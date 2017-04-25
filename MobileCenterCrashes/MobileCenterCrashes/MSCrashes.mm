#import "MSAppleErrorLog.h"
#import "MSCrashesCXXExceptionWrapperException.h"
#import "MSCrashesDelegate.h"
#import "MSCrashesInternal.h"
#import "MSCrashesPrivate.h"
#import "MSCrashesUtil.h"
#import "MSErrorAttachmentLog.h"
#import "MSErrorAttachmentLogInternal.h"
#import "MSErrorLogFormatter.h"
#import "MSMobileCenterInternal.h"
#import "MSServiceAbstractProtected.h"
#import "MSWrapperExceptionManager.h"

/**
 * Service name for initialization.
 */
static NSString *const kMSServiceName = @"Crashes";

/**
 * The group ID for storage.
 */
static NSString *const kMSGroupID = @"Crashes";

/**
 * The group ID for log buffer.
 */
static NSString *const kMSBufferGroupID = @"CrashesBuffer";

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

std::array<MSCrashesBufferedLog, ms_crashes_log_buffer_size> msCrashesLogBuffer;

#pragma mark - Callbacks Setup

static MSCrashesCallbacks msCrashesCallbacks = {.context = NULL, .handleSignal = NULL};
static NSString *const kMSUserConfirmationKey = @"MSUserConfirmation";

static void ms_save_log_buffer_callback(__attribute__((unused)) siginfo_t *info,
                                        __attribute__((unused)) ucontext_t *uap,
                                        __attribute__((unused)) void *context) {

  // Do not save the buffer if it is empty.
  if (msCrashesLogBuffer.size() == 0) {
    return;
  }

  // Iterate over the buffered logs and write them to disk.
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
  }
}

// Proxy implementation for PLCrashReporter to keep our interface stable while this can change.
static void plcr_post_crash_callback(siginfo_t *info, ucontext_t *uap, void *context) {
  ms_save_log_buffer_callback(info, uap, context);
  [MSCrashes wrapperCrashCallback];

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

  // This relies on a LOT of sneaky internal knowledge of how PLCR works and
  // should not be considered a long-term solution.
  NSGetUncaughtExceptionHandler()([[MSCrashesCXXExceptionWrapperException alloc] initWithCXXExceptionInfo:info]);
  abort();
}

@interface MSCrashes ()

/**
 * Indicates if the app crashed in the previous session
 *
 * Use this on startup, to check if the app starts the first time after it crashed previously.
 * You can use this also to disable specific events, like asking the user to rate your app.
 *
 * @warning This property only has a correct value, once the sdk has been properly initialized!
 *
 * @see lastSessionCrashReport
 */
@property BOOL didCrashInLastSession;

/**
 * Detail information about the last crash.
 */
@property(getter=getLastSessionCrashReport) MSErrorReport *lastSessionCrashReport;

/**
 * Queue with high priority that will be used to create the log buffer files. The default main queue is too slow.
 */
