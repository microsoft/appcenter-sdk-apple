/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVACrashesPrivate.h"
#import "AvalancheHub+Internal.h"
#import "AVACrashesHelper.h"
#import "AVACrashCXXExceptionWrapperException.h"

static NSString *const kAVAAnalyzerFilename =
@"AVACrashes.analyzer";

#pragma mark - Callbacks Setup

static AVACrashesCallbacks avaCrashCallbacks = {
  .context = NULL,
  .handleSignal = NULL
};

// Proxy implementation for PLCrashReporter to keep our interface stable while this can change
static void plcr_post_crash_callback (siginfo_t *info, ucontext_t *uap, void *context) {
  if (avaCrashCallbacks.handleSignal != NULL) {
    avaCrashCallbacks.handleSignal(context);
  }
}

static PLCrashReporterCallbacks plCrashCallbacks = {
  .version = 0,
  .context = NULL,
  .handleSignal = plcr_post_crash_callback
};

// C++ Exception Handler
static void uncaught_cxx_exception_handler(const AVACrashUncaughtCXXExceptionInfo *info) {
  // This relies on a LOT of sneaky internal knowledge of how PLCR works and should not be considered a long-term solution.
  NSGetUncaughtExceptionHandler()([[AVACrashCXXExceptionWrapperException alloc] initWithCXXExceptionInfo:info]);
  abort();
}

@implementation AVACrashes

@synthesize delegate = _delegate;

#pragma mark - Module initialization

+ (id)sharedInstance {
  static id sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (instancetype)init {
  if ((self = [super init])) {
    _fileManager = [[NSFileManager alloc] init];
    _crashFiles = [[NSMutableArray alloc] init];
    _crashesDir = [AVACrashesHelper crashesDir];
    _analyzerInProgressFile = [_crashesDir stringByAppendingPathComponent:kAVAAnalyzerFilename];
  }
  return self;
}

- (void)startFeature {
  AVALogVerbose(@"[AVACrashes] VERBOSE: Started crash module");

  [self configureCrashReporter];

  if ([self.plCrashReporter hasPendingCrashReport]) {
    [self persistLatestCrashReport];
  }
  
  _crashFiles = [self persitedCrashReports];
  if(self.crashFiles.count > 0) {
    [self startDelayedCrashProcessing];
  }
}

+ (void)setEnable:(BOOL)isEnabled {
}

+ (BOOL)isEnabled {
  return YES;
}

#pragma mark - Crash reporter configuration

- (void)configureCrashReporter {
  static dispatch_once_t plcrPredicate;
  dispatch_once(&plcrPredicate, ^{
    PLCrashReporterSignalHandlerType signalHandlerType =
        PLCrashReporterSignalHandlerTypeBSD;
    PLCrashReporterSymbolicationStrategy symbolicationStrategy =
        PLCrashReporterSymbolicationStrategyNone;
    AVAPLCrashReporterConfig *config = [[AVAPLCrashReporterConfig alloc]
        initWithSignalHandlerType:signalHandlerType
            symbolicationStrategy:symbolicationStrategy];
    _plCrashReporter =
        [[AVAPLCrashReporter alloc] initWithConfiguration:config];

    /**
     The actual signal and mach handlers are only registered when invoking
     `enableCrashReporterAndReturnError`, so it is safe enough to only disable
     the following part when a debugger is attached no matter which signal
     handler type is set.
     */
    if ([AVACrashesHelper isDebuggerAttached]) {
      AVALogWarning(@"[AVACrashes] WARNING: Detecting crashes is NOT "
                    @"enabled due to running the app with a debugger "
                    @"attached.");
    } else {

      /**
       Multiple exception handlers can be set, but we can only query the top
       level error handler (uncaught exception handler). To check if
       PLCrashReporter's error handler is successfully added, we compare the top
       level one that is set before and the one after PLCrashReporter sets up
       its own. With delayed processing we can then check if another error
       handler was set up afterwards and can show a debug warning log message,
       that the dev has to make sure the "newer" error handler doesn't exit the
       process itself, because then all subsequent handlers would never be
       invoked. Note: ANY error handler setup BEFORE HockeySDK initialization
       will not be processed!
       */
      NSUncaughtExceptionHandler *initialHandler =
          NSGetUncaughtExceptionHandler();

      NSError *error = NULL;
      [self.plCrashReporter setCrashCallbacks:&plCrashCallbacks];
      if (![self.plCrashReporter enableCrashReporterAndReturnError:&error])
        AVALogError(@"[AVACrashes] ERROR: Could not enable crash reporter: %@",
                    [error localizedDescription]);
      NSUncaughtExceptionHandler *currentHandler =
          NSGetUncaughtExceptionHandler();
      if (currentHandler && currentHandler != initialHandler) {
        self.exceptionHandler = currentHandler;

        AVALogDebug(@"[AVACrashes] INFO: Exception handler successfully initialized.");
      } else {
        AVALogError(@"[AVACrashes] ERROR: Exception handler could not be "
                    @"set. Make sure there is no other exception "
                    @"handler set up!");
      }
      [AVACrashUncaughtCXXExceptionHandlerManager
          addCXXExceptionHandler:uncaught_cxx_exception_handler];
    }
  });
}

#pragma mark - Crash processing

- (void)startDelayedCrashProcessing {
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startCrashProcessing) object:nil];
  [self performSelector:@selector(startCrashProcessing) withObject:nil afterDelay:0.5];
}

