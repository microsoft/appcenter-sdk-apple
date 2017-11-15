#import "MSAppCenterInternal.h"
#import "MSAppleErrorLog.h"
#import "MSCrashesCXXExceptionWrapperException.h"
#import "MSCrashesDelegate.h"
#import "MSCrashesInternal.h"
#import "MSCrashesPrivate.h"
#import "MSCrashesUtil.h"
#import "MSCrashHandlerSetupDelegate.h"
#import "MSErrorAttachmentLog.h"
#import "MSErrorAttachmentLogInternal.h"
#import "MSErrorLogFormatter.h"
#import "MSHandledErrorLog.h"
#import "MSServiceAbstractProtected.h"
#import "MSWrapperExceptionManagerInternal.h"
#import "MSWrapperCrashesHelper.h"

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
 * Name for the AnalyzerInProgress file. Some background info here: writing the file to signal that we are processing
 * crashes proved to be faster and more reliable as e.g. storing a flag in the NSUserDefaults.
 */
static NSString *const kMSAnalyzerFilename = @"MSCrashes.analyzer";

/**
 * File extension for buffer files. Files will have a GUID as the file name and a .mscrasheslogbuffer as file
 * extension.
 */
static NSString *const kMSLogBufferFileExtension = @"mscrasheslogbuffer";

static unsigned int kMaxAttachmentsPerCrashReport = 2;

std::array<MSCrashesBufferedLog, ms_crashes_log_buffer_size> msCrashesLogBuffer;

#pragma mark - Callbacks Setup

static MSCrashesCallbacks msCrashesCallbacks = {.context = NULL, .handleSignal = NULL};
static NSString *const kMSUserConfirmationKey = @"MSUserConfirmation";
static volatile BOOL writeBufferTaskStarted = NO;

static void ms_save_log_buffer_callback(__attribute__((unused)) siginfo_t *info,
                                        __attribute__((unused)) ucontext_t *uap,
                                        __attribute__((unused)) void *context) {

  // Iterate over the buffered logs and write them to disk.
  writeBufferTaskStarted = YES;
  for (int i = 0; i < ms_crashes_log_buffer_size; i++) {

    // Make sure not to allocate any memory (e.g. copy).
    const std::string &data = msCrashesLogBuffer[i].buffer;
    const std::string &path = msCrashesLogBuffer[i].bufferPath;
    int fd = open(path.c_str(), O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd < 0) {
      continue;
    }
    write(fd, data.data(), data.size());
    close(fd);
    MSLogDebug([MSCrashes logTag], @"Closed a buffer file: %@",
               [NSString stringWithCString:path.c_str() encoding:[NSString defaultCStringEncoding]]);
  }
}

/**
 * Proxy implementation for PLCrashReporter to keep our interface stable while this can change.
 */
static void plcr_post_crash_callback(siginfo_t *info, ucontext_t *uap, void *context) {
  ms_save_log_buffer_callback(info, uap, context);
  if (msCrashesCallbacks.handleSignal != NULL) {
    msCrashesCallbacks.handleSignal(context);
  }
}

static PLCrashReporterCallbacks plCrashCallbacks = {
  .version = 0, .context = NULL, .handleSignal = plcr_post_crash_callback};

/**
 * C++ Exception Handler
 */
__attribute__((noreturn)) static void uncaught_cxx_exception_handler(const MSCrashesUncaughtCXXExceptionInfo *info) {

  /*
   * This relies on a LOT of sneaky internal knowledge of how PLCR works and should not be considered a long-term
   * solution.
   */
  NSGetUncaughtExceptionHandler()([[MSCrashesCXXExceptionWrapperException alloc] initWithCXXExceptionInfo:info]);
  abort();
}

@interface MSCrashes ()

/**
 * Indicates if the app crashed in the previous session.
 *
 * Use this on startup, to check if the app starts the first time after it crashed previously. You can use this also to
 * disable specific events, like asking the user to rate your app.
 *
 * @warning This property only has a correct value, once the sdk has been properly initialized!
 *
 * @see lastSessionCrashReport
 */
@property BOOL didCrashInLastSession;

