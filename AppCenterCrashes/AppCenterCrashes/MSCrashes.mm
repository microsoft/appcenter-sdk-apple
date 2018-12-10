#import "MSAppCenterInternal.h"
#import "MSAppleErrorLog.h"
#import "MSChannelUnitConfiguration.h"
#import "MSChannelUnitProtocol.h"
#import "MSCrashHandlerSetupDelegate.h"
#import "MSCrashesCXXExceptionWrapperException.h"
#import "MSCrashesDelegate.h"
#import "MSCrashesInternal.h"
#import "MSCrashesPrivate.h"
#import "MSCrashesUtil.h"
#import "MSDeviceTracker.h"
#import "MSEncrypter.h"
#import "MSErrorAttachmentLog.h"
#import "MSErrorAttachmentLogInternal.h"
#import "MSErrorLogFormatter.h"
#import "MSHandledErrorLog.h"
#import "MSServiceAbstractProtected.h"
#import "MSSessionContext.h"
#import "MSUserIdContext.h"
#import "MSUtility+File.h"
#import "MSWrapperCrashesHelper.h"
#import "MSWrapperExceptionManagerInternal.h"

/**
 * Service name for initialization.
 */
static NSString *const kMSServiceName = @"Crashes";

/**
 * The group Id for storage.
 */
static NSString *const kMSGroupId = @"Crashes";

/**
 * The group Id for log buffer.
 */
static NSString *const kMSBufferGroupId = @"CrashesBuffer";

/**
 * Name for the AnalyzerInProgress file. Some background info here: writing the file to signal that we are processing crashes proved to be
 * faster and more reliable as e.g. storing a flag in the NSUserDefaults.
 */
static NSString *const kMSAnalyzerFilename = @"MSCrashes.analyzer";

/**
 * File extension for buffer files. Files will have a GUID as the file name and a .mscrasheslogbuffer as file extension.
 */
static NSString *const kMSLogBufferFileExtension = @"mscrasheslogbuffer";

static NSString *const kMSTargetTokenFileExtension = @"targettoken";

static unsigned int kMaxAttachmentsPerCrashReport = 2;

std::array<MSCrashesBufferedLog, ms_crashes_log_buffer_size> msCrashesLogBuffer;

/**
 * Singleton.
 */
static MSCrashes *sharedInstance = nil;
static dispatch_once_t onceToken;

#pragma mark - Callbacks Setup

static MSCrashesCallbacks msCrashesCallbacks = {.context = nullptr, .handleSignal = nullptr};
static NSString *const kMSUserConfirmationKey = @"MSUserConfirmation";
static volatile BOOL writeBufferTaskStarted = NO;

static void ms_save_log_buffer(const std::string &data, const std::string &path) {
  int fd = open(path.c_str(), O_WRONLY | O_CREAT | O_TRUNC, 0644);
  if (fd < 0) {
    return;
  }
  write(fd, data.data(), data.size());
  close(fd);
}

void ms_save_log_buffer() {

  // Iterate over the buffered logs and write them to disk.
  writeBufferTaskStarted = YES;
  for (int i = 0; i < ms_crashes_log_buffer_size; i++) {

    // Make sure not to allocate any memory (e.g. copy).
    ms_save_log_buffer(msCrashesLogBuffer[i].buffer, msCrashesLogBuffer[i].bufferPath);
    if (!msCrashesLogBuffer[i].targetToken.empty()) {
      ms_save_log_buffer(msCrashesLogBuffer[i].targetToken, msCrashesLogBuffer[i].targetTokenPath);
    }
  }
}

/**
 * Proxy implementation for PLCrashReporter to keep our interface stable while this can change.
 */
static void plcr_post_crash_callback(__unused siginfo_t *info, __unused ucontext_t *uap, void *context) {
  ms_save_log_buffer();
  if (msCrashesCallbacks.handleSignal != nullptr) {
    msCrashesCallbacks.handleSignal(context);
  }
}

static PLCrashReporterCallbacks plCrashCallbacks = {.version = 0, .context = nullptr, .handleSignal = plcr_post_crash_callback};

/**
 * C++ Exception Handler
 */
__attribute__((noreturn)) static void uncaught_cxx_exception_handler(const MSCrashesUncaughtCXXExceptionInfo *info) {

  /*
   * This relies on a LOT of sneaky internal knowledge of how PLCR works and should not be considered a long-term solution.
   */
  NSGetUncaughtExceptionHandler()([[MSCrashesCXXExceptionWrapperException alloc] initWithCXXExceptionInfo:info]);
  abort();
}

@interface MSCrashes ()

/**
 * Indicates if the app crashed in the previous session.
 * Use this on startup, to check if the app starts the first time after it crashed previously. You can use this also to disable specific
 * events, like asking the user to rate your app.
 *
 * @warning This property only has a correct value, once the sdk has been properly initialized!
 *
 * @see lastSessionCrashReport
 */
@property BOOL didCrashInLastSession;

/**
 * Indicates if the delayedProcessingSemaphore will need to be released anymore. Useful for preventing overflows.
 */
@property BOOL shouldReleaseProcessingSemaphore;

/**
 * Detail information about the last crash.
 */
@property(getter=getLastSessionCrashReport) MSErrorReport *lastSessionCrashReport;

/**
 * Queue with high priority that will be used to create the log buffer files. The default main queue is too slow.
 */
@property(nonatomic) dispatch_queue_t bufferFileQueue;

/**
 * A group to wait for creation of buffers in the test.
 */
@property(nonatomic) dispatch_group_t bufferFileGroup;

/**
 * Semaphore for exclusion with "startDelayedCrashProcessing" method.
 */
@property dispatch_semaphore_t delayedProcessingSemaphore;

/**
 * Channel unit for log buffer.
 */
@property(nonatomic) id<MSChannelUnitProtocol> bufferChannelUnit;

/*
 * Encrypter for target tokens.
 */
@property(nonatomic, readonly) MSEncrypter *targetTokenEncrypter;

@end

@implementation MSCrashes

@synthesize delegate = _delegate;
@synthesize channelGroup = _channelGroup;
@synthesize channelUnitConfiguration = _channelUnitConfiguration;

#pragma mark - Public Methods

+ (void)generateTestCrash {
  @synchronized([MSCrashes sharedInstance]) {
    if ([[MSCrashes sharedInstance] canBeUsed]) {
      if ([MSUtility currentAppEnvironment] != MSEnvironmentAppStore) {
        if ([MSAppCenter isDebuggerAttached]) {
          MSLogWarning([MSCrashes logTag], @"The debugger is attached. The following crash cannot be detected by the SDK!");
        }

        // Crashing the app here!
        __builtin_trap();
      }
    } else {
      MSLogWarning([MSCrashes logTag], @"GenerateTestCrash was just called in an App Store environment. The call will be ignored");
    }
  }
}