@property(nonatomic) dispatch_queue_t bufferFileQueue;

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
        if ([MSMobileCenter isDebuggerAttached]) {
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
  MSCrashes *crashes = [self sharedInstance];
  NSArray<MSErrorAttachmentLog *> *attachments;

  // Check for user confirmation.
  if (userConfirmation == MSUserConfirmationDontSend) {

    // Don't send logs, clean up the files.
    for (NSUInteger i = 0; i < [crashes.unprocessedFilePaths count]; i++) {
      NSURL *fileURL = crashes.unprocessedFilePaths[i];
      MSErrorReport *report = crashes.unprocessedReports[i];
      [crashes deleteCrashReportWithFileURL:fileURL];
      [MSWrapperExceptionManager deleteWrapperExceptionDataWithUUIDString:report.incidentIdentifier];
      [crashes.crashFiles removeObject:fileURL];
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
  for (NSUInteger i = 0; i < [crashes.unprocessedReports count]; i++) {
    MSAppleErrorLog *log = crashes.unprocessedLogs[i];
    MSErrorReport *report = crashes.unprocessedReports[i];
    NSURL *fileURL = crashes.unprocessedFilePaths[i];

    // Get error attachments.
    if ([crashes delegateImplementsAttachmentCallback]) {
      attachments = [crashes.delegate attachmentsWithCrashes:crashes forErrorReport:report];
    } else {
      MSLogDebug([MSCrashes logTag], @"attachmentsWithCrashes is not implemented");
    }

    // First, send crash log to log manager.
    [crashes.logManager processLog:log forGroupID:crashes.groupID];

    // Then, send attachements log to log manager.
    for (MSErrorAttachmentLog *attachment in attachments) {
      attachment.errorId = log.errorId;
      [crashes.logManager processLog:attachment forGroupID:crashes.groupID];
    }

    // Clean up.
    [crashes deleteCrashReportWithFileURL:fileURL];
    [MSWrapperExceptionManager deleteWrapperExceptionDataWithUUIDString:report.incidentIdentifier];
    [crashes.crashFiles removeObject:fileURL];
  }
}

+ (MSErrorReport *_Nullable)lastSessionCrashReport {
  return [[self sharedInstance] getLastSessionCrashReport];
}

/* This can never be binded to Xamarin */
+ (void)enableMachExceptionHandler {
  [[self sharedInstance] setEnableMachExceptionHandler:YES];
}

+ (void)setDelegate:(_Nullable id<MSCrashesDelegate>)delegate {
  [[self sharedInstance] setDelegate:delegate];
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
    _channelConfiguration = [[MSChannelConfiguration alloc] initWithGroupID:[self groupID]
                                                                   priority:MSPriorityHigh
                                                              flushInterval:1.0
                                                             batchSizeLimit:10
                                                        pendingBatchesLimit:6];

    /**
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

  // Enabling
  if (isEnabled) {

    // Check if there is a wrapper SDK that needs to do some custom handler setup. If there is,
    // then the wrapper SDK will call [self configureCrashReporter].
    if (![[MSWrapperExceptionManager getDelegate] respondsToSelector:@selector(setUpCrashHandlers)] ||
        ![[MSWrapperExceptionManager getDelegate] setUpCrashHandlers]) {
      [self configureCrashReporter];
    }

    // PLCrashReporter keeps collecting crash reports even when the SDK is disabled,
    // delete them only if current state is disabled.
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

    // Set self as delegate of crashes' channel.
    [self.logManager addChannelDelegate:self forGroupID:self.groupID];

    // Process PLCrashReports, this will format the PLCrashReport into our schema and then trigger sending.
    // This mostly happens on the start of the service.
    if (self.crashFiles.count > 0) {
      [self startDelayedCrashProcessing];
    }

    MSLogInfo([MSCrashes logTag], @"Crashes service has been enabled.");

    // More details on log if a debugger is attached.
    if ([MSMobileCenter isDebuggerAttached]) {
      MSLogInfo([MSCrashes logTag], @"Crashes service has been enabled but the service cannot detect crashes due to "
                                     "running the application with a debugger attached.");
    } else {
      MSLogInfo([MSCrashes logTag], @"Crashes service has been enabled.");
    }
  } else {

    // Don't set PLCrashReporter to nil!
    MSLogDebug([MSCrashes logTag], @"Cleaning up all crash files.");
    [MSWrapperExceptionManager deleteAllWrapperExceptions];
    [MSWrapperExceptionManager deleteAllWrapperExceptionData];
    [self deleteAllFromCrashesDirectory];
    [self emptyLogBufferFiles];
    [self removeAnalyzerFile];
    [self.plCrashReporter purgePendingCrashReport];

    // Remove as ChannelDelegate from LogManager
    [self.logManager removeChannelDelegate:self forGroupID:self.groupID];
    [self.logManager removeChannelDelegate:self forGroupID:self.groupID];
    [self.logManager removeChannelDelegate:self forGroupID:self.groupID];
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
  [logManager initChannelWithConfiguration:[[MSChannelConfiguration alloc] initWithGroupID:kMSBufferGroupID
                                                                                  priority:MSPriorityHigh
                                                                             flushInterval:1.0
                                                                            batchSizeLimit:60
                                                                       pendingBatchesLimit:1]];

  [self processLogBufferAfterCrash];
  MSLogVerbose([MSCrashes logTag], @"Started crash service.");
}

+ (NSString *)logTag {
  return @"MobileCenterCrashes";
}

- (NSString *)groupID {
  return kMSGroupID;
}

- (MSInitializationPriority)initializationPriority {
  return MSInitializationPriorityMax;
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
  [self deleteBufferedLogWithInternalId:internalId];
}

- (void)onFailedPersistingLog:(id<MSLog>)log withInternalId:(NSString *)internalId {
  (void)log;
  [self deleteBufferedLogWithInternalId:internalId];
}

- (void)deleteBufferedLogWithInternalId:(NSString *)internalId {
  @synchronized(self) {
    for (auto it = msCrashesLogBuffer.begin(), end = msCrashesLogBuffer.end(); it != end; ++it) {
      NSString *bufferId = [NSString stringWithCString:it->internalId.c_str() encoding:NSUTF8StringEncoding];
      if (bufferId && bufferId.length > 0 && [bufferId isEqualToString:internalId]) {
        MSLogVerbose([MSCrashes logTag], @"Deleting item from buffer with id %@", internalId);
        it->buffer = [@"" cStringUsingEncoding:NSUTF8StringEncoding];
        it->timestamp = [@"" cStringUsingEncoding:NSUTF8StringEncoding];
        it->internalId = [@"" cStringUsingEncoding:NSUTF8StringEncoding];
      }
    }
  }
}

#pragma mark - MSChannelDelegate

- (void)channel:(id<MSChannel>)channel willSendLog:(id<MSLog>)log {
  (void)channel;
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

- (void)channel:(id<MSChannel>)channel didSucceedSendingLog:(id<MSLog>)log {
  (void)channel;
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

- (void)channel:(id<MSChannel>)channel didFailSendingLog:(id<MSLog>)log withError:(NSError *)error {
  (void)channel;
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

- (void)configureCrashReporter {
  if (self.plCrashReporter) {
    MSLogDebug([MSCrashes logTag], @"Already configured PLCrashReporter.");
    return;
  }

  PLCrashReporterSignalHandlerType signalHandlerType = PLCrashReporterSignalHandlerTypeBSD;
  if (self.isMachExceptionHandlerEnabled) {
    signalHandlerType = PLCrashReporterSignalHandlerTypeMach;
    MSLogVerbose([MSCrashes logTag], @"Enabled Mach exception handler.");
  }
  PLCrashReporterSymbolicationStrategy symbolicationStrategy = PLCrashReporterSymbolicationStrategyNone;
  MSPLCrashReporterConfig *config = [[MSPLCrashReporterConfig alloc] initWithSignalHandlerType:signalHandlerType
                                                                         symbolicationStrategy:symbolicationStrategy];
  self.plCrashReporter = [[MSPLCrashReporter alloc] initWithConfiguration:config];

  /**
   * The actual signal and mach handlers are only registered when invoking
   * `enableCrashReporterAndReturnError`, so it is safe enough to only disable
   * the following part when a debugger is attached no matter which signal
   * handler type is set.
   */
  if ([MSMobileCenter isDebuggerAttached]) {
    MSLogWarning([MSCrashes logTag],
                 @"Detecting crashes is NOT enabled due to running the app with a debugger attached.");
  } else {

    /**
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
    NSError *error = NULL;
    [self.plCrashReporter setCrashCallbacks:&plCrashCallbacks];
    if (![self.plCrashReporter enableCrashReporterAndReturnError:&error])
      MSLogError([MSCrashes logTag], @"Could not enable crash reporter: %@", [error localizedDescription]);
    NSUncaughtExceptionHandler *currentHandler = NSGetUncaughtExceptionHandler();
    if (currentHandler && currentHandler != initialHandler) {
      self.exceptionHandler = currentHandler;
      MSLogDebug([MSCrashes logTag], @"Exception handler successfully initialized.");
    } else {
      MSLogError([MSCrashes logTag],
                 @"Exception handler could not be set. Make sure there is no other exception handler set up!");
    }
    [MSCrashesUncaughtCXXExceptionHandlerManager addCXXExceptionHandler:uncaught_cxx_exception_handler];
  }
}

#pragma mark - Crash processing

- (void)startDelayedCrashProcessing {
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startCrashProcessing) object:nil];
  [self performSelector:@selector(startCrashProcessing) withObject:nil afterDelay:0.5];
}

- (void)startCrashProcessing {

  // FIXME: There is no life cycle for app extensions yet so force start crash processing until then.
  if ([MSUtility applicationState] != MSApplicationStateActive &&
      [MSUtility applicationState] != MSApplicationStateUnknown) {
    return;
  }
  MSLogDebug([MSCrashes logTag], @"Start delayed CrashManager processing");

  // Was our own exception handler successfully added?
  if (self.exceptionHandler) {

    // Get the current top level error handler
    NSUncaughtExceptionHandler *currentHandler = NSGetUncaughtExceptionHandler();

    /**
     * If the top level error handler differs from our own, at least another one was added.
     * This could cause exception crashes not to be reported to Mobile Center. Print out
     * log message for details.
     */
    if (self.exceptionHandler != currentHandler) {
      MSLogWarning([MSCrashes logTag], @"Another exception handler was added. If "
                                       @"this invokes any kind of exit() after processing the "
                                       @"exception, which causes any subsequent error handler "
                                       @"not to be invoked, these crashes will NOT be reported "
                                       @"to Mobile Center!");
    }
  }
  if (!self.sendingInProgress && self.crashFiles.count > 0) {
    [self processCrashReports];
  }
}

- (void)processCrashReports {
  NSError *error = NULL;
  self.unprocessedLogs = [[NSMutableArray alloc] init];
  self.unprocessedReports = [[NSMutableArray alloc] init];
  self.unprocessedFilePaths = [[NSMutableArray alloc] init];

  // Start crash processing for real.
  NSArray *tempCrashesFiles = [NSArray arrayWithArray:self.crashFiles];
  for (NSURL *fileURL in tempCrashesFiles) {
    NSString *uuidString;

    // We always start sending with the oldest pending one.
    NSData *crashFileData = [NSData dataWithContentsOfURL:fileURL];
    if ([crashFileData length] > 0) {
      MSLogVerbose([MSCrashes logTag], @"Crash report found");
      if (self.isEnabled) {
        MSPLCrashReport *report = [[MSPLCrashReport alloc] initWithData:crashFileData error:&error];
        MSAppleErrorLog *log = [MSErrorLogFormatter errorLogFromCrashReport:report];
        MSErrorReport *errorReport = [MSErrorLogFormatter errorReportFromLog:(log)];
        uuidString = errorReport.incidentIdentifier;
        if ([self shouldProcessErrorReport:errorReport]) {
          MSLogDebug([MSCrashes logTag],
                     @"shouldProcessErrorReport is not implemented or returned YES, processing the crash report: %@",
                     report.debugDescription);

          // Put the log to temporary space for next callbacks.
          [self.unprocessedLogs addObject:log];
          [self.unprocessedReports addObject:errorReport];
          [self.unprocessedFilePaths addObject:fileURL];

          continue;

        } else {
          MSLogDebug([MSCrashes logTag], @"shouldProcessErrorReport returned NO, discard the crash report: %@",
                     report.debugDescription);
        }
      } else {
        MSLogDebug([MSCrashes logTag], @"Crashes service is disabled, discard the crash report");
      }

      // Cleanup.
      [MSWrapperExceptionManager deleteWrapperExceptionDataWithUUIDString:uuidString];
      [self deleteCrashReportWithFileURL:fileURL];
      [self.crashFiles removeObject:fileURL];
    }
  }

  // Get a user confirmation if there are crash logs that need to be processed.
  if ([self.unprocessedLogs count] > 0) {
    NSNumber *flag = [MS_USER_DEFAULTS objectForKey:kMSUserConfirmationKey];
    if (flag && [flag boolValue]) {

      // User confirmation is set to MSUserConfirmationAlways.
      MSLogDebug([MSCrashes logTag],
                 @"The flag for user confirmation is set to MSUserConfirmationAlways, continue sending logs");
      [MSCrashes notifyWithUserConfirmation:MSUserConfirmationSend];
      return;
    } else if (!self.userConfirmationHandler || !self.userConfirmationHandler(self.unprocessedReports)) {

      // User confirmation handler doesn't exist or returned NO which means 'want to process'.
      MSLogDebug([MSCrashes logTag],
                 @"The user confirmation handler is not implemented or returned NO, continue sending logs");
      [MSCrashes notifyWithUserConfirmation:MSUserConfirmationSend];
    }
  }
}

- (void)processLogBufferAfterCrash {

  // Iterate over each file in it with the kMSLogBufferFileExtension and send the log if a log can be deserialized.
  NSError *error = nil;
  NSArray *files = [self.fileManager contentsOfDirectoryAtURL:self.logBufferDir
                                   includingPropertiesForKeys:nil
                                                      options:NSDirectoryEnumerationOptions(0)
                                                        error:&error];
  for (NSURL *fileURL in files) {
    if ([[fileURL pathExtension] isEqualToString:kMSLogBufferFileExtension]) {
      NSData *serializedLog = [NSData dataWithContentsOfURL:fileURL];
      if (serializedLog && serializedLog.length && serializedLog.length > 0) {
        id<MSLog> item = [NSKeyedUnarchiver unarchiveObjectWithData:serializedLog];
        if (item) {

          // Buffered logs are used sending their own channel. It will never contain more than 20 logs
          [self.logManager processLog:item forGroupID:kMSBufferGroupID];
        }
      }

      // Create empty new file, overwrites the old one.
      [[NSData data] writeToURL:fileURL atomically:NO];
    }
  }
}

#pragma mark - Helper

- (void)deleteAllFromCrashesDirectory {
  NSError *error = nil;
  NSArray *files = [self.fileManager contentsOfDirectoryAtURL:self.crashesDir
                                   includingPropertiesForKeys:nil
                                                      options:(NSDirectoryEnumerationOptions)0
                                                        error:&error];
  for (NSURL *fileURL in files) {
    [self.fileManager removeItemAtURL:fileURL error:&error];
    if (error) {
      MSLogError([MSCrashes logTag], @"Error deleting file %@: %@", fileURL, error.localizedDescription);
    }
  }
  [self.crashFiles removeAllObjects];
}

- (void)deleteCrashReportWithFileURL:(NSURL *)fileURL {
  NSError *error = nil;
  if ([fileURL checkResourceIsReachableAndReturnError:&error]) {
    [self.fileManager removeItemAtURL:fileURL error:&error];
  }
}

- (void)handleLatestCrashReport {
  NSError *error = nil;

  // Check if the next call ran successfully the last time
  if (![self.analyzerInProgressFile checkResourceIsReachableAndReturnError:&error]) {

    // Mark the start of the routine
    [self createAnalyzerFile];

    // Try loading the crash report
    NSData *crashData =
        [[NSData alloc] initWithData:[self.plCrashReporter loadPendingCrashReportDataAndReturnError:&error]];
    if (crashData == nil) {
      MSLogError([MSCrashes logTag], @"Could not load crash report: %@", error);
    } else {

      // Get data of PLCrashReport and write it to SDK directory
      MSPLCrashReport *report = [[MSPLCrashReport alloc] initWithData:crashData error:&error];
      if (report) {
        NSString *cacheFilename = [NSString stringWithFormat:@"%.0f", [NSDate timeIntervalSinceReferenceDate]];
        NSURL *cacheURL = [self.crashesDir URLByAppendingPathComponent:cacheFilename];
        [crashData writeToURL:cacheURL atomically:YES];
        self.lastSessionCrashReport = [MSErrorLogFormatter errorReportFromCrashReport:report];
      } else {
        MSLogWarning([MSCrashes logTag], @"Could not parse crash report");
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

  if ([self.crashesDir checkResourceIsReachableAndReturnError:&error]) {
    NSArray *files =
        [self.fileManager contentsOfDirectoryAtURL:self.crashesDir
                        includingPropertiesForKeys:@[ NSURLNameKey, NSURLFileSizeKey, NSURLIsRegularFileKey ]
                                           options:(NSDirectoryEnumerationOptions)0
                                             error:&error];
    for (NSURL *fileURL in files) {
      NSString *fileName = nil;
      [fileURL getResourceValue:&fileName forKey:NSURLNameKey error:&error];
      NSNumber *fileSizeNumber = nil;
      [fileURL getResourceValue:&fileSizeNumber forKey:NSURLFileSizeKey error:&error];
      NSNumber *isRegular = nil;
      [fileURL getResourceValue:&isRegular forKey:NSURLIsRegularFileKey error:&error];

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
  if ([self.analyzerInProgressFile checkResourceIsReachableAndReturnError:&error]) {
    if (![self.fileManager removeItemAtURL:self.analyzerInProgressFile error:&error]) {
      MSLogError([MSCrashes logTag], @"Couldn't remove analyzer file at %@ with error %@.", self.analyzerInProgressFile,
                 error.localizedDescription);
    }
  }
}

- (void)createAnalyzerFile {
  NSError *error = nil;
  if (![self.analyzerInProgressFile checkResourceIsReachableAndReturnError:&error]) {
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

    // Create missing buffer files if needed. We don't care about which one's are already there, we'll skip existing
    // ones.
    for (int i = 0; i < ms_crashes_log_buffer_size; i++) {

      // Files are named N.mscrasheslogbuffer where N is between 0 and ms_crashes_log_buffer_size.
      NSString *logId = @(i).stringValue;
      [files addObject:[self fileURLWithName:logId]];
    }

    // Create a buffer. Making use of `{}` as we're using C++11.
    for (NSUInteger i = 0; i < ms_crashes_log_buffer_size; i++) {

      // We need to convert the NSURL to NSString as we cannot safe NSURL to our async-safe log buffer.
      NSString *path = files[i].path;

      /**
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
  if (![self.logBufferDir checkResourceIsReachableAndReturnError:&error]) {
    [[NSFileManager defaultManager] createDirectoryAtURL:self.logBufferDir
                             withIntermediateDirectories:YES
                                              attributes:nil
                                                   error:nil];
  }
  NSURL *fileURL = [self.logBufferDir URLByAppendingPathComponent:fileName];
  if (![fileURL checkResourceIsReachableAndReturnError:&error]) {

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
  @synchronized(self) {
    BOOL success = [[NSData data] writeToURL:fileURL atomically:NO];
    if (success) {
      MSLogVerbose([MSCrashes logTag], @"Created file for log buffer: %@", [fileURL absoluteString]);
    } else {
      MSLogError([MSCrashes logTag], @"Couldn't create file for log buffer.");
    }
  }
}

- (void)emptyLogBufferFiles {
  NSError *error = nil;
  NSArray *files = [self.fileManager contentsOfDirectoryAtURL:self.logBufferDir
                                   includingPropertiesForKeys:@[ NSURLFileSizeKey ]
                                                      options:NSDirectoryEnumerationOptions(0)
                                                        error:&error];
  for (NSURL *fileURL in files) {
    if ([[fileURL pathExtension] isEqualToString:kMSLogBufferFileExtension]) {

      // Create empty new file, overwrites the old one.
      NSNumber *fileSizeNumber = nil;
      [fileURL getResourceValue:&fileSizeNumber forKey:NSURLFileSizeKey error:&error];
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
  return self.delegate && [self.delegate respondsToSelector:@selector(attachmentsWithCrashes:forErrorReport:)];
}

+ (void)wrapperCrashCallback {
  if (![MSWrapperExceptionManager hasException]) {
    return;
  }

  // If a wrapper SDK has passed an exception, save it to disk.
  NSError *error = NULL;
  NSData *crashData = [[NSData alloc]
      initWithData:[[[MSCrashes sharedInstance] plCrashReporter] loadPendingCrashReportDataAndReturnError:&error]];

  // This shouldn't happen because the callback should only happen once plCrashReporter has written the report to
  // disk.
  if (!crashData) {
    MSLogError([MSCrashes logTag], @"Could not load crash data: %@", error.localizedDescription);
  }
  MSPLCrashReport *report = [[MSPLCrashReport alloc] initWithData:crashData error:&error];
  if (report) {
    [MSWrapperExceptionManager saveWrapperException:report.uuidRef];
  } else {
    MSLogError([MSCrashes logTag], @"Could not load crash report: %@", error.localizedDescription);
  }
}

// We need to override setter, because it's default behavior creates an NSArray, and some tests fail.
- (void)setCrashFiles:(NSMutableArray *)crashFiles {
  _crashFiles = [[NSMutableArray alloc] initWithArray:crashFiles];
}

@end