/**
 * Indicates if the delayedProcessingSemaphore will need to be released
 * anymore. Useful for preventing overflows.
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
 * Semaphore for exclusion with "startDelayedCrashProcessing" method.
 */
@property dispatch_semaphore_t delayedProcessingSemaphore;

@end

@implementation MSCrashes

@synthesize delegate = _delegate;
@synthesize logManager = _logManager;
@synthesize channelConfiguration = _channelConfiguration;

#pragma mark - Public Methods

+ (void)generateTestCrash {

  @synchronized([self sharedInstance]) {
    if ([[self sharedInstance] canBeUsed]) {
      if ([MSUtility currentAppEnvironment] != MSEnvironmentAppStore) {
        if ([MSAppCenter isDebuggerAttached]) {
          MSLogWarning([MSCrashes logTag],
                       @"The debugger is attached. The following crash cannot be detected by the SDK!");
        }

        // Crashing the app here!
        __builtin_trap();
      }
    } else {
      MSLogWarning([MSCrashes logTag], @"GenerateTestCrash was just called in an App Store environment. The call will "
                   @"be ignored");
    }
  }
}

+ (BOOL)hasCrashedInLastSession {
  return [[self sharedInstance] didCrashInLastSession];
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
  return [[self sharedInstance] getLastSessionCrashReport];
}

/**
 * This can never be bound to Xamarin.
 *
 * This method is not part of the publicly available APIs on tvOS as Mach exception handling is not possible on tvOS.
 * The property is NO by default there.
 */
+ (void)disableMachExceptionHandler {
  [[self sharedInstance] setEnableMachExceptionHandler:NO];
}

+ (void)setDelegate:(_Nullable id<MSCrashesDelegate>)delegate {
  [[self sharedInstance] setDelegate:delegate];
}

/**
 * Track handled exception directly as model form.
 * This API is not public and is used by wrapper SDKs.
 */
+ (void)trackModelException:(MSException *)exception {
  @synchronized(self) {
    if ([[self sharedInstance] canBeUsed]) {
      [[self sharedInstance] trackModelException:exception];
    }
  }
}

#pragma mark - Service initialization

- (instancetype)init {
  if ((self = [super init])) {
    _fileManager = [[NSFileManager alloc] init];
    _crashFiles = [[NSMutableArray alloc] init];
    _crashesDir = [MSCrashesUtil crashesDir];
    _logBufferDir = [MSCrashesUtil logBufferDir];
    _analyzerInProgressFile = [_crashesDir URLByAppendingPathComponent:kMSAnalyzerFilename];
    _didCrashInLastSession = NO;
    _delayedProcessingSemaphore = dispatch_semaphore_create(0);
    _automaticProcessing = YES;
    _shouldReleaseProcessingSemaphore = YES;
#if !TARGET_OS_TV
    _enableMachExceptionHandler = YES;
#endif
    _channelConfiguration = [[MSChannelConfiguration alloc] initWithGroupId:[self groupId]
                                                                   priority:MSPriorityHigh
                                                              flushInterval:1.0
                                                             batchSizeLimit:1
                                                        pendingBatchesLimit:3];

#if TARGET_OS_OSX
    /*
     * AppKit is preventing applications from crashing on macOS so PLCrashReport cannot catch any crashes.
     * Setting this flag will let application crash on uncaught exceptions.
     */
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{ @"NSApplicationCrashOnExceptions" : @YES }];
#endif

    /*
     * Using our own queue with high priority as the default main queue is slower and we want the files to be created
     * as quickly as possible in case the app is crashing fast.
     */
    _bufferFileQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
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
    [self configureCrashReporterWithUncaughtExceptionHandlerEnabled:YES];

    // Allow a wrapper SDK to perform custom behavior after setting up crash handlers.
    if ([crashSetupDelegate respondsToSelector:@selector(didSetUpCrashHandlers)]) {
      [crashSetupDelegate didSetUpCrashHandlers];
    }

    /*
     * PLCrashReporter keeps collecting crash reports even when the SDK is disabled,
     * delete them only if current state is disabled.
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
     * Process PLCrashReports, this will format the PLCrashReport into our schema and then trigger sending. This mostly
     * happens on the start of the service.
     */
    if (self.crashFiles.count > 0) {
      [self startDelayedCrashProcessing];
    }
    else {
      dispatch_semaphore_signal(self.delayedProcessingSemaphore);
    }

    // More details on log if a debugger is attached.
    if ([MSAppCenter isDebuggerAttached]) {
      MSLogInfo([MSCrashes logTag], @"Crashes service has been enabled but the service cannot detect crashes due to "
                "running the application with a debugger attached.");
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
    MSLogInfo([MSCrashes logTag], @"Crashes service has been disabled.");
  }
}