+ (BOOL)hasCrashedInLastSession {
  return [[MSCrashes sharedInstance] didCrashInLastSession];
}

+ (void)setUserConfirmationHandler:(_Nullable MSUserConfirmationHandler)userConfirmationHandler {

  // FIXME: Type cast is required at the moment. Need to fix the root cause.
  MSCrashes *crashes = static_cast<MSCrashes *>([self sharedInstance]);
  crashes.userConfirmationHandler = userConfirmationHandler;
}

+ (void)notifyWithUserConfirmation:(MSUserConfirmation)userConfirmation {
  [[MSCrashes sharedInstance] notifyWithUserConfirmation:userConfirmation];
}

+ (MSErrorReport *_Nullable)lastSessionCrashReport {
  return [[MSCrashes sharedInstance] getLastSessionCrashReport];
}

/**
 * This can never be bound to Xamarin.
 * This method is not part of the publicly available APIs on tvOS as Mach exception handling is not possible on tvOS.
 * The property is NO by default there.
 */
+ (void)disableMachExceptionHandler {
  [[MSCrashes sharedInstance] setEnableMachExceptionHandler:NO];
}

+ (void)setDelegate:(_Nullable id<MSCrashesDelegate>)delegate {
  [[MSCrashes sharedInstance] setDelegate:delegate];
}

/**
 * Track handled exception directly as model form.
 * This API is not public and is used by wrapper SDKs.
 */
+ (void)trackModelException:(MSException *)exception {
  [self trackModelException:exception withProperties:nil];
}

/**
 * Track handled exception directly as model form with user-defined custom properties.
 * This API is not public and is used by wrapper SDKs.
 */
+ (void)trackModelException:(MSException *)exception withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties {
  @synchronized(self) {
    if ([[MSCrashes sharedInstance] canBeUsed]) {
      [[MSCrashes sharedInstance] trackModelException:exception withProperties:properties];
    }
  }
}

#pragma mark - Service initialization

- (instancetype)init {
  if ((self = [super init])) {
    _crashFiles = [NSMutableArray new];
    _crashesPathComponent = [MSCrashesUtil crashesDir];
    _logBufferPathComponent = [MSCrashesUtil logBufferDir];
    _analyzerInProgressFilePathComponent = [NSString stringWithFormat:@"%@/%@", [MSCrashesUtil crashesDir], kMSAnalyzerFilename];

    _didCrashInLastSession = NO;
    _delayedProcessingSemaphore = dispatch_semaphore_create(0);
    _automaticProcessing = YES;
    _shouldReleaseProcessingSemaphore = YES;
#if !TARGET_OS_TV
    _enableMachExceptionHandler = YES;
#endif
    _channelUnitConfiguration = [[MSChannelUnitConfiguration alloc] initWithGroupId:[self groupId]
                                                                           priority:MSPriorityHigh
                                                                      flushInterval:1.0
                                                                     batchSizeLimit:1
                                                                pendingBatchesLimit:3];
    _targetTokenEncrypter = [MSEncrypter new];

    /*
     * Using our own queue with high priority as the default main queue is slower and we want the files to be created as quickly as possible
     * in case the app is crashing fast.
     */
    _bufferFileQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    _bufferFileGroup = dispatch_group_create();
    [self setupLogBuffer];
  }
  return self;
}

#pragma mark - MSServiceAbstract

- (void)applyEnabledState:(BOOL)isEnabled {
  [super applyEnabledState:isEnabled];

  // Enabling.
  if (isEnabled) {
    id<MSCrashHandlerSetupDelegate> crashSetupDelegate = [MSWrapperCrashesHelper getCrashHandlerSetupDelegate];

    // Check if a wrapper SDK has a preference for uncaught exception handling.
    BOOL enableUncaughtExceptionHandler = YES;
    if ([crashSetupDelegate respondsToSelector:@selector(shouldEnableUncaughtExceptionHandler)]) {
      enableUncaughtExceptionHandler = [crashSetupDelegate shouldEnableUncaughtExceptionHandler];
    }

    // Allow a wrapper SDK to perform custom behavior before setting up crash handlers.
    if ([crashSetupDelegate respondsToSelector:@selector(willSetUpCrashHandlers)]) {
      [crashSetupDelegate willSetUpCrashHandlers];
    }

    // Set up crash handlers.
    [self configureCrashReporterWithUncaughtExceptionHandlerEnabled:enableUncaughtExceptionHandler];

    // Allow a wrapper SDK to perform custom behavior after setting up crash handlers.
    if ([crashSetupDelegate respondsToSelector:@selector(didSetUpCrashHandlers)]) {
      [crashSetupDelegate didSetUpCrashHandlers];
    }

    /*
     * PLCrashReporter keeps collecting crash reports even when the SDK is disabled, delete them only if current state is disabled.
     */
    if (!self.isEnabled) {
      [self.plCrashReporter purgePendingCrashReport];
    }

    // Get pending crashes from PLCrashReporter and persist them in the intermediate format.
    if ([self.plCrashReporter hasPendingCrashReport]) {
      self.didCrashInLastSession = YES;
      [self handleLatestCrashReport];
    }

    // Get persisted crash reports.
    self.crashFiles = [self persistedCrashReports];

    /*
     * Process PLCrashReports, this will format the PLCrashReport into our schema and then trigger sending. This mostly happens on the start
     * of the service.
     */
    if (self.crashFiles.count > 0) {
      [self startDelayedCrashProcessing];
    } else {
      dispatch_semaphore_signal(self.delayedProcessingSemaphore);
      [self clearContextHistoryAndKeepCurrentSession];
    }

    // More details on log if a debugger is attached.
    if ([MSAppCenter isDebuggerAttached]) {
      MSLogInfo([MSCrashes logTag], @"Crashes service has been enabled but the service cannot detect crashes due to running the "
                                    @"application with a debugger attached.");
    } else {
      MSLogInfo([MSCrashes logTag], @"Crashes service has been enabled.");
    }
  } else {

    // Don't set PLCrashReporter to nil!
    MSLogDebug([MSCrashes logTag], @"Cleaning up all crash files.");
    [MSWrapperExceptionManager deleteAllWrapperExceptions];
    [self deleteAllFromCrashesDirectory];
    [self emptyLogBufferFiles];
    [self removeAnalyzerFile];
    [self.plCrashReporter purgePendingCrashReport];
    [self clearUnprocessedReports];
    [self clearContextHistoryAndKeepCurrentSession];
    MSLogInfo([MSCrashes logTag], @"Crashes service has been disabled.");
  }
}

#pragma mark - MSServiceInternal