- (void)startCrashProcessing {
  if (![AVACrashesHelper isAppExtension] &&
      [[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
    return;
  }
  
  AVALogDebug(@"[AVACrashes] INFO: Start delayed CrashManager processing");
  
  // Was our own exception handler successfully added?
  if (self.exceptionHandler) {
    
    // Get the current top level error handler
    NSUncaughtExceptionHandler *currentHandler = NSGetUncaughtExceptionHandler();
    
    // If the top level error handler differs from our own, then at least another one was added.
    // This could cause exception crashes not to be reported to HockeyApp. See log message for details.
    if (self.exceptionHandler != currentHandler) {
      AVALogWarning(@"[AVACrashes] WARNING: Another exception handler was added. If this invokes any kind exit() after processing the exception, which causes any subsequent error handler not to be invoked, these crashes will NOT be reported to HockeyApp!");
    }
  }
  if (!self.sendingInProgress && self.crashFiles.count > 0) {
    
    // TODO: Send and clean next crash report
    PLCrashReport *report = [self nextCrashReport];
    AVALogVerbose(@"[AVACrashes] VERBOSE: Crash report found: %@ ", report.debugDescription);
  }
}

- (AVAPLCrashReport *)nextCrashReport {
  NSError *error = NULL;
  AVAPLCrashReport *report;
  
  if ([self.crashFiles count] > 0) {

    // we start sending always with the oldest pending one
    NSString *filename = [self.crashFiles objectAtIndex:0];
    NSData *crashFileData = [NSData dataWithContentsOfFile:filename];
  
    if ([crashFileData length] > 0) {
     report = [[AVAPLCrashReport alloc] initWithData:crashFileData error:&error];
    }
  }
  return report;
}

#pragma mark - Helper

- (void)persistLatestCrashReport {
  NSError *error = NULL;
  
  // Check if the next call ran successfully the last time
  if (![self.fileManager fileExistsAtPath:self.analyzerInProgressFile]) {
    
    // Mark the start of the routine
    [self createAnalyzerFile];
    
    // Try loading the crash report
    NSData *crashData = [[NSData alloc] initWithData:[self.plCrashReporter loadPendingCrashReportDataAndReturnError: &error]];
    NSString *cacheFilename = [NSString stringWithFormat: @"%.0f", [NSDate timeIntervalSinceReferenceDate]];
    
    if (crashData == nil) {
      AVALogError(@"[AVACrashes] ERROR: Could not load crash report: %@", error);
    } else {
      
      // Get data of PLCrashReport and write it to SDK directory
      AVAPLCrashReport *report = [[AVAPLCrashReport alloc] initWithData:crashData error:&error];
      if (report) {
        [crashData writeToFile:[self.crashesDir stringByAppendingPathComponent: cacheFilename] atomically:YES];
      } else {
        AVALogWarning(@"[AVACrashes] WARNING: Could not parse crash report");
      }
    }
    
    // Purge the report mark the end of the routine
    [self removeAnalyzerFile];
  }
  
  [self.plCrashReporter purgePendingCrashReport];
}

- (NSMutableArray *)persitedCrashReports {
  NSMutableArray *persitedCrashReports;
  if ([self.fileManager fileExistsAtPath:self.crashesDir]) {
    NSError *error;
    NSArray *dirArray = [self.fileManager contentsOfDirectoryAtPath:self.crashesDir error:&error];
    
    for (NSString *file in dirArray) {
      persitedCrashReports = [NSMutableArray new];
      NSString *filePath = [self.crashesDir stringByAppendingPathComponent:file];
      NSDictionary *fileAttributes = [self.fileManager attributesOfItemAtPath:filePath error:&error];
      
      if ([[fileAttributes objectForKey:NSFileType] isEqualToString:NSFileTypeRegular] &&
          [[fileAttributes objectForKey:NSFileSize] intValue] > 0 &&
          ![file hasSuffix:@".DS_Store"] &&
          ![file hasSuffix:@".analyzer"] &&
          ![file hasSuffix:@".plist"] &&
          ![file hasSuffix:@".data"] &&
          ![file hasSuffix:@".meta"] &&
          ![file hasSuffix:@".desc"]) {
        [persitedCrashReports addObject:filePath];
      }
    }
  }
  return persitedCrashReports;
}

- (void)removeAnalyzerFile {
  if ([self.fileManager fileExistsAtPath:self.analyzerInProgressFile]) {
    NSError *error = nil;
    if(![self.fileManager removeItemAtPath:self.analyzerInProgressFile error:&error]) {
      AVALogError(@"[AVACrashes] ERROR: Couldn't remove analzer file at %@: ", self.analyzerInProgressFile);
    }
  }
}

- (void)createAnalyzerFile {
  if (![self.fileManager fileExistsAtPath:self.analyzerInProgressFile]) {
    [self.fileManager createFileAtPath:self.analyzerInProgressFile contents:nil attributes:nil];
  }
}

@end