#pragma mark - MSServiceInternal

+ (instancetype)sharedInstance {
  static id sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

+ (NSString *)serviceName {
  return kMSServiceName;
}

- (void)startWithLogManager:(id<MSLogManager>)logManager appSecret:(NSString *)appSecret {
  [super startWithLogManager:logManager appSecret:appSecret];
  [logManager addDelegate:self];

  // Initialize a dedicated channel for log buffer.
  [logManager initChannelWithConfiguration:[[MSChannelConfiguration alloc] initWithGroupId:kMSBufferGroupId
                                                                                  priority:MSPriorityHigh
                                                                             flushInterval:1.0
                                                                            batchSizeLimit:60
                                                                       pendingBatchesLimit:1]];

  [self processLogBufferAfterCrash];
  MSLogVerbose([MSCrashes logTag], @"Started crash service.");
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

#pragma mark - MSLogManagerDelegate

/**
 * Why are we doing the event-buffering inside crashes?
 * The reason is, only Crashes has the chance to execute code at crash time and only with the following constraints:
 * 1. Don't execute any Objective-C code when crashing.
 * 2. Don't allocate new memory when crashing.
 * 3. Only use async-safe C/C++ methods.
 * This means the Crashes module can't message any other module. All logic related to the buffer needs to happen before
 * the crash and then, at crash time, crashes has all info in place to save the buffer safely.
 **/
- (void)onEnqueuingLog:(id<MSLog>)log withInternalId:(NSString *)internalId {

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
      NSNumber *oldestTimestamp;
      NSNumberFormatter *timestampFormatter = [[NSNumberFormatter alloc] init];
      timestampFormatter.numberStyle = NSNumberFormatterDecimalStyle;
      long indexToDelete = 0;
      MSLogVerbose([MSCrashes logTag], @"Storing a log to Crashes Buffer: (sid: %@, type: %@)", log.sid, log.type);
      for (auto it = msCrashesLogBuffer.begin(), end = msCrashesLogBuffer.end(); it != end; ++it) {

        // We've found an empty element, buffer our log.
        if (it->buffer.empty()) {
          it->buffer = std::string(&reinterpret_cast<const char *>(serializedLog.bytes)[0],
                                   &reinterpret_cast<const char *>(serializedLog.bytes)[serializedLog.length]);
          it->internalId = internalId.UTF8String;
          NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
          it->timestamp = [[NSString stringWithFormat:@"%f", now] cStringUsingEncoding:NSUTF8StringEncoding];

          MSLogVerbose([MSCrashes logTag], @"Found an empty buffer position.");

          // We're done, no need to iterate any more and leave the method.
          return;
        } else {

          /*
           * The current element is full. Save the timestamp if applicable and continue iterating unless we have
           * reached the last element.
           */
          NSString *timestamp = [NSString stringWithCString:it->timestamp.c_str() encoding:NSUTF8StringEncoding];
          NSNumber *bufferedLogTimestamp = [timestampFormatter numberFromString:timestamp];

          // Remember the timestamp if the log is older than the previous one or the initial one.
          if (!oldestTimestamp || oldestTimestamp.doubleValue > bufferedLogTimestamp.doubleValue) {
            oldestTimestamp = bufferedLogTimestamp;
            indexToDelete = it - msCrashesLogBuffer.begin();
            MSLogVerbose([MSCrashes logTag], @"Remembering index %ld for oldest timestamp %@.", indexToDelete,
                         oldestTimestamp);
          }
        }

        /*
         * Continue to iterate until we reach en empty element, in which case we store the log in it and stop, or until
         * we reach the end of the buffer. In the later case, we will replace the oldest log with the current one
         */
      }

      // We've reached the last element in our buffer and we now go ahead and replace the oldest element.
      MSLogVerbose([MSCrashes logTag], @"Reached end of buffer. Next step is overwriting the oldest one.");

      // Overwrite the oldest buffered log.
      msCrashesLogBuffer[indexToDelete].buffer =
      std::string(&reinterpret_cast<const char *>(serializedLog.bytes)[0],
                  &reinterpret_cast<const char *>(serializedLog.bytes)[serializedLog.length]);
      msCrashesLogBuffer[indexToDelete].internalId = internalId.UTF8String;
      NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
      msCrashesLogBuffer[indexToDelete].timestamp =
      [[NSString stringWithFormat:@"%f", now] cStringUsingEncoding:NSUTF8StringEncoding];
      MSLogVerbose([MSCrashes logTag], @"Overwrote buffered log at index %ld.", indexToDelete);

      // We're done, no need to iterate any more. But no need to `return;` as we're at the end of the buffer.
    }
  }
}