+ (instancetype)sharedInstance {
  dispatch_once(&onceToken, ^{
    if (sharedInstance == nil) {
      sharedInstance = [MSCrashes new];
    }
  });
  return sharedInstance;
}

+ (NSString *)serviceName {
  return kMSServiceName;
}

- (void)startWithChannelGroup:(id<MSChannelGroupProtocol>)channelGroup
                    appSecret:(nullable NSString *)appSecret
      transmissionTargetToken:(nullable NSString *)token
              fromApplication:(BOOL)fromApplication {
  [super startWithChannelGroup:channelGroup appSecret:appSecret transmissionTargetToken:token fromApplication:fromApplication];
  [self.channelGroup addDelegate:self];
  [self processLogBufferAfterCrash];
  MSLogVerbose([MSCrashes logTag], @"Started crash service.");
}

- (void)updateConfigurationWithAppSecret:(NSString *)appSecret transmissionTargetToken:(NSString *)token {
  [self processLogBufferAfterCrash];

  /*
   * updateConfigurationWithAppSecret:transmissionTargetToken: will apply enabled state at the end so all update for the service should be
   * done prior to call super method.
   */
  [super updateConfigurationWithAppSecret:appSecret transmissionTargetToken:token];
}

+ (NSString *)logTag {
  return @"AppCenterCrashes";
}

- (NSString *)groupId {
  return kMSGroupId;
}

- (MSInitializationPriority)initializationPriority {
  return MSInitializationPriorityMax;
}

- (void)setEnableMachExceptionHandler:(BOOL)enableMachExceptionHandler {
  _enableMachExceptionHandler = enableMachExceptionHandler;
}

- (void)clearContextHistoryAndKeepCurrentSession {
  [[MSDeviceTracker sharedInstance] clearDevices];
  [[MSSessionContext sharedInstance] clearSessionHistoryAndKeepCurrentSession:YES];
  [[MSUserIdContext sharedInstance] clearUserIdHistory];
}

#pragma mark - Channel Delegate

/**
 * Why are we doing the event-buffering inside crashes?
 * The reason is, only Crashes has the chance to execute code at crash time and only with the following constraints:
 * 1. Don't execute any Objective-C code when crashing.
 * 2. Don't allocate new memory when crashing.
 * 3. Only use async-safe C/C++ methods.
 * This means the Crashes module can't message any other module. All logic related to the buffer needs to happen before the crash and then,
 * at crash time, crashes has all info in place to save the buffer safely from the main thread (other threads are killed at crash time).
 */
- (void)channel:(id<MSChannelProtocol>)__unused channel
    didPrepareLog:(id<MSLog>)log
       internalId:(NSString *)internalId
            flags:(MSFlags)__unused flags {

  // Don't buffer event if log is empty, crashes module is disabled or the log is related to crash.
  NSObject *logObject = static_cast<NSObject *>(log);
  if (!log || ![self isEnabled] || [logObject isKindOfClass:[MSAppleErrorLog class]] ||
      [logObject isKindOfClass:[MSErrorAttachmentLog class]]) {
    return;
  }

  // The callback can be called from any thread, making sure we make this thread-safe.
  @synchronized(self) {
    NSData *serializedLog = [NSKeyedArchiver archivedDataWithRootObject:log];
    if (serializedLog && (serializedLog.length > 0)) {

      // Serialize target token.
      NSString *targetToken = log.transmissionTargetTokens != nil ? log.transmissionTargetTokens.anyObject : nil;
      targetToken = targetToken != nil ? [self.targetTokenEncrypter encryptString:targetToken] : @"";

      // Storing a log.
      NSTimeInterval oldestTimestamp = DBL_MAX;
      long indexToDelete = 0;
      MSLogVerbose([MSCrashes logTag], @"Storing a log to Crashes Buffer: (sid: %@, type: %@)", log.sid, log.type);
      for (auto it = msCrashesLogBuffer.begin(), end = msCrashesLogBuffer.end(); it != end; ++it) {

        // We've found an empty element, buffer our log.
        if (it->buffer.empty()) {
          it->buffer = std::string(&reinterpret_cast<const char *>(serializedLog.bytes)[0],
                                   &reinterpret_cast<const char *>(serializedLog.bytes)[serializedLog.length]);
          it->targetToken = targetToken.UTF8String;
          it->internalId = internalId.UTF8String;
          it->timestamp = [[NSDate date] timeIntervalSince1970];

          MSLogVerbose([MSCrashes logTag], @"Found an empty buffer position.");

          // We're done, no need to iterate any more and leave the method.
          return;
        } else {

          // The current element is full. Save the timestamp if applicable and continue iterating unless we have reached the last element.

          // Remember the timestamp if the log is older than the previous one or the initial one.
          if (oldestTimestamp > it->timestamp) {
            oldestTimestamp = it->timestamp;
            indexToDelete = it - msCrashesLogBuffer.begin();
            MSLogVerbose([MSCrashes logTag], @"Remembering index %ld for oldest timestamp %f.", indexToDelete, oldestTimestamp);
          }
        }

        /*
         * Continue to iterate until we reach en empty element, in which case we store the log in it and stop, or until we reach the end of
         * the buffer. In the later case, we will replace the oldest log with the current one.
         */
      }

      // We've reached the last element in our buffer and we now go ahead and replace the oldest element.
      MSLogVerbose([MSCrashes logTag], @"Reached end of buffer. Next step is overwriting the oldest one.");

      // Overwrite the oldest buffered log.
      msCrashesLogBuffer[indexToDelete].buffer = std::string(&reinterpret_cast<const char *>(serializedLog.bytes)[0],
                                                             &reinterpret_cast<const char *>(serializedLog.bytes)[serializedLog.length]);
      msCrashesLogBuffer[indexToDelete].internalId = internalId.UTF8String;
      msCrashesLogBuffer[indexToDelete].timestamp = [[NSDate date] timeIntervalSince1970];
      MSLogVerbose([MSCrashes logTag], @"Overwrote buffered log at index %ld.", indexToDelete);

      // We're done, no need to iterate any more. But no need to `return;` as we're at the end of the buffer.
    }
  }
}

