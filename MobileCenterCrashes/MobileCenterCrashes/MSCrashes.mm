/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */


#import <string>
#import <unordered_map>
#import <list>
#import <array>

#import "MSAppleErrorLog.h"
#import "MSCrashesCXXExceptionWrapperException.h"
#import "MSCrashesDelegate.h"
#import "MSCrashesUtil.h"
#import "MSCrashesInternal.h"
#import "MSCrashesPrivate.h"
#import "MSErrorLogFormatter.h"
#import "MSMobileCenterInternal.h"
#import "MSServiceAbstractProtected.h"
#import "MSWrapperExceptionManager.h"

/**
 *  Service name.
 */
static NSString *const kMSServiceName = @"Crashes";
static NSString *const kMSAnalyzerFilename = @"MSCrashes.analyzer";
static NSString *const kMSLogBufferFileExtension = @"mscrasheslogbuffer";

#pragma mark - Callbacks Setup

static MSCrashesCallbacks msCrashesCallbacks = {.context = NULL, .handleSignal = NULL};
static NSString *const kMSUserConfirmationKey = @"MSUserConfirmation";


/**
 * Data structure for logs that need to be flushed at crash time to make sure no log is lost at crash time.
 * @property bufferPath The path where the buffered log should be persisted.
 * @property buffer The actual buffered data. It comes in the form of a std::string but actually contains an NSData object
 * which is a serialized log.
 */
struct BUFFERED_LOG {
    std::string bufferPath;
    std::string buffer;

    BUFFERED_LOG() = default;

    BUFFERED_LOG(NSString *path, NSData *data) :
            bufferPath(path.UTF8String),
            buffer(&reinterpret_cast<const char *>(data.bytes)[0], &reinterpret_cast<const char *>(data.bytes)[data.length]) {
    }
};

std::array<BUFFERED_LOG, 20> logBuffer;
std::array<BUFFERED_LOG, 20>::iterator logBufferIterator;


static void ms_save_log_buffer_callback(siginfo_t *info, ucontext_t *uap, void *context) {
  // Do not save the buffer if it is empty.
  if (logBuffer.size() == 0) {
    return;
  }

  for (std::array<BUFFERED_LOG, 20>::iterator it = logBuffer.begin(), end = logBuffer.end(); it != end; ++it) {
    // Make sure not to allocate any memory (e.g. copy) but use the iterator.
    const std::string buffer = it->buffer;
    int fd = open(it->bufferPath.c_str(), O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd < 0) {
      return;
    }
    write(fd, it->buffer.data(), it->buffer.size());
    close(fd);
  }
}