- (void)onFinishedPersistingLog:(id<MSLog>)log withInternalId:(NSString *)internalId {
  (void)log;
  [self deleteBufferedLog:log withInternalId:internalId];
}

- (void)onFailedPersistingLog:(id<MSLog>)log withInternalId:(NSString *)internalId {
  (void)log;
  [self deleteBufferedLog:log withInternalId:internalId];
}

- (void)deleteBufferedLog:(id<MSLog>)log withInternalId:(NSString *)internalId {
  @synchronized(self) {
    for (auto it = msCrashesLogBuffer.begin(), end = msCrashesLogBuffer.end(); it != end; ++it) {
      NSString *bufferId = [NSString stringWithCString:it->internalId.c_str() encoding:NSUTF8StringEncoding];
      if (bufferId && bufferId.length > 0 && [bufferId isEqualToString:internalId]) {
        MSLogVerbose([MSCrashes logTag], @"Deleting a log from buffer with id %@", internalId);
        it->buffer = [@"" cStringUsingEncoding:NSUTF8StringEncoding];
        it->timestamp = [@"" cStringUsingEncoding:NSUTF8StringEncoding];
        it->internalId = [@"" cStringUsingEncoding:NSUTF8StringEncoding];
        if (writeBufferTaskStarted) {

          /*
           * Crashes already started writing buffer to files. To prevent sending duplicate logs after relaunch, it will
           * delete the buffer file.
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

- (void)willSendLog:(id<MSLog>)log {
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

- (void)didSucceedSendingLog:(id<MSLog>)log {
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

- (void)didFailSendingLog:(id<MSLog>)log withError:(NSError *)error {
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
  MSPLCrashReporterConfig *config =
  [[MSPLCrashReporterConfig alloc] initWithSignalHandlerType:signalHandlerType
                                       symbolicationStrategy:symbolicationStrategy
                      shouldRegisterUncaughtExceptionHandler:enableUncaughtExceptionHandler];
  self.plCrashReporter = [[MSPLCrashReporter alloc] initWithConfiguration:config];

  /*
   * The actual signal and mach handlers are only registered when invoking
   * `enableCrashReporterAndReturnError`, so it is safe enough to only disable
   * the following part when a debugger is attached no matter which signal
   * handler type is set.
   */
  if ([MSAppCenter isDebuggerAttached]) {
    MSLogWarning([MSCrashes logTag],
                 @"Detecting crashes is NOT enabled due to running the app with a debugger attached.");
  } else {

    /*
     * Multiple exception handlers can be set, but we can only query the top
     * level error handler (uncaught exception handler). To check if
     * PLCrashReporter's error handler is successfully added, we compare the top
     * level one that is set before and the one after PLCrashReporter sets up
     * its own. With delayed processing we can then check if another error
     * handler was set up afterwards and can show a debug warning log message,
     * that the dev has to make sure the "newer" error handler doesn't exit the
     * process itself, because then all subsequent handlers would never be
     * invoked. Note: ANY error handler setup BEFORE SDK initialization
     * will not be processed!
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
      MSLogDebug([MSCrashes logTag],
                 @"Exception handler successfully initialized but it has not been registered due to the wrapper SDK.");
    } else {
      MSLogError([MSCrashes logTag],
                 @"Exception handler could not be set. Make sure there is no other exception handler set up!");
    }

    // Add a handler for C++-Exceptions.
    [MSCrashesUncaughtCXXExceptionHandlerManager addCXXExceptionHandler:uncaught_cxx_exception_handler];
  }
}

#pragma mark - Crash processing

- (void)startDelayedCrashProcessing {
  /*
   * FIXME: If application is crashed and relaunched from multitasking view, the SDK starts faster than normal launch
   * and application state is not updated from inactive to active at this time. Give more delay here for a workaround
   * but we need to fix it eventually. This can also be happen if application is launched from Xcode and stoped by
   * clicking stop button on Xcode.
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
  // FIXME: There is no life cycle for app extensions yet so force start crash processing until then.
  // Also force start crash processing when automatic processing is disabled. Though it sounds
  // counterintuitive, this is important because there are scenarios in some wrappers (i.e. RN) where
  // the application state is not ready by the time crash processing needs to happen.
  if (self.automaticProcessing &&
      ([MSUtility applicationState] != MSApplicationStateActive &&
       [MSUtility applicationState] != MSApplicationStateUnknown)) {
        return;
      }
  MSLogDebug([MSCrashes logTag], @"Start delayed CrashManager processing");

  // Was our own exception handler successfully added?
  if (self.exceptionHandler) {

    // Get the current top level error handler
    NSUncaughtExceptionHandler *currentHandler = NSGetUncaughtExceptionHandler();

    /*
     * If the top level error handler differs from our own, at least another one was added.
     * This could cause exception crashes not to be reported to App Center. Print out
     * log message for details.
     */
    if (self.exceptionHandler != currentHandler) {
      MSLogWarning([MSCrashes logTag], @"Another exception handler was added. If "
                   @"this invokes any kind of exit() after processing the "
                   @"exception, which causes any subsequent error handler "
                   @"not to be invoked, these crashes will NOT be reported "
                   @"to App Center!");
    }
  }
  if (self.crashFiles.count > 0) {
    [self processCrashReports];
  }
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
  self.unprocessedReports = [[NSMutableArray alloc] init];
  self.unprocessedLogs = [[NSMutableArray alloc] init];
  self.unprocessedFilePaths = [[NSMutableArray alloc] init];

  // First save all found crash reports for use in correlation step.
  NSMutableDictionary *foundCrashReports = [[NSMutableDictionary alloc] init];
  NSMutableDictionary *foundErrorReports = [[NSMutableDictionary alloc] init];
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
        MSLogDebug([MSCrashes logTag],
                   @"Automatic crash processing is disabled, storing the crash report for later processing: %@",
                   report.debugDescription);
      } else {
        MSLogDebug([MSCrashes logTag],
                   @"shouldProcessErrorReport is not implemented or returned YES, processing the crash report: %@",
                   report.debugDescription);
      }

      // Put the log to temporary space for next callbacks.
      [self.unprocessedLogs addObject:log];
      [self.unprocessedReports addObject:errorReport];
      [self.unprocessedFilePaths addObject:fileURL];
    } else {
      MSLogDebug([MSCrashes logTag], @"shouldProcessErrorReport returned NO, discard the crash report: %@",
                 report.debugDescription);

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

  // Iterate over each file in it with the kMSLogBufferFileExtension and send the log if a log can be deserialized.
  NSError *error = nil;
  NSArray *files = [self.fileManager contentsOfDirectoryAtURL:self.logBufferDir
                                   includingPropertiesForKeys:nil
                                                      options:NSDirectoryEnumerationOptions(0)
                                                        error:&error];
  if (!files) {
    MSLogError([MSCrashes logTag], @"Couldn't get files in the directory \"%@\": %@", self.logBufferDir,
               error.localizedDescription);
    return;
  }
  for (NSURL *fileURL in files) {
    if ([[fileURL pathExtension] isEqualToString:kMSLogBufferFileExtension]) {
      NSData *serializedLog = [NSData dataWithContentsOfURL:fileURL];
      if (serializedLog && serializedLog.length && serializedLog.length > 0) {
        id<MSLog> item = [NSKeyedUnarchiver unarchiveObjectWithData:serializedLog];
        if (item) {

          // Buffered logs are used sending their own channel. It will never contain more than 20 logs
          [self.logManager processLog:item forGroupId:kMSBufferGroupId];
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
  NSMutableArray *filteredOutLogs = [[NSMutableArray alloc] init];
  NSMutableArray *filteredOutReports = [[NSMutableArray alloc] init];
  NSMutableArray *filteredOutFilePaths = [[NSMutableArray alloc] init];
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
- (void)sendErrorAttachments:(NSArray<MSErrorAttachmentLog *> *)errorAttachments
      withIncidentIdentifier:(NSString *)incidentIdentifier {

  // Send attachements log to log manager.
  unsigned int totalProcessedAttachments = 0;
  for (MSErrorAttachmentLog *attachment in errorAttachments) {
    attachment.errorId = incidentIdentifier;
    if (![MSCrashes validatePropertiesForAttachment:attachment]) {
      MSLogError([MSCrashes logTag], @"Not all required fields are present in MSErrorAttachmentLog.");
      continue;
    }
    [self.logManager processLog:attachment forGroupId:self.groupId];
    ++totalProcessedAttachments;
  }
  if (totalProcessedAttachments > kMaxAttachmentsPerCrashReport) {
    MSLogWarning([MSCrashes logTag], @"A limit of %u attachments per error report might be enforced by server.",
                 kMaxAttachmentsPerCrashReport);
  }
}

#pragma mark - Helper

- (void)deleteAllFromCrashesDirectory {
  NSError *error = nil;
  NSArray *files = [self.fileManager contentsOfDirectoryAtURL:self.crashesDir
                                   includingPropertiesForKeys:nil
                                                      options:NSDirectoryEnumerationOptions(0)
                                                        error:&error];
  if (!files) {
    MSLogError([MSCrashes logTag], @"Couldn't get files in the directory \"%@\": %@", self.crashesDir,
               error.localizedDescription);
    return;
  }
  for (NSURL *fileURL in files) {
    [self.fileManager removeItemAtURL:fileURL error:&error];
    if (error) {
      MSLogWarning([MSCrashes logTag], @"Couldn't delete file \"%@\": %@", fileURL, error.localizedDescription);
    }
  }
  [self.crashFiles removeAllObjects];
}

- (void)deleteCrashReportWithFileURL:(NSURL *)fileURL {
  NSError *error = nil;
  if ([fileURL checkResourceIsReachableAndReturnError:nil]) {
    [self.fileManager removeItemAtURL:fileURL error:&error];
    if (error) {
      MSLogWarning([MSCrashes logTag], @"Couldn't delete file \"%@\": %@", fileURL, error.localizedDescription);
    }
  }
}

- (void)handleLatestCrashReport {
  NSError *error = nil;

  // Check if the next call ran successfully the last time
  if (![self.analyzerInProgressFile checkResourceIsReachableAndReturnError:nil]) {

    // Mark the start of the routine
    [self createAnalyzerFile];

    // Try loading the crash report
    NSData *crashData =
    [[NSData alloc] initWithData:[self.plCrashReporter loadPendingCrashReportDataAndReturnError:&error]];
    if (crashData == nil) {
      MSLogError([MSCrashes logTag], @"Couldn't load crash report: %@", error.localizedDescription);
    } else {

      // Get data of PLCrashReport and write it to SDK directory
      MSPLCrashReport *report = [[MSPLCrashReport alloc] initWithData:crashData error:&error];
      if (report) {
        NSString *cacheFilename = [NSString stringWithFormat:@"%.0f", [NSDate timeIntervalSinceReferenceDate]];
        NSURL *cacheURL = [self.crashesDir URLByAppendingPathComponent:cacheFilename];
        [crashData writeToURL:cacheURL atomically:YES];
        self.lastSessionCrashReport = [MSErrorLogFormatter errorReportFromCrashReport:report];
        [MSWrapperExceptionManager correlateLastSavedWrapperExceptionToReport:@[ self.lastSessionCrashReport ]];
      } else {
        MSLogWarning([MSCrashes logTag], @"Couldn't parse crash report: %@", error.localizedDescription);
      }
    }

    // Purge the report marker at the end of the routine.
    [self removeAnalyzerFile];
  }
  [self.plCrashReporter purgePendingCrashReport];
}

- (NSMutableArray *)persistedCrashReports {
  NSError *error = nil;
  NSMutableArray *persistedCrashReports = [NSMutableArray new];

  if ([self.crashesDir checkResourceIsReachableAndReturnError:nil]) {
    NSArray *files =
    [self.fileManager contentsOfDirectoryAtURL:self.crashesDir
                    includingPropertiesForKeys:@[ NSURLNameKey, NSURLFileSizeKey, NSURLIsRegularFileKey ]
                                       options:NSDirectoryEnumerationOptions(0)
                                         error:&error];
    if (!files) {
      MSLogError([MSCrashes logTag], @"Couldn't get files in the directory \"%@\": %@", self.crashesDir,
                 error.localizedDescription);
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
  }
  return persistedCrashReports;
}

- (void)removeAnalyzerFile {
  NSError *error = nil;
  if ([self.analyzerInProgressFile checkResourceIsReachableAndReturnError:nil]) {
    if (![self.fileManager removeItemAtURL:self.analyzerInProgressFile error:&error]) {
      MSLogError([MSCrashes logTag], @"Couldn't remove analyzer file at %@ with error %@.", self.analyzerInProgressFile,
                 error.localizedDescription);
    }
  }
}

- (void)createAnalyzerFile {
  if (![self.analyzerInProgressFile checkResourceIsReachableAndReturnError:nil]) {
    if (![[NSData data] writeToURL:self.analyzerInProgressFile atomically:NO]) {
      MSLogError([MSCrashes logTag], @"Couldn't create analyzer file at %@: ", self.analyzerInProgressFile);
    }
  }
}

- (void)setupLogBuffer {

  // We need to make this @synchronized here as we're setting up msCrashesLogBuffer.
  @synchronized(self) {

    // Setup asynchronously.
    NSMutableArray<NSURL *> *files = [NSMutableArray arrayWithCapacity:ms_crashes_log_buffer_size];

    /*
     * Create missing buffer files if needed. We don't care about which one's are already there, we'll skip existing
     * ones.
     */
    for (int i = 0; i < ms_crashes_log_buffer_size; i++) {

      // Files are named N.mscrasheslogbuffer where N is between 0 and ms_crashes_log_buffer_size.
      NSString *logId = @(i).stringValue;
      [files addObject:[self fileURLWithName:logId]];
    }

    // Create a buffer. Making use of `{}` as we're using C++11.
    for (NSUInteger i = 0; i < ms_crashes_log_buffer_size; i++) {

      // We need to convert the NSURL to NSString as we cannot safe NSURL to our async-safe log buffer.
      NSString *path = files[i].path;

      /*
       * Some explanation into what actually happens, courtesy of Gwynne:
       * "Passing nil does not initialize anything to nil here, what actually happens is an exploit of the Objective-C
       * send-to-nil-returns-zero rule, so that the effective initialization becomes `buffer(&(0)[0], &(0)[0])`, and
       * since `NULL` is zero, `[0]` is equivalent to a direct dereference, and `&(*(NULL))` cancels out to
       * just `NULL`, it becomes `buffer(nullptr, nullptr)`, which is a no-op because the initializer code loops as
       * `while(begin != end)`, so the `nil` pointer is never dereferenced."
       */
      msCrashesLogBuffer[i] = MSCrashesBufferedLog(path, nil);
    }
  }
}

- (NSURL *)fileURLWithName:(NSString *)name {
  NSError *error = nil;
  NSString *fileName = [NSString stringWithFormat:@"%@.%@", name, kMSLogBufferFileExtension];
  if (![self.logBufferDir checkResourceIsReachableAndReturnError:nil]) {
    if (![[NSFileManager defaultManager] createDirectoryAtURL:self.logBufferDir
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error]) {
      MSLogError([MSCrashes logTag], @"Couldn't create directory at %@: %@", self.logBufferDir,
                 error.localizedDescription);
    }
  }
  NSURL *fileURL = [self.logBufferDir URLByAppendingPathComponent:fileName];
  if (![fileURL checkResourceIsReachableAndReturnError:nil]) {

    // Create files asynchronously. We don't really care as they are only ever used post-crash.
    dispatch_async(self.bufferFileQueue, ^{
      [self createBufferFileAtURL:fileURL];
    });
    return fileURL;
  } else {
    MSLogVerbose([MSCrashes logTag], @"Didn't create crash buffer file as one already existed at %@.", fileURL);
    return fileURL;
  }
}

- (void)createBufferFileAtURL:(NSURL *)fileURL {
  BOOL success = NO;
  @synchronized(self) {
    success = [[NSData data] writeToURL:fileURL atomically:NO];
  }
  if (success) {
    MSLogVerbose([MSCrashes logTag], @"Created file for log buffer: %@", [fileURL absoluteString]);
  } else {
    MSLogError([MSCrashes logTag], @"Couldn't create file for log buffer.");
  }
}

- (void)emptyLogBufferFiles {
  NSError *error = nil;
  NSArray *files = [self.fileManager contentsOfDirectoryAtURL:self.logBufferDir
                                   includingPropertiesForKeys:@[ NSURLFileSizeKey ]
                                                      options:NSDirectoryEnumerationOptions(0)
                                                        error:&error];
  if (!files) {
    MSLogError([MSCrashes logTag], @"Couldn't get files in the directory \"%@\": %@", self.logBufferDir,
               error.localizedDescription);
    return;
  }
  for (NSURL *fileURL in files) {
    if ([[fileURL pathExtension] isEqualToString:kMSLogBufferFileExtension]) {

      // Create empty new file, overwrites the old one.
      NSNumber *fileSizeNumber = nil;
      [fileURL getResourceValue:&fileSizeNumber forKey:NSURLFileSizeKey error:nil];
      if ([fileSizeNumber intValue] > 0) {
        [[NSData data] writeToURL:fileURL atomically:NO];
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
    MSLogDebug([MSCrashes logTag],
               @"The flag for user confirmation is set to MSUserConfirmationAlways, continue sending logs");
    [self notifyWithUserConfirmation:MSUserConfirmationSend];
    return alwaysSend;
  } else if (self.automaticProcessing && !(self.userConfirmationHandler && [self userPromptedForConfirmation])) {

    // User confirmation handler doesn't exist or returned NO which means 'want to process'.
    MSLogDebug([MSCrashes logTag],
               @"The user confirmation handler is not implemented or returned NO, continue sending logs");
    [self notifyWithUserConfirmation:MSUserConfirmationSend];
  } else if (!self.automaticProcessing) {
    MSLogDebug([MSCrashes logTag],
               @"Automatic crash processing is disabled and \"AlwaysSend\" is false. Awaiting user confirmation.");
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
+ (void)sendErrorAttachments:(NSArray<MSErrorAttachmentLog *> *)errorAttachments
      withIncidentIdentifier:(NSString *)incidentIdentifier {
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

    // First, send crash log to log manager.
    [self.logManager processLog:log forGroupId:self.groupId];

    // Send error attachments.
    [self sendErrorAttachments:attachments withIncidentIdentifier:report.incidentIdentifier];

    // Clean up.
    [self deleteCrashReportWithFileURL:fileURL];
    [MSWrapperExceptionManager deleteWrapperExceptionWithUUIDString:report.incidentIdentifier];
    [self.crashFiles removeObject:fileURL];
  }
}

#pragma mark - Handled exceptions

- (void)trackModelException:(MSException *)exception {
  if (![self isEnabled])
    return;

  // Create an error log.
  MSHandledErrorLog *log = [MSHandledErrorLog new];

  // Set properties of the error log.
  log.errorId = MS_UUID_STRING;
  log.exception = exception;

  // Send log to log manager.
  [self.logManager processLog:log forGroupId:self.groupId];
}

@end