- (void)channel:(id<MSChannelProtocol>)__unused channel didCompleteEnqueueingLog:(id<MSLog>)log internalId:(NSString *)internalId {
  @synchronized(self) {
    for (auto it = msCrashesLogBuffer.begin(), end = msCrashesLogBuffer.end(); it != end; ++it) {
      NSString *bufferId = [NSString stringWithCString:it->internalId.c_str() encoding:NSUTF8StringEncoding];
      if (bufferId && bufferId.length > 0 && [bufferId isEqualToString:internalId]) {
        MSLogVerbose([MSCrashes logTag], @"Deleting a log from buffer with id %@", internalId);
        it->buffer = "";
        it->targetToken = "";
        it->timestamp = 0;
        it->internalId = "";
        if (writeBufferTaskStarted) {

          /*
           * Crashes already started writing buffer to files.
           * To prevent sending duplicate logs after relaunch, it will delete the buffer file.
           */
          unlink(it->bufferPath.c_str());
          MSLogVerbose([MSCrashes logTag], @"Deleted a log from Crashes Buffer (sid: %@, type: %@)", log.sid, log.type);
          MSLogVerbose([MSCrashes logTag], @"Deleted crash buffer file: %@.",
                       [NSString stringWithCString:it->bufferPath.c_str() encoding:[NSString defaultCStringEncoding]]);
        }
      }
    }
  }
}

#pragma mark - Channel Delegate

- (void)channel:(id<MSChannelProtocol>)__unused channel willSendLog:(id<MSLog>)log {
  id<MSCrashesDelegate> strongDelegate = self.delegate;
  if (strongDelegate && [strongDelegate respondsToSelector:@selector(crashes:willSendErrorReport:)]) {
    NSObject *logObject = static_cast<NSObject *>(log);
    if ([logObject isKindOfClass:[MSAppleErrorLog class]]) {
      MSAppleErrorLog *appleErrorLog = static_cast<MSAppleErrorLog *>(log);
      MSErrorReport *report = [MSErrorLogFormatter errorReportFromLog:appleErrorLog];
      [strongDelegate crashes:self willSendErrorReport:report];
    }
  }
}

- (void)channel:(id<MSChannelProtocol>)__unused channel didSucceedSendingLog:(id<MSLog>)log {
  id<MSCrashesDelegate> strongDelegate = self.delegate;
  if (strongDelegate && [strongDelegate respondsToSelector:@selector(crashes:didSucceedSendingErrorReport:)]) {
    NSObject *logObject = static_cast<NSObject *>(log);
    if ([logObject isKindOfClass:[MSAppleErrorLog class]]) {
      MSAppleErrorLog *appleErrorLog = static_cast<MSAppleErrorLog *>(log);
      MSErrorReport *report = [MSErrorLogFormatter errorReportFromLog:appleErrorLog];
      [strongDelegate crashes:self didSucceedSendingErrorReport:report];
    }
  }
}

- (void)channel:(id<MSChannelProtocol>)__unused channel didFailSendingLog:(id<MSLog>)log withError:(NSError *)error {
  id<MSCrashesDelegate> strongDelegate = self.delegate;
  if (strongDelegate && [strongDelegate respondsToSelector:@selector(crashes:didFailSendingErrorReport:withError:)]) {
    NSObject *logObject = static_cast<NSObject *>(log);
    if ([logObject isKindOfClass:[MSAppleErrorLog class]]) {
      MSAppleErrorLog *appleErrorLog = static_cast<MSAppleErrorLog *>(log);
      MSErrorReport *report = [MSErrorLogFormatter errorReportFromLog:appleErrorLog];
      [strongDelegate crashes:self didFailSendingErrorReport:report withError:error];
    }
  }
}

#pragma mark - Crash reporter configuration

- (void)configureCrashReporterWithUncaughtExceptionHandlerEnabled:(BOOL)enableUncaughtExceptionHandler {
  if (self.plCrashReporter) {
    MSLogDebug([MSCrashes logTag], @"Already configured PLCrashReporter.");
    return;
  }

  if (enableUncaughtExceptionHandler) {
    MSLogDebug([MSCrashes logTag], @"EnableUncaughtExceptionHandler is set to YES");
  } else {
    MSLogDebug([MSCrashes logTag], @"EnableUncaughtExceptionHandler is set to NO, we're running in a Xamarin runtime.");
  }

  PLCrashReporterSignalHandlerType signalHandlerType = PLCrashReporterSignalHandlerTypeBSD;

#if !TARGET_OS_TV
  if (self.isMachExceptionHandlerEnabled) {
    signalHandlerType = PLCrashReporterSignalHandlerTypeMach;
    MSLogVerbose([MSCrashes logTag], @"Enabled Mach exception handler.");
  }
#endif
  PLCrashReporterSymbolicationStrategy symbolicationStrategy = PLCrashReporterSymbolicationStrategyNone;
  MSPLCrashReporterConfig *config = [[MSPLCrashReporterConfig alloc] initWithSignalHandlerType:signalHandlerType
                                                                         symbolicationStrategy:symbolicationStrategy
                                                        shouldRegisterUncaughtExceptionHandler:enableUncaughtExceptionHandler];
  self.plCrashReporter = [[MSPLCrashReporter alloc] initWithConfiguration:config];

  /*
   * The actual signal and mach handlers are only registered when invoking `enableCrashReporterAndReturnError`, so it is safe enough to only
   * disable the following part when a debugger is attached no matter which signal handler type is set.
   */
  if ([MSAppCenter isDebuggerAttached]) {
    MSLogWarning([MSCrashes logTag], @"Detecting crashes is NOT enabled due to running the app with a debugger attached.");
  } else {

    /*
     * Multiple exception handlers can be set, but we can only query the top level error handler (uncaught exception handler). To check if
     * PLCrashReporter's error handler is successfully added, we compare the top level one that is set before and the one after
     * PLCrashReporter sets up its own. With delayed processing we can then check if another error handler was set up afterwards and can
     * show a debug warning log message, that the dev has to make sure the "newer" error handler doesn't exit the process itself, because
     * then all subsequent handlers would never be invoked. Note: ANY error handler setup BEFORE SDK initialization will not be processed!
     */
    NSUncaughtExceptionHandler *initialHandler = NSGetUncaughtExceptionHandler();
    NSError *error = nil;
    [self.plCrashReporter setCrashCallbacks:&plCrashCallbacks];
    if (![self.plCrashReporter enableCrashReporterAndReturnError:&error])
      MSLogError([MSCrashes logTag], @"Could not enable crash reporter: %@", [error localizedDescription]);
    NSUncaughtExceptionHandler *currentHandler = NSGetUncaughtExceptionHandler();
    if (currentHandler && currentHandler != initialHandler) {
      self.exceptionHandler = currentHandler;
      MSLogDebug([MSCrashes logTag], @"Exception handler successfully initialized.");
    } else if (currentHandler && !enableUncaughtExceptionHandler) {
      self.exceptionHandler = currentHandler;
      MSLogDebug([MSCrashes logTag], @"Exception handler successfully initialized but it has not been registered due to the wrapper SDK.");
    } else {
      MSLogError([MSCrashes logTag], @"Exception handler could not be set. Make sure there is no other exception handler set up!");
    }

    // Add a handler for C++-Exceptions.
    [MSCrashesUncaughtCXXExceptionHandlerManager addCXXExceptionHandler:uncaught_cxx_exception_handler];
  }
}

