/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSAppleErrorLog.h"
#import "MSCrashesCXXExceptionWrapperException.h"
#import "MSCrashesDelegate.h"
#import "MSCrashesHelper.h"
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

#pragma mark - Callbacks Setup

static MSCrashesCallbacks msCrashesCallbacks = {.context = NULL, .handleSignal = NULL};
static NSString *const kMSUserConfirmationKey = @"MSUserConfirmation";

/** Proxy implementation for PLCrashReporter to keep our interface stable while
 *  this can change.
 */
static void plcr_post_crash_callback(siginfo_t *info, ucontext_t *uap, void *context) {
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
static void uncaught_cxx_exception_handler(const MSCrashesUncaughtCXXExceptionInfo *info) {
  // This relies on a LOT of sneaky internal knowledge of how PLCR works and
  // should not be considered a long-term solution.
  NSGetUncaughtExceptionHandler()([[MSCrashesCXXExceptionWrapperException alloc] initWithCXXExceptionInfo:info]);
  abort();
}

@interface MSCrashes () <MSChannelDelegate>

@end

@implementation MSCrashes

@synthesize delegate = _delegate;
@synthesize logManager = _logManager;

#pragma mark - Public Methods

+ (void)generateTestCrash {
  @synchronized([self sharedInstance]) {
    if ([[self sharedInstance] canBeUsed]) {
      if ([MSEnvironmentHelper currentAppEnvironment] != MSEnvironmentAppStore) {
        if ([MSMobileCenter isDebuggerAttached]) {
          MSLogWarning([MSCrashes getLoggerTag],
                       @"The debugger is attached. The following crash cannot be detected by the SDK!");
        }

        __builtin_trap();
      }
    } else {
      MSLogWarning([MSCrashes getLoggerTag],
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
  ((MSCrashes *)[self sharedInstance]).userConfirmationHandler = userConfirmationHandler;
}

+ (void)notifyWithUserConfirmation:(MSUserConfirmation)userConfirmation {
  MSCrashes *crashes = [self sharedInstance];

  if (userConfirmation == MSUserConfirmationDontSend) {

    // Don't send logs. Clean up files.
    for (NSUInteger i = 0; i < [crashes.unprocessedFilePaths count]; i++) {
      NSString *filePath = [crashes.unprocessedFilePaths objectAtIndex:i];
      MSErrorReport *report = [crashes.unprocessedReports objectAtIndex:i];
      [crashes deleteCrashReportWithFilePath:filePath];
      [MSWrapperExceptionManager deleteWrapperExceptionDataWithUUIDString:report.incidentIdentifier];
      [crashes.crashFiles removeObject:filePath];
    }
    return;
  } else if (userConfirmation == MSUserConfirmationAlways) {

    // Always send logs. Set the flag YES to bypass user confirmation next time.
    [kMSUserDefaults setObject:[[NSNumber alloc] initWithBool:YES] forKey:kMSUserConfirmationKey];
  }

  // Process crashes logs.
  for (NSUInteger i = 0; i < [crashes.unprocessedReports count]; i++) {
    MSAppleErrorLog *log = [crashes.unprocessedLogs objectAtIndex:i];
    MSErrorReport *report = [crashes.unprocessedReports objectAtIndex:i];
    NSString *filePath = [crashes.unprocessedFilePaths objectAtIndex:i];

    // Get error attachment.
    if ([crashes delegateImplementsAttachmentCallback])
      [log setErrorAttachment:[crashes.delegate attachmentWithCrashes:crashes forErrorReport:report]];
    else
      MSLogDebug([MSCrashes getLoggerTag], @"attachmentWithCrashes is not implemented");

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

+ (void)setDelegate:(_Nullable id<MSCrashesDelegate>)delegate {
  [[self sharedInstance] setDelegate:delegate];
}

#pragma mark - Service initialization

- (instancetype)init {
  if ((self = [super init])) {
    _fileManager = [[NSFileManager alloc] init];
    _crashFiles = [[NSMutableArray alloc] init];
    _crashesDir = [MSCrashesHelper crashesDir];
    _analyzerInProgressFile = [_crashesDir stringByAppendingPathComponent:kMSAnalyzerFilename];
    _didCrashInLastSession = NO;
  }
  return self;
}

#pragma mark - MSServiceAbstract

- (void)applyEnabledState:(BOOL)isEnabled {
  [super applyEnabledState:isEnabled];

  if (isEnabled) {
    [self configureCrashReporter];

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
    MSLogInfo([MSCrashes getLoggerTag], @"Crashes service has been enabled.");
  } else {
    // Don't set PLCrashReporter to nil!
    MSLogDebug([MSCrashes getLoggerTag], @"Cleaning up all crash files.");
    [MSWrapperExceptionManager deleteAllWrapperExceptions];
    [MSWrapperExceptionManager deleteAllWrapperExceptionData];
    [self deleteAllFromCrashesDirectory];
    [self removeAnalyzerFile];
    [self.plCrashReporter purgePendingCrashReport];
    [self.logManager removeChannelDelegate:self forPriority:MSPriorityHigh];
    MSLogInfo([MSCrashes getLoggerTag], @"Crashes service has been disabled.");
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

- (void)startWithLogManager:(id<MSLogManager>)logManager {
  [super startWithLogManager:logManager];
  MSLogVerbose([MSCrashes getLoggerTag], @"Started crash service.");
}

+ (NSString *)getLoggerTag {
  return @"MobileCenterCrashes";
}

- (NSString *)storageKey {
  return kMSServiceName;
}

- (MSPriority)priority {
  return MSPriorityHigh;
}

#pragma mark - MSChannelDelegate

- (void)channel:(id)channel willSendLog:(id<MSLog>)log {
  if (self.delegate && [self.delegate respondsToSelector:@selector(crashes:willSendErrorReport:)]) {
    if ([((NSObject *)log) isKindOfClass:[MSAppleErrorLog class]]) {
      MSErrorReport *report = [MSErrorLogFormatter errorReportFromLog:((MSAppleErrorLog *)log)];
      [self.delegate crashes:self willSendErrorReport:report];
    }
  }
}

- (void)channel:(id<MSChannel>)channel didSucceedSendingLog:(id<MSLog>)log {
  if (self.delegate && [self.delegate respondsToSelector:@selector(crashes:didSucceedSendingErrorReport:)]) {
    if ([((NSObject *)log) isKindOfClass:[MSAppleErrorLog class]]) {
      MSErrorReport *report = [MSErrorLogFormatter errorReportFromLog:((MSAppleErrorLog *)log)];
      [self.delegate crashes:self didSucceedSendingErrorReport:report];
    }
  }
}

- (void)channel:(id<MSChannel>)channel didFailSendingLog:(id<MSLog>)log withError:(NSError *)error {
  if (self.delegate && [self.delegate respondsToSelector:@selector(crashes:didFailSendingErrorReport:withError:)]) {
    if ([((NSObject *)log) isKindOfClass:[MSAppleErrorLog class]]) {
      MSErrorReport *report = [MSErrorLogFormatter errorReportFromLog:((MSAppleErrorLog *)log)];
      [self.delegate crashes:self didFailSendingErrorReport:report withError:error];
    }
  }
}

#pragma mark - Crash reporter configuration

- (void)configureCrashReporter {

  if (_plCrashReporter) {
    MSLogDebug([MSCrashes getLoggerTag], @"Already configured PLCrashReporter.");
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
    MSLogWarning([MSCrashes getLoggerTag],
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
      MSLogError([MSCrashes getLoggerTag], @"Could not enable crash reporter: %@", [error localizedDescription]);
    NSUncaughtExceptionHandler *currentHandler = NSGetUncaughtExceptionHandler();
    if (currentHandler && currentHandler != initialHandler) {
      self.exceptionHandler = currentHandler;

      MSLogDebug([MSCrashes getLoggerTag], @"Exception handler successfully initialized.");
    } else {
      MSLogError([MSCrashes getLoggerTag],
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
  if (![MSCrashesHelper isAppExtension] &&
      [[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
    return;
  }

  MSLogDebug([MSCrashes getLoggerTag], @"Start delayed CrashManager processing");

  // Was our own exception handler successfully added?
  if (self.exceptionHandler) {

    // Get the current top level error handler
    NSUncaughtExceptionHandler *currentHandler = NSGetUncaughtExceptionHandler();

    /* If the top level error handler differs from our own, then at least
     * another one was added.
     * This could cause exception crashes not to be reported to Mobile Center. See
     * log message for details.
     */
    if (self.exceptionHandler != currentHandler) {
      MSLogWarning([MSCrashes getLoggerTag], @"Another exception handler was added. If "
                                             @"this invokes any kind of exit() after processing the "
                                             @"exception, which causes any subsequent error handler "
                                             @"not to be invoked, these crashes will NOT be reported "
                                             @"to Mobile Center!");
    }
  }
  if (!self.sendingInProgress && self.crashFiles.count > 0) {

    // TODO: Send and clean next crash report
    [self processCrashReport];
  }
}

- (void)processCrashReport {
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
      MSLogVerbose([MSCrashes getLoggerTag], @"Crash report found");
      if (self.isEnabled) {
        MSPLCrashReport *report = [[MSPLCrashReport alloc] initWithData:crashFileData error:&error];
        MSAppleErrorLog *log = [MSErrorLogFormatter errorLogFromCrashReport:report];
        MSErrorReport *errorReport = [MSErrorLogFormatter errorReportFromLog:(log)];
        uuidString = errorReport.incidentIdentifier;
        if ([self shouldProcessErrorReport:errorReport]) {
          MSLogDebug([MSCrashes getLoggerTag],
                     @"shouldProcessErrorReport is not implemented or returned YES, processing the crash report: %@",
                     report.debugDescription);

          // Put the log to temporary space for next callbacks.
          [_unprocessedLogs addObject:log];
          [_unprocessedReports addObject:errorReport];
          [_unprocessedFilePaths addObject:filePath];

          continue;
        } else {
          MSLogDebug([MSCrashes getLoggerTag], @"shouldProcessErrorReport returned NO, discard the crash report: %@",
                     report.debugDescription);
        }
      } else {
        MSLogDebug([MSCrashes getLoggerTag], @"Crashes service is disabled, discard the crash report");
      }

      [MSWrapperExceptionManager deleteWrapperExceptionDataWithUUIDString:uuidString];
      [self deleteCrashReportWithFilePath:filePath];
      [self.crashFiles removeObject:filePath];
    }
  }

  // Get a user confirmation if there are crash logs that need to be processed.
  if ([_unprocessedLogs count] > 0) {
    NSNumber *flag = [kMSUserDefaults objectForKey:kMSUserConfirmationKey];
    if (flag && [flag boolValue]) {

      // User confirmation is set to MSUserConfirmationAlways.
      MSLogDebug([MSCrashes getLoggerTag],
                 @"The flag for user confirmation is set to MSUserConfirmationAlways, continue sending logs");
      [MSCrashes notifyWithUserConfirmation:MSUserConfirmationSend];
      return;
    } else if (!_userConfirmationHandler || !_userConfirmationHandler(_unprocessedReports)) {

      // User confirmation handler doesn't exist or returned NO which means 'want to process'.
      MSLogDebug([MSCrashes getLoggerTag],
                 @"The user confirmation handler is not implemented or returned NO, continue sending logs");
      [MSCrashes notifyWithUserConfirmation:MSUserConfirmationSend];
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
      MSLogError([MSCrashes getLoggerTag], @"Error deleting file %@: %@", filePath, error.localizedDescription);
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
      MSLogError([MSCrashes getLoggerTag], @"Could not load crash report: %@", error);
    } else {

      // Get data of PLCrashReport and write it to SDK directory
      MSPLCrashReport *report = [[MSPLCrashReport alloc] initWithData:crashData error:&error];

      if (report) {
        [crashData writeToFile:[self.crashesDir stringByAppendingPathComponent:cacheFilename] atomically:YES];
        _lastSessionCrashReport = [MSErrorLogFormatter errorReportFromCrashReport:report];
      } else {
        MSLogWarning([MSCrashes getLoggerTag], @"Could not parse crash report");
      }
    }

    // Purge the report mark at the end of the routine
    [self removeAnalyzerFile];
  }

  [self.plCrashReporter purgePendingCrashReport];
}

- (NSMutableArray *)persistedCrashReports {
  NSMutableArray *persitedCrashReports = [NSMutableArray new];
  if ([self.fileManager fileExistsAtPath:self.crashesDir]) {
    NSError *error;
    NSArray *dirArray = [self.fileManager contentsOfDirectoryAtPath:self.crashesDir error:&error];

    for (NSString *file in dirArray) {
      NSString *filePath = [self.crashesDir stringByAppendingPathComponent:file];
      NSDictionary *fileAttributes = [self.fileManager attributesOfItemAtPath:filePath error:&error];

      if ([[fileAttributes objectForKey:NSFileType] isEqualToString:NSFileTypeRegular] &&
          [[fileAttributes objectForKey:NSFileSize] intValue] > 0 && ![file hasSuffix:@".DS_Store"] &&
          ![file hasSuffix:@".analyzer"] && ![file hasSuffix:@".plist"] && ![file hasSuffix:@".data"] &&
          ![file hasSuffix:@".meta"] && ![file hasSuffix:@".desc"]) {
        [persitedCrashReports addObject:filePath];
      }
    }
  }
  return persitedCrashReports;
}

- (void)removeAnalyzerFile {
  if ([self.fileManager fileExistsAtPath:self.analyzerInProgressFile]) {
    NSError *error = nil;
    if (![self.fileManager removeItemAtPath:self.analyzerInProgressFile error:&error]) {
      MSLogError([MSCrashes getLoggerTag], @"Couldn't remove analyzer file at %@: ", self.analyzerInProgressFile);
    }
  }
}

- (void)createAnalyzerFile {
  if (![self.fileManager fileExistsAtPath:self.analyzerInProgressFile]) {
    [self.fileManager createFileAtPath:self.analyzerInProgressFile contents:nil attributes:nil];
  }
}

- (BOOL)shouldProcessErrorReport:(MSErrorReport *)errorReport {
  return (!self.delegate || ![self.delegate respondsToSelector:@selector(crashes:shouldProcessErrorReport:)] ||
          [self.delegate crashes:self shouldProcessErrorReport:errorReport]);
}

- (BOOL)delegateImplementsAttachmentCallback {
  return self.delegate && [self.delegate respondsToSelector:@selector(attachmentWithCrashes:forErrorReport:)];
}

+ (void)wrapperCrashCallback {
  if (![MSWrapperExceptionManager hasException]) {
    return;
  }

  // If a wrapper SDK has passed an execption, save it to disk

  NSError *error = NULL;
  NSData *crashData = [[NSData alloc]
      initWithData:[[[MSCrashes sharedInstance] plCrashReporter] loadPendingCrashReportDataAndReturnError:&error]];

  // This shouldn't happen because the callback should only happen once plCrashReporter
  // has written the report to disk
  if (!crashData) {
    MSLogError([MSCrashes getLoggerTag], @"Could not load crash data: %@", error.localizedDescription);
  }

  MSPLCrashReport *report = [[MSPLCrashReport alloc] initWithData:crashData error:&error];

  if (report) {
    [MSWrapperExceptionManager saveWrapperException:report.uuidRef];
  } else {
    MSLogError([MSCrashes getLoggerTag], @"Could not load crash report: %@", error.localizedDescription);
  }
}

@end