/** Proxy implementation for PLCrashReporter to keep our interface stable while
 *  this can change.
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
static void uncaught_cxx_exception_handler(const MSCrashesUncaughtCXXExceptionInfo *info) {
  // This relies on a LOT of sneaky internal knowledge of how PLCR works and
  // should not be considered a long-term solution.
  NSGetUncaughtExceptionHandler()([[MSCrashesCXXExceptionWrapperException alloc] initWithCXXExceptionInfo:info]);
  abort();
}

@interface MSCrashes () <MSChannelDelegate, MSLogManagerDelegate>

@end

@implementation MSCrashes

@synthesize delegate = _delegate;
@synthesize logManager = _logManager;

#pragma mark - Public Methods

+ (void)generateTestCrash {
  @synchronized ([self sharedInstance]) {
    if ([[self sharedInstance] canBeUsed]) {
      if ([MSUtil currentAppEnvironment] != MSEnvironmentAppStore) {
        if ([MSMobileCenter isDebuggerAttached]) {
          MSLogWarning([MSCrashes logTag],
                  @"The debugger is attached. The following crash cannot be detected by the SDK!");
        }

        __builtin_trap();
      }
    } else {
      MSLogWarning([MSCrashes logTag],
              @"GenerateTestCrash was just called in an App Store environment. The call will "
                      @"be ignored");
    }
  }
}

+ (BOOL)hasCrashedInLastSession {
  return [[self sharedInstance] didCrashInLastSession];
}

+ (void)setUserConfirmationHandler:(_Nullable MSUserConfirmationHandler)userConfirmationHandler {
  // FIXME: Type cast is required at the moment. Need to fix the root cause.
  ((MSCrashes *) [self sharedInstance]).userConfirmationHandler = userConfirmationHandler;
}

+ (void)notifyWithUserConfirmation:(MSUserConfirmation)userConfirmation {
  MSCrashes *crashes = [self sharedInstance];

  if (userConfirmation == MSUserConfirmationDontSend) {

    // Don't send logs. Clean up files.
    for (NSUInteger i = 0; i < [crashes.unprocessedFilePaths count]; i++) {
      NSString *filePath = crashes.unprocessedFilePaths[i];
      MSErrorReport *report = crashes.unprocessedReports[i];
      [crashes deleteCrashReportWithFilePath:filePath];
      [MSWrapperExceptionManager deleteWrapperExceptionDataWithUUIDString:report.incidentIdentifier];
      [crashes.crashFiles removeObject:filePath];
    }
    return;
  } else if (userConfirmation == MSUserConfirmationAlways) {

    // Always send logs. Set the flag YES to bypass user confirmation next time.
    [MS_USER_DEFAULTS setObject:[[NSNumber alloc] initWithBool:YES] forKey:kMSUserConfirmationKey];
  }

  // Process crashes logs.
  for (NSUInteger i = 0; i < [crashes.unprocessedReports count]; i++) {
    MSAppleErrorLog *log = crashes.unprocessedLogs[i];
    MSErrorReport *report = crashes.unprocessedReports[i];
    NSString *filePath = crashes.unprocessedFilePaths[i];

    // Get error attachment.
    if ([crashes delegateImplementsAttachmentCallback]) {
      // TODO (attachmentWithCrashes): Bring this back when the backend supports attachment for Crashes.
//      [log setErrorAttachment:[crashes.delegate attachmentWithCrashes:crashes forErrorReport:report]];
    } else {
      MSLogDebug([MSCrashes logTag], @"attachmentWithCrashes is not implemented");
    }

    // Send log to log manager.
    [crashes.logManager processLog:log withPriority:crashes.priority];
    [crashes deleteCrashReportWithFilePath:filePath];
    [MSWrapperExceptionManager deleteWrapperExceptionDataWithUUIDString:report.incidentIdentifier];
    [crashes.crashFiles removeObject:filePath];
  }
}

+ (MSErrorReport *_Nullable)lastSessionCrashReport {

  return [[self sharedInstance] getLastSessionCrashReport];
}

+ (void)setDelegate:(_Nullable id <MSCrashesDelegate>)delegate {
  [[self sharedInstance] setDelegate:delegate];
}

#pragma mark - Service initialization

- (instancetype)init {
  if ((self = [super init])) {
    _fileManager = [[NSFileManager alloc] init];
    _crashFiles = [[NSMutableArray alloc] init];
    _crashesDir = [MSCrashesUtil crashesDir];
    _analyzerInProgressFile = [_crashesDir stringByAppendingPathComponent:kMSAnalyzerFilename];
    _didCrashInLastSession = NO;

    // Array of 20 buffer file paths.
    NSArray<NSString *> *bufferFiles = [self createLogBufferFilesIfNeeded];

    // Just to make sure we have max of 20 files on disk. If we have less than 20 files on disk, we can't really do
    // anything. This case should never happen.
    int count = bufferFiles.count >= 20 ? 20: bufferFiles.count;

    logBufferIterator = logBuffer.begin();

    for (int i = 0; i < count; i++) {
      BUFFERED_LOG emptyLog = BUFFERED_LOG{bufferFiles[i], nil};
      logBuffer[i] = emptyLog;
    }

    // Move iterator to the start of the list.
    logBufferIterator = logBuffer.begin();
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
      _didCrashInLastSession = YES;
      [self handleLatestCrashReport];
    }

    // Get persisted crash reports.
    _crashFiles = [self persistedCrashReports];

    // Set self as delegate of crashes' channel.
    [self.logManager addChannelDelegate:self forPriority:MSPriorityHigh];

    // Process PLCrashReports, this will format the PLCrashReport into our schema and then trigger sending.
    // This mostly happens on the start of the service.
    if (self.crashFiles.count > 0) {
      [self startDelayedCrashProcessing];
    }
    MSLogInfo([MSCrashes logTag], @"Crashes service has been enabled.");

    // More details on log if a debugger is attached.
    if ([MSMobileCenter isDebuggerAttached]) {
      MSLogInfo([MSCrashes logTag], @"Crashes service has been enabled but the service cannot detect crashes due to running the application with a debugger attached.");
    } else {
      MSLogInfo([MSCrashes logTag], @"Crashes service has been enabled.");
    }
  } else {

    // Don't set PLCrashReporter to nil!
    MSLogDebug([MSCrashes logTag], @"Cleaning up all crash files.");
    [MSWrapperExceptionManager deleteAllWrapperExceptions];
    [MSWrapperExceptionManager deleteAllWrapperExceptionData];
    [self deleteAllFromCrashesDirectory];
    [self removeAnalyzerFile];
    [self.plCrashReporter purgePendingCrashReport];

    // Remove as ChannelDelegate from LogManager
    [self.logManager removeChannelDelegate:self forPriority:MSPriorityHigh];
    [self.logManager removeChannelDelegate:self forPriority:MSPriorityDefault];
    [self.logManager removeChannelDelegate:self forPriority:MSPriorityBackground];

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

- (void)startWithLogManager:(id <MSLogManager>)logManager {
  [super startWithLogManager:logManager];

  [logManager addDelegate:self];
  [self processLogBufferAfterCrash];

  MSLogVerbose([MSCrashes logTag], @"Started crash service.");
}

+ (NSString *)logTag {
  return @"MobileCenterCrashes";
}

- (NSString *)storageKey {
  return kMSServiceName;
}

- (MSPriority)priority {
  return MSPriorityHigh;
}

#pragma mark - MSLogManagerDelegate

- (void)onProcessingLog:(id <MSLog>)log withPriority:(MSPriority)priority {
  MSLogVerbose([MSCrashes logTag], @"Did enqeue log.");

  if (!log) {
    return;
  }
// The callback can be called from any thread, making sure we make this thread-safe.
  @synchronized (self) {
    NSData *serializedLog = [NSKeyedArchiver archivedDataWithRootObject:log];

    if (serializedLog && (serializedLog.length > 0)) {
      long index = std::distance(logBuffer.begin(), logBufferIterator);
      if (index >= 20) {
        logBufferIterator = logBuffer.begin();
      }
      logBufferIterator->buffer = std::string(&reinterpret_cast<const char *>(serializedLog.bytes)[0], &reinterpret_cast<const char *>(serializedLog.bytes)[serializedLog.length]);

      ++logBufferIterator;
    }
  }
}

- (NSArray<NSString *> *)createLogBufferFilesIfNeeded {

  NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.crashesDir error:NULL];
  NSMutableArray *logBufferFiles = [NSMutableArray arrayWithCapacity:20];

  // Get already existing buffer files.
  for (NSString *tmp in files) {
    if ([[tmp pathExtension] isEqualToString:kMSLogBufferFileExtension]) {
      NSString *filePath = [self.crashesDir stringByAppendingPathComponent:tmp];
      [logBufferFiles addObject:filePath];
    }
  }

  // Create missing buffer files if needed.
  if (logBufferFiles.count < 20) {
    int missingFileCount = 20 - logBufferFiles.count;
    for (int i = 0; i < missingFileCount; i++) {
      NSString *logId = MS_UUID_STRING;
      NSString *path = [self createBufferFileForBufferId:logId];
      [logBufferFiles addObject:path];
    }
  }

  return logBufferFiles;
}

#pragma mark - MSChannelDelegate

- (void)channel:(id)channel willSendLog:(id <MSLog>)log {
  if (self.delegate && [self.delegate respondsToSelector:@selector(crashes:willSendErrorReport:)]) {
    if ([((NSObject *) log) isKindOfClass:[MSAppleErrorLog class]]) {
      MSErrorReport *report = [MSErrorLogFormatter errorReportFromLog:((MSAppleErrorLog *) log)];
      [self.delegate crashes:self willSendErrorReport:report];
    }
  }
}

- (void)channel:(id <MSChannel>)channel didSucceedSendingLog:(id <MSLog>)log {
  if (self.delegate && [self.delegate respondsToSelector:@selector(crashes:didSucceedSendingErrorReport:)]) {
    if ([((NSObject *) log) isKindOfClass:[MSAppleErrorLog class]]) {
      MSErrorReport *report = [MSErrorLogFormatter errorReportFromLog:((MSAppleErrorLog *) log)];
      [self.delegate crashes:self didSucceedSendingErrorReport:report];
    }
  }
}

- (void)channel:(id <MSChannel>)channel didFailSendingLog:(id <MSLog>)log withError:(NSError *)error {
  if (self.delegate && [self.delegate respondsToSelector:@selector(crashes:didFailSendingErrorReport:withError:)]) {
    if ([((NSObject *) log) isKindOfClass:[MSAppleErrorLog class]]) {
      MSErrorReport *report = [MSErrorLogFormatter errorReportFromLog:((MSAppleErrorLog *) log)];
      [self.delegate crashes:self didFailSendingErrorReport:report withError:error];
    }
  }
}

#pragma mark - Crash reporter configuration

- (void)configureCrashReporter {
  if (_plCrashReporter) {
    MSLogDebug([MSCrashes logTag], @"Already configured PLCrashReporter.");
    return;
  }

  PLCrashReporterSignalHandlerType signalHandlerType = PLCrashReporterSignalHandlerTypeBSD;
  PLCrashReporterSymbolicationStrategy symbolicationStrategy = PLCrashReporterSymbolicationStrategyNone;
  MSPLCrashReporterConfig *config = [[MSPLCrashReporterConfig alloc] initWithSignalHandlerType:signalHandlerType
                                                                         symbolicationStrategy:symbolicationStrategy];
  _plCrashReporter = [[MSPLCrashReporter alloc] initWithConfiguration:config];

  /**
   The actual signal and mach handlers are only registered when invoking
   `enableCrashReporterAndReturnError`, so it is safe enough to only disable
   the following part when a debugger is attached no matter which signal
   handler type is set.
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
  if ([MSUtil applicationState] != MSApplicationStateActive &&
          [MSUtil applicationState] != MSApplicationStateUnknown) {
    return;
  }

  MSLogDebug([MSCrashes logTag], @"Start delayed CrashManager processing");

  // Was our own exception handler successfully added?
  if (self.exceptionHandler) {

    // Get the current top level error handler
    NSUncaughtExceptionHandler *currentHandler = NSGetUncaughtExceptionHandler();

    /* If the top level error handler differs from our own, then at least
     * another one was added.
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
  _unprocessedLogs = [[NSMutableArray alloc] init];
  _unprocessedReports = [[NSMutableArray alloc] init];
  _unprocessedFilePaths = [[NSMutableArray alloc] init];

  NSArray *tempCrashesFiles = [NSArray arrayWithArray:self.crashFiles];
  for (NSString *filePath in tempCrashesFiles) {
    NSString *uuidString;

    // we start sending always with the oldest pending one
    NSData *crashFileData = [NSData dataWithContentsOfFile:filePath];
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
          [_unprocessedLogs addObject:log];
          [_unprocessedReports addObject:errorReport];
          [_unprocessedFilePaths addObject:filePath];

          continue;
        } else {
          MSLogDebug([MSCrashes logTag], @"shouldProcessErrorReport returned NO, discard the crash report: %@",
                  report.debugDescription);
        }
      } else {
        MSLogDebug([MSCrashes logTag], @"Crashes service is disabled, discard the crash report");
      }

      [MSWrapperExceptionManager deleteWrapperExceptionDataWithUUIDString:uuidString];
      [self deleteCrashReportWithFilePath:filePath];
      [self.crashFiles removeObject:filePath];
    }
  }

  // Get a user confirmation if there are crash logs that need to be processed.
  if ([_unprocessedLogs count] > 0) {
    NSNumber *flag = [MS_USER_DEFAULTS objectForKey:kMSUserConfirmationKey];
    if (flag && [flag boolValue]) {

      // User confirmation is set to MSUserConfirmationAlways.
      MSLogDebug([MSCrashes logTag],
              @"The flag for user confirmation is set to MSUserConfirmationAlways, continue sending logs");
      [MSCrashes notifyWithUserConfirmation:MSUserConfirmationSend];
      return;
    } else if (!_userConfirmationHandler || !_userConfirmationHandler(_unprocessedReports)) {

      // User confirmation handler doesn't exist or returned NO which means 'want to process'.
      MSLogDebug([MSCrashes logTag],
              @"The user confirmation handler is not implemented or returned NO, continue sending logs");
      [MSCrashes notifyWithUserConfirmation:MSUserConfirmationSend];
    }
  }
}

- (void)processLogBufferAfterCrash {
  NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.crashesDir
                                                                       error:NULL];
  for (NSString *tmp in files) {
    if ([[tmp pathExtension] isEqualToString:kMSLogBufferFileExtension]) {
      NSString *filePath = [self.crashesDir stringByAppendingPathComponent:tmp];
      NSData *serializedLog = [NSData dataWithContentsOfFile:filePath];

      id <MSLog> item = [NSKeyedUnarchiver unarchiveObjectWithData:serializedLog];
      if (item) {
        if ([((NSObject *) item) isKindOfClass:[MSAppleErrorLog class]]) {
          [self.logManager processLog:item withPriority:self.priority];
        } else {
          [self.logManager processLog:item withPriority:MSPriorityDefault];
        }
      }
      // Create empty new file, overwrites the old one.
      [[NSFileManager defaultManager] createFileAtPath:filePath contents:[NSData data] attributes:nil];
    }
  }
}

#pragma mark - Helper

- (void)deleteAllFromCrashesDirectory {
  NSError *error = nil;
  for (NSString *filePath in [self.fileManager enumeratorAtPath:self.crashesDir]) {
    NSString *path = [self.crashesDir stringByAppendingPathComponent:filePath];
    [_fileManager removeItemAtPath:path error:&error];

    if (error) {
      MSLogError([MSCrashes logTag], @"Error deleting file %@: %@", filePath, error.localizedDescription);
    }
  }
  [self.crashFiles removeAllObjects];
}

- (void)deleteCrashReportWithFilePath:(NSString *)filePath {
  NSError *error = NULL;
  if ([self.fileManager fileExistsAtPath:filePath]) {
    [self.fileManager removeItemAtPath:filePath error:&error];
  }
}

- (void)handleLatestCrashReport {
  NSError *error = NULL;
  // Check if the next call ran successfully the last time
  if (![self.fileManager fileExistsAtPath:self.analyzerInProgressFile]) {

    // Mark the start of the routine
    [self createAnalyzerFile];

    // Try loading the crash report
    NSData *crashData =
            [[NSData alloc] initWithData:[self.plCrashReporter loadPendingCrashReportDataAndReturnError:&error]];
    NSString *cacheFilename = [NSString stringWithFormat:@"%.0f", [NSDate timeIntervalSinceReferenceDate]];

    if (crashData == nil) {
      MSLogError([MSCrashes logTag], @"Could not load crash report: %@", error);
    } else {

      // Get data of PLCrashReport and write it to SDK directory
      MSPLCrashReport *report = [[MSPLCrashReport alloc] initWithData:crashData error:&error];

      if (report) {
        [crashData writeToFile:[self.crashesDir stringByAppendingPathComponent:cacheFilename] atomically:YES];
        _lastSessionCrashReport = [MSErrorLogFormatter errorReportFromCrashReport:report];
      } else {
        MSLogWarning([MSCrashes logTag], @"Could not parse crash report");
      }
    }

    // Purge the report mark at the end of the routine
    [self removeAnalyzerFile];
  }

  [self.plCrashReporter purgePendingCrashReport];
}

- (NSMutableArray *)persistedCrashReports {
  NSMutableArray *persistedCrashReports = [NSMutableArray new];
  if ([self.fileManager fileExistsAtPath:self.crashesDir]) {
    NSError *error;
    NSArray *dirArray = [self.fileManager contentsOfDirectoryAtPath:self.crashesDir error:&error];

    for (NSString *file in dirArray) {
      NSString *filePath = [self.crashesDir stringByAppendingPathComponent:file];
      NSDictionary *fileAttributes = [self.fileManager attributesOfItemAtPath:filePath error:&error];

      if ([fileAttributes[NSFileType] isEqualToString:NSFileTypeRegular] &&
              [fileAttributes[NSFileSize] intValue] > 0 && ![file hasSuffix:@".DS_Store"] &&
              ![file hasSuffix:@".analyzer"] && ![file hasSuffix:@".plist"] && ![file hasSuffix:@".data"] &&
              ![file hasSuffix:@".meta"] && ![file hasSuffix:@".desc"]) {
        [persistedCrashReports addObject:filePath];
      }
    }
  }
  return persistedCrashReports;
}

- (void)removeAnalyzerFile {
  if ([self.fileManager fileExistsAtPath:self.analyzerInProgressFile]) {
    NSError *error = nil;
    if (![self.fileManager removeItemAtPath:self.analyzerInProgressFile error:&error]) {
      MSLogError([MSCrashes logTag], @"Couldn't remove analyzer file at %@ with error %@.",
              self.analyzerInProgressFile, error.localizedDescription);
    }
  }
}

- (void)createAnalyzerFile {
  if (![self.fileManager fileExistsAtPath:self.analyzerInProgressFile]) {
    if (![self.fileManager createFileAtPath:self.analyzerInProgressFile contents:nil attributes:nil]) {
      MSLogError([MSCrashes logTag], @"Couldn't create analyzer file at %@: ", self.analyzerInProgressFile);
    }
  }
}

- (NSString *)createBufferFileForBufferId:(NSString *)bufferId {
  NSString *fileName = [NSString stringWithFormat:@"%@.%@", bufferId, kMSLogBufferFileExtension];
  NSString *filePath = [_crashesDir stringByAppendingPathComponent:fileName];

  if (![self.fileManager fileExistsAtPath:filePath]) {
    BOOL success = [self.fileManager createFileAtPath:filePath contents:nil attributes:nil];
    if (!success) {
      MSLogError([MSCrashes logTag], @"Couldn't create crash buffer file at: %@.", filePath);
      return nil;
    } else {
      MSLogVerbose([MSCrashes logTag], @"Created crash buffer file at %@.", filePath);
      return filePath;
    }
  } else {
    return filePath;
  }
}


- (BOOL)shouldProcessErrorReport:(MSErrorReport *)errorReport {
  return (!self.delegate || ![self.delegate respondsToSelector:@selector(crashes:shouldProcessErrorReport:)] ||
          [self.delegate crashes:self shouldProcessErrorReport:errorReport]);
}

- (BOOL)delegateImplementsAttachmentCallback {
  // TODO (attachmentWithCrashes): Bring this back when the backend supports attachment for Crashes.
//   return self.delegate && [self.delegate respondsToSelector:@selector(attachmentWithCrashes:forErrorReport:)];
  return NO;
}

+ (void)wrapperCrashCallback {
  if (![MSWrapperExceptionManager hasException]) {
    return;
  }

  // If a wrapper SDK has passed an exception, save it to disk

  NSError *error = NULL;
  NSData *crashData = [[NSData alloc]
          initWithData:[[[MSCrashes sharedInstance] plCrashReporter] loadPendingCrashReportDataAndReturnError:&error]];

  // This shouldn't happen because the callback should only happen once plCrashReporter
  // has written the report to disk
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

@end