#pragma mark - Crash processing

- (void)startDelayedCrashProcessing {

  /*
   * FIXME: If application is crashed and relaunched from multitasking view, the SDK starts faster than normal launch and application state
   * is not updated from inactive to active at this time. Give more delay here for a workaround but we need to fix it eventually. This can
   * also happen if the application is launched from Xcode and stopped by clicking the stop button on Xcode.
   * In addition to that, we also need it to be delayed because
   * 1. it sometimes needs to "warm up" internet connection on iOS 8,
   * 2. giving some time to start and let all Crashes initialization happen before processing crashes.
   */

  // This must be performed asynchronously to prevent a deadlock with 'unprocessedCrashReports'.
  dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, (1 * NSEC_PER_SEC));
  dispatch_after(delay, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [self startCrashProcessing];

    // Only release once to avoid releasing an unbounded number of times.
    @synchronized(self) {
      if (self.shouldReleaseProcessingSemaphore) {
        dispatch_semaphore_signal(self.delayedProcessingSemaphore);
        self.shouldReleaseProcessingSemaphore = NO;
      }
    }
  });
}

- (void)startCrashProcessing {

  /*
   * FIXME: There is no life cycle for app extensions yet so force start crash processing until then. Also force start crash processing when
   * automatic processing is disabled. Though it sounds counterintuitive, this is important because there are scenarios in some wrappers
   * (i.e. RN) where the application state is not ready by the time crash processing needs to happen.
   */
  if (self.automaticProcessing && ([MSUtility applicationState] == MSApplicationStateBackground)) {
    MSLogWarning([MSCrashes logTag], @"Crashes will not be processed because the application is in the background.");
    return;
  }
  MSLogDebug([MSCrashes logTag], @"Start delayed CrashManager processing");

  // Was our own exception handler successfully added?
  if (self.exceptionHandler) {

    // Get the current top level error handler.
    NSUncaughtExceptionHandler *currentHandler = NSGetUncaughtExceptionHandler();

    /*
     * If the top level error handler differs from our own, at least another one was added. This could cause exception crashes not to be
     * reported to App Center. Print out log message for details.
     */
    if (self.exceptionHandler != currentHandler) {
      MSLogWarning([MSCrashes logTag], @"Another exception handler was added. If "
                                       @"this invokes any kind of exit() after processing the "
                                       @"exception, which causes any subsequent error handler "
                                       @"not to be invoked, these crashes will NOT be reported "
                                       @"to App Center!");
    }
  }
  [self processCrashReports];
}

- (void)processCrashReports {

  // Handle 'disabled' state all at once to simplify the logic that follows.
  if (!self.isEnabled) {
    MSLogDebug([MSCrashes logTag], @"Crashes service is disabled; discard all crash reports");
    [self deleteAllFromCrashesDirectory];
    [MSWrapperExceptionManager deleteAllWrapperExceptions];
    return;
  }
  NSError *error = nil;
  self.unprocessedReports = [NSMutableArray new];
  self.unprocessedLogs = [NSMutableArray new];
  self.unprocessedFilePaths = [NSMutableArray new];

  // First save all found crash reports for use in correlation step.
  NSMutableDictionary *foundCrashReports = [NSMutableDictionary new];
  NSMutableDictionary *foundErrorReports = [NSMutableDictionary new];
  for (NSURL *fileURL in self.crashFiles) {
    NSData *crashFileData = [NSData dataWithContentsOfURL:fileURL];
    if ([crashFileData length] > 0) {
      MSPLCrashReport *report = [[MSPLCrashReport alloc] initWithData:crashFileData error:&error];
      if (report) {
        foundCrashReports[fileURL] = report;
        foundErrorReports[fileURL] = [MSErrorLogFormatter errorReportFromCrashReport:report];
      } else {
        MSLogWarning([MSCrashes logTag], @"Crash report found but couldn't parse it, discard the crash report: %@",
                     error.localizedDescription);
      }
    }
  }

  // Correlation step.
  [MSWrapperExceptionManager correlateLastSavedWrapperExceptionToReport:[foundErrorReports allValues]];

  // Processing step.
  for (NSURL *fileURL in [foundCrashReports allKeys]) {
    MSLogVerbose([MSCrashes logTag], @"Crash reports found");
    MSPLCrashReport *report = foundCrashReports[fileURL];
    MSErrorReport *errorReport = foundErrorReports[fileURL];
    MSAppleErrorLog *log = [MSErrorLogFormatter errorLogFromCrashReport:report];
    if (!self.automaticProcessing || [self shouldProcessErrorReport:errorReport]) {
      if (!self.automaticProcessing) {
        MSLogDebug([MSCrashes logTag], @"Automatic crash processing is disabled, storing the crash report for later processing: %@",
                   report.debugDescription);
      } else {
        MSLogDebug([MSCrashes logTag], @"shouldProcessErrorReport is not implemented or returned YES, processing the crash report: %@",
                   report.debugDescription);
      }

      // Put the log to temporary space for next callbacks.
      [self.unprocessedLogs addObject:log];
      [self.unprocessedReports addObject:errorReport];
      [self.unprocessedFilePaths addObject:fileURL];
    } else {
      MSLogDebug([MSCrashes logTag], @"shouldProcessErrorReport returned NO, discard the crash report: %@", report.debugDescription);

      // Discard the crash report.
      [MSWrapperExceptionManager deleteWrapperExceptionWithUUIDString:errorReport.incidentIdentifier];
      [self deleteCrashReportWithFileURL:fileURL];
      [self.crashFiles removeObject:fileURL];
    }
  }

  // Send reports or await user confirmation if automatic processing is enabled.
  if (self.automaticProcessing) {
    [self sendCrashReportsOrAwaitUserConfirmation];
  }
}

- (void)processLogBufferAfterCrash {

  // Initialize a dedicated channel for log buffer.
  self.bufferChannelUnit =
      [self.channelGroup addChannelUnitWithConfiguration:[[MSChannelUnitConfiguration alloc] initWithGroupId:kMSBufferGroupId
                                                                                                    priority:MSPriorityHigh
                                                                                               flushInterval:1.0
                                                                                              batchSizeLimit:50
                                                                                         pendingBatchesLimit:1]];

  // Iterate over each file in it with the kMSLogBufferFileExtension and send the log if a log can be deserialized.
  NSArray<NSURL *> *files = [MSUtility contentsOfDirectory:[NSString stringWithFormat:@"%@", self.logBufferPathComponent]
                                         propertiesForKeys:nil];
  for (NSURL *fileURL in files) {
    if ([[fileURL pathExtension] isEqualToString:kMSLogBufferFileExtension]) {
      NSData *serializedLog = [NSData dataWithContentsOfURL:fileURL];
      if (serializedLog && serializedLog.length && serializedLog.length > 0) {
        id<MSLog> item = [NSKeyedUnarchiver unarchiveObjectWithData:serializedLog];
        if (item) {

          // Try to set target token.
          NSString *targetTokenFilePath = [fileURL.path stringByReplacingOccurrencesOfString:kMSLogBufferFileExtension
                                                                                  withString:kMSTargetTokenFileExtension];
          NSURL *targetTokenFileURL = [NSURL fileURLWithPath:targetTokenFilePath];
          NSString *targetToken = [NSString stringWithContentsOfURL:targetTokenFileURL encoding:NSUTF8StringEncoding error:nil];
          if (targetToken != nil) {
            targetToken = [self.targetTokenEncrypter decryptString:targetToken];
            [item addTransmissionTargetToken:targetToken];

            // Delete target token file.
            [MSUtility deleteFileAtURL:targetTokenFileURL];
          }

          // Buffered logs are used sending their own channel. It will never contain more than 50 logs.
          MSLogDebug([MSCrashes logTag], @"Re-enqueueing buffered log, type: %@.", item.type);
          // TODO Must read log priority and serialize to be able to enqueue with proper criticality
          [self.bufferChannelUnit enqueueItem:item flags:MSFlagsDefault];
        }
      }

      // Create empty new file, overwrites the old one.
      [[NSData data] writeToURL:fileURL atomically:NO];
    }
  }
}

/**
 * Gets a list of unprocessed crashes as MSErrorReports.
 */
- (NSArray<MSErrorReport *> *)unprocessedCrashReports {
  dispatch_semaphore_wait(self.delayedProcessingSemaphore, DISPATCH_TIME_FOREVER);
  dispatch_semaphore_signal(self.delayedProcessingSemaphore);
  return self.unprocessedReports;
}

/**
 * Resumes processing for a given subset of the unprocessed reports. Returns YES if should "AlwaysSend".
 */
- (BOOL)sendCrashReportsOrAwaitUserConfirmationForFilteredIds:(NSArray<NSString *> *)filteredIds {
  NSMutableArray *filteredOutLogs = [NSMutableArray new];
  NSMutableArray *filteredOutReports = [NSMutableArray new];
  NSMutableArray *filteredOutFilePaths = [NSMutableArray new];
  for (NSUInteger i = 0; i < [self.unprocessedReports count]; i++) {
    MSErrorReport *report = self.unprocessedReports[i];
    MSErrorReport *foundReport = nil;
    for (NSString *filteredReportId in filteredIds) {
      if ([report.incidentIdentifier isEqualToString:filteredReportId]) {
        foundReport = report;
        break;
      }
    }

    // Use the report from the list in case it was modified at all.
    if (foundReport) {
      self.unprocessedReports[i] = foundReport;
    } else {
      MSAppleErrorLog *log = self.unprocessedLogs[i];
      NSURL *filePath = self.unprocessedFilePaths[i];
      [filteredOutReports addObject:report];
      [filteredOutLogs addObject:log];
      [filteredOutFilePaths addObject:filePath];

      // Remove the items from disk.
      [MSWrapperExceptionManager deleteWrapperExceptionWithUUIDString:report.incidentIdentifier];
      [self deleteCrashReportWithFileURL:filePath];
      [self.crashFiles removeObject:filePath];
    }
  }

  // Remove filtered out items from memory.
  [self.unprocessedLogs removeObjectsInArray:filteredOutLogs];
  [self.unprocessedFilePaths removeObjectsInArray:filteredOutFilePaths];
  [self.unprocessedReports removeObjectsInArray:filteredOutReports];

  // Send or await user confirmation.
  return [self sendCrashReportsOrAwaitUserConfirmation];
}

/**
 * Sends error attachments for a particular error report.
 */
- (void)sendErrorAttachments:(NSArray<MSErrorAttachmentLog *> *)errorAttachments withIncidentIdentifier:(NSString *)incidentIdentifier {

  // Send attachments log to log manager.
  unsigned int totalProcessedAttachments = 0;
  for (MSErrorAttachmentLog *attachment in errorAttachments) {
    attachment.errorId = incidentIdentifier;
    if (![MSCrashes validatePropertiesForAttachment:attachment]) {
      MSLogError([MSCrashes logTag], @"Not all required fields are present in MSErrorAttachmentLog.");
      continue;
    }
    [self.channelUnit enqueueItem:attachment flags:MSFlagsDefault];
    ++totalProcessedAttachments;
  }
  if (totalProcessedAttachments > kMaxAttachmentsPerCrashReport) {
    MSLogWarning([MSCrashes logTag], @"A limit of %u attachments per error report might be enforced by server.",
                 kMaxAttachmentsPerCrashReport);
  }
}

#pragma mark - Helper

- (void)deleteAllFromCrashesDirectory {
  [MSUtility deleteItemForPathComponent:self.crashesPathComponent];
  [self.crashFiles removeAllObjects];
}

- (void)deleteCrashReportWithFileURL:(NSURL *)fileURL {
  [MSUtility deleteFileAtURL:fileURL];
}

- (void)handleLatestCrashReport {
  NSError *error = nil;

  // Check if the next call ran successfully the last time.
  if (![MSUtility fileExistsForPathComponent:self.analyzerInProgressFilePathComponent]) {

    // Mark the start of the routine.
    [self createAnalyzerFile];

    // Try loading the crash report.
    NSData *crashData = [[NSData alloc] initWithData:[self.plCrashReporter loadPendingCrashReportDataAndReturnError:&error]];
    if (crashData == nil) {
      MSLogError([MSCrashes logTag], @"Couldn't load crash report: %@", error.localizedDescription);
    } else {

      // Get data of PLCrashReport and write it to SDK directory.
      MSPLCrashReport *report = [[MSPLCrashReport alloc] initWithData:crashData error:&error];
      if (report) {
        NSString *cacheFilename = [NSString stringWithFormat:@"%.0f", [NSDate timeIntervalSinceReferenceDate]];
        NSString *crashPath = [NSString stringWithFormat:@"%@/%@", self.crashesPathComponent, cacheFilename];
        [MSUtility createFileAtPathComponent:crashPath withData:crashData atomically:YES forceOverwrite:NO];
        self.lastSessionCrashReport = [MSErrorLogFormatter errorReportFromCrashReport:report];
        [MSWrapperExceptionManager correlateLastSavedWrapperExceptionToReport:@[ self.lastSessionCrashReport ]];
      } else {
        MSLogWarning([MSCrashes logTag], @"Couldn't parse crash report: %@", error.localizedDescription);
      }
    }
  } else {
    MSLogError([MSCrashes logTag], @"Error on loading the crash report, it will be purged.");
  }

  // Purge the report marker at the end of the routine.
  [self removeAnalyzerFile];
  [self.plCrashReporter purgePendingCrashReport];
}

- (NSMutableArray *)persistedCrashReports {
  NSMutableArray *persistedCrashReports = [NSMutableArray new];
  NSArray *files = [MSUtility contentsOfDirectory:self.crashesPathComponent
                                propertiesForKeys:@[ NSURLNameKey, NSURLFileSizeKey, NSURLIsRegularFileKey ]];
  if (!files) {
    MSLogError([MSCrashes logTag], @"No persisted crashes found.");
    return persistedCrashReports;
  }
  for (NSURL *fileURL in files) {
    NSString *fileName = nil;
    [fileURL getResourceValue:&fileName forKey:NSURLNameKey error:nil];
    NSNumber *fileSizeNumber = nil;
    [fileURL getResourceValue:&fileSizeNumber forKey:NSURLFileSizeKey error:nil];
    NSNumber *isRegular = nil;
    [fileURL getResourceValue:&isRegular forKey:NSURLIsRegularFileKey error:nil];
    if ([isRegular boolValue] && [fileSizeNumber intValue] > 0 && ![fileName hasSuffix:@".DS_Store"] &&
        ![fileName hasSuffix:@".analyzer"] && ![fileName hasSuffix:@".plist"] && ![fileName hasSuffix:@".data"] &&
        ![fileName hasSuffix:@".meta"] && ![fileName hasSuffix:@".desc"]) {
      [persistedCrashReports addObject:fileURL];
    }
  }
  return persistedCrashReports;
}

- (void)removeAnalyzerFile {
  [MSUtility deleteItemForPathComponent:self.analyzerInProgressFilePathComponent];
}

- (void)createAnalyzerFile {
  NSURL *analyzerURL = [MSUtility createFileAtPathComponent:self.analyzerInProgressFilePathComponent
                                                   withData:nil
                                                 atomically:NO
                                             forceOverwrite:NO];
  if (!analyzerURL) {
    MSLogError([MSCrashes logTag], @"Couldn't create crash analyzer file.");
  }
}

- (void)setupLogBuffer {

  // We need to make this @synchronized here as we're setting up msCrashesLogBuffer.
  @synchronized(self) {

    // Setup asynchronously.
    NSMutableArray<NSURL *> *files = [NSMutableArray arrayWithCapacity:ms_crashes_log_buffer_size];

    /*
     * Create missing buffer files if needed. We don't care about which one's are already there, we'll skip existing ones.
     */
    for (NSUInteger i = 0; i < ms_crashes_log_buffer_size; i++) {

      // Files are named N.mscrasheslogbuffer where N is between 0 and ms_crashes_log_buffer_size.
      NSString *logId = @(i).stringValue;
      NSString *filePathComponent = [NSString stringWithFormat:@"%@/%@.%@", self.logBufferPathComponent, logId, kMSLogBufferFileExtension];
      [files addObject:[MSUtility fullURLForPathComponent:filePathComponent]];

      // Create files asynchronously. We don't really care as they are only ever used in the post-crash callback.
      dispatch_group_async(self.bufferFileGroup, self.bufferFileQueue, ^{
        [MSUtility createFileAtPathComponent:filePathComponent withData:nil atomically:NO forceOverwrite:NO];
      });

      // We need to convert the NSURL to NSString as we cannot safe NSURL to our async-safe log buffer.
      NSString *path = files[i].path;

      /*
       * Some explanation into what actually happens, courtesy of Gwynne: "Passing nil does not initialize anything to nil here, what
       * actually happens is an exploit of the Objective-C send-to-nil-returns-zero rule, so that the effective initialization becomes
       * `buffer(&(0)[0], &(0)[0])`, and since `NULL` is zero, `[0]` is equivalent to a direct dereference, and `&(*(NULL))` cancels out to
       * just `NULL`, it becomes `buffer(nullptr, nullptr)`, which is a no-op because the initializer code loops as `while(begin != end)`,
       * so the `nil` pointer is never dereferenced."
       */
      msCrashesLogBuffer[i] = MSCrashesBufferedLog(path, nil);

      // Save target token path as well to avoid memory allocation when saving.
      NSString *targetTokenPath = [path stringByReplacingOccurrencesOfString:kMSLogBufferFileExtension
                                                                  withString:kMSTargetTokenFileExtension];
      msCrashesLogBuffer[i].targetTokenPath = targetTokenPath.UTF8String;
    }
  }
}

- (void)emptyLogBufferFiles {
  NSString *bufferDir = [NSString stringWithFormat:@"%@", self.logBufferPathComponent];
  NSArray *files = [MSUtility contentsOfDirectory:bufferDir propertiesForKeys:nil];
  if (!files) {
    MSLogError([MSCrashes logTag], @"Couldn't get files in the directory \"%@\"", bufferDir);
    return;
  }
  for (NSURL *fileURL in files) {
    if ([[fileURL pathExtension] isEqualToString:kMSLogBufferFileExtension]) {

      // Create empty new file, overwrites the old one.
      NSNumber *fileSizeNumber = nil;
      [fileURL getResourceValue:&fileSizeNumber forKey:NSURLFileSizeKey error:nil];
      if ([fileSizeNumber intValue] > 0) {
        NSString *fileName = [fileURL lastPathComponent];
        NSString *filePathComponent = [NSString stringWithFormat:@"%@/%@", bufferDir, fileName];
        [MSUtility createFileAtPathComponent:filePathComponent withData:nil atomically:NO forceOverwrite:YES];
      }
    }
  }
}

- (BOOL)shouldProcessErrorReport:(MSErrorReport *)errorReport {
  id<MSCrashesDelegate> strongDelegate = self.delegate;
  return (!strongDelegate || ![strongDelegate respondsToSelector:@selector(crashes:shouldProcessErrorReport:)] ||
          [strongDelegate crashes:self shouldProcessErrorReport:errorReport]);
}

- (BOOL)delegateImplementsAttachmentCallback {
  id<MSCrashesDelegate> strongDelegate = self.delegate;
  return strongDelegate && [strongDelegate respondsToSelector:@selector(attachmentsWithCrashes:forErrorReport:)];
}

// We need to override setter, because it's default behavior creates an NSArray, and some tests fail.
- (void)setCrashFiles:(NSMutableArray *)crashFiles {
  _crashFiles = [[NSMutableArray alloc] initWithArray:crashFiles];
}

+ (BOOL)validatePropertiesForAttachment:(MSErrorAttachmentLog *)attachment {
  BOOL errorIdValid = attachment.errorId && ([attachment.errorId length] > 0);
  BOOL attachmentIdValid = attachment.attachmentId && ([attachment.attachmentId length] > 0);
  BOOL attachmentDataValid = attachment.data && ([attachment.data length] > 0);
  BOOL contentTypeValid = attachment.contentType && ([attachment.contentType length] > 0);

  return errorIdValid && attachmentIdValid && attachmentDataValid && contentTypeValid;
}

- (BOOL)sendCrashReportsOrAwaitUserConfirmation {
  BOOL alwaysSend = [self shouldAlwaysSend];

  // Get a user confirmation if there are crash logs that need to be processed.
  if ([self.unprocessedReports count] == 0) {
    return alwaysSend;
  }
  if (alwaysSend) {

    // User confirmation is set to MSUserConfirmationAlways.
    MSLogDebug([MSCrashes logTag], @"The flag for user confirmation is set to MSUserConfirmationAlways, continue sending logs");
    [self notifyWithUserConfirmation:MSUserConfirmationSend];
    return alwaysSend;
  } else if (self.automaticProcessing && !(self.userConfirmationHandler && [self userPromptedForConfirmation])) {

    // User confirmation handler doesn't exist or returned NO which means 'want to process'.
    MSLogDebug([MSCrashes logTag], @"The user confirmation handler is not implemented or returned NO, continue sending logs");
    [self notifyWithUserConfirmation:MSUserConfirmationSend];
  } else if (!self.automaticProcessing) {
    MSLogDebug([MSCrashes logTag], @"Automatic crash processing is disabled and \"AlwaysSend\" is false. Awaiting user confirmation.");
  }
  return alwaysSend;
}

- (BOOL)userPromptedForConfirmation {

  // User confirmation handler may contain UI so we have to run it in the main thread.
  __block BOOL userPromptedForConfirmation;
  if ([NSThread isMainThread]) {
    userPromptedForConfirmation = self.userConfirmationHandler(self.unprocessedReports);
  } else {
    dispatch_sync(dispatch_get_main_queue(), ^{
      userPromptedForConfirmation = self.userConfirmationHandler(self.unprocessedReports);
    });
  }
  return userPromptedForConfirmation;
}

/**
 * This is an instance method to make testing easier.
 */
- (BOOL)shouldAlwaysSend {
  NSNumber *flag = [MS_USER_DEFAULTS objectForKey:kMSUserConfirmationKey];
  return flag && [flag boolValue];
}

/**
 * Sends error attachments for a particular error report.
 */
+ (void)sendErrorAttachments:(NSArray<MSErrorAttachmentLog *> *)errorAttachments withIncidentIdentifier:(NSString *)incidentIdentifier {
  [[MSCrashes sharedInstance] sendErrorAttachments:errorAttachments withIncidentIdentifier:incidentIdentifier];
}

- (void)notifyWithUserConfirmation:(MSUserConfirmation)userConfirmation {
  NSArray<MSErrorAttachmentLog *> *attachments;

  // Check for user confirmation.
  if (userConfirmation == MSUserConfirmationDontSend) {

    // Don't send logs, clean up the files.
    for (NSUInteger i = 0; i < [self.unprocessedFilePaths count]; i++) {
      NSURL *fileURL = self.unprocessedFilePaths[i];
      MSErrorReport *report = self.unprocessedReports[i];
      [self deleteCrashReportWithFileURL:fileURL];
      [MSWrapperExceptionManager deleteWrapperExceptionWithUUIDString:report.incidentIdentifier];
      [self.crashFiles removeObject:fileURL];
    }

    // Return and do not continue with crash processing.
    [self clearUnprocessedReports];
    [self clearContextHistoryAndKeepCurrentSession];
    return;
  } else if (userConfirmation == MSUserConfirmationAlways) {

    /*
     * Always send logs. Set the flag YES to bypass user confirmation next time.
     * Continue crash processing afterwards.
     */
    [MS_USER_DEFAULTS setObject:[[NSNumber alloc] initWithBool:YES] forKey:kMSUserConfirmationKey];
  }

  // Process crashes logs.
  for (NSUInteger i = 0; i < [self.unprocessedReports count]; i++) {
    MSAppleErrorLog *log = self.unprocessedLogs[i];
    MSErrorReport *report = self.unprocessedReports[i];
    NSURL *fileURL = self.unprocessedFilePaths[i];

    // Get error attachments.
    if ([self delegateImplementsAttachmentCallback]) {
      attachments = [self.delegate attachmentsWithCrashes:self forErrorReport:report];
    } else {
      MSLogDebug([MSCrashes logTag], @"attachmentsWithCrashes is not implemented");
    }

    // First, get correlated session Id.
    log.sid = [[MSSessionContext sharedInstance] sessionIdAt:log.timestamp];

    // Second, get correlated user Id.
    log.userId = [[MSUserIdContext sharedInstance] userIdAt:log.timestamp];

    // Then, enqueue crash log.
    [self.channelUnit enqueueItem:log flags:MSFlagsPersistenceCritical];

    // Send error attachments.
    [self sendErrorAttachments:attachments withIncidentIdentifier:report.incidentIdentifier];

    // Clean up.
    [self deleteCrashReportWithFileURL:fileURL];
    [MSWrapperExceptionManager deleteWrapperExceptionWithUUIDString:report.incidentIdentifier];
    [self.crashFiles removeObject:fileURL];
  }
  [self clearUnprocessedReports];
  [self clearContextHistoryAndKeepCurrentSession];
}

- (void)clearUnprocessedReports {
  [self.unprocessedReports removeAllObjects];
  [self.unprocessedLogs removeAllObjects];
  [self.unprocessedFilePaths removeAllObjects];
}

+ (void)resetSharedInstance {

  // resets the once_token so dispatch_once will run again.
  onceToken = 0;
  sharedInstance = nil;
}

#pragma mark - Handled exceptions

- (void)trackModelException:(MSException *)exception withProperties:(NSDictionary<NSString *, NSString *> *)properties {
  if (![self isEnabled])
    return;

  // Create an error log.
  MSHandledErrorLog *log = [MSHandledErrorLog new];

  // Set userId to the error log.
  log.userId = [[MSUserIdContext sharedInstance] userId];

  // Set properties of the error log.
  log.errorId = MS_UUID_STRING;
  log.exception = exception;
  if (properties && properties.count > 0) {

    // Send only valid properties.
    log.properties = [MSUtility validateProperties:properties
                                        forLogName:[NSString stringWithFormat:@"ErrorLog: %@", log.errorId]
                                              type:log.type];
  }

  // Enqueue log.
  [self.channelUnit enqueueItem:log flags:MSFlagsDefault];
}

@end
