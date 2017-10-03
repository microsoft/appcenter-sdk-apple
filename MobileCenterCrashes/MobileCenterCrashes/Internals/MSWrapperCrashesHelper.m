#import "MSWrapperCrashesHelper.h"

@interface MSWrapperCrashesHelper ()

@property(weak, nonatomic) id<MSCrashHandlerSetupDelegate> crashHandlerSetupDelegate;

@end

@implementation MSWrapperCrashesHelper

/**
 * Gets the singleton instance.
 */
+ (instancetype)sharedInstance {
  static MSWrapperCrashesHelper *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

+ (void)setCrashHandlerSetupDelegate:(id<MSCrashHandlerSetupDelegate>)delegate {
  [[self sharedInstance] setCrashHandlerSetupDelegate:delegate];
}

+ (id<MSCrashHandlerSetupDelegate>)getCrashHandlerSetupDelegate {
  return [[self sharedInstance] crashHandlerSetupDelegate];
}

/**
 * Disables automatic crash processing. Causes SDK not to send reports, even if ALWAYS_SEND is set.
 */
+ (void)setAutomaticProcessing:(BOOL)automaticProcessing {
  [[MSCrashes sharedInstance] setAutomaticProcessing:automaticProcessing];
}

/**
 * Gets a list of unprocessed crash reports.
 */
+ (NSArray<MSErrorReport *> *)getUnprocessedCrashReports {
  return [[MSCrashes sharedInstance] getUnprocessedCrashReports];
}

/**
 * Resumes processing for a list of error reports that is a subset of the unprocessed reports.
 */
+ (void)sendCrashReportsOrAwaitUserConfirmationForFilteredList:(NSArray<MSErrorReport *> *)filteredList {
  [[MSCrashes sharedInstance] sendCrashReportsOrAwaitUserConfirmationForFilteredList:filteredList];
}

/**
 * Sends error attachments for a particular error report.
 */
+ (void)sendErrorAttachments:(NSArray<MSErrorAttachmentLog *> *)errorAttachments forErrorReport:(MSErrorReport *)errorReport {
  [[MSCrashes sharedInstance] sendErrorAttachments:errorAttachments forErrorReport:errorReport];
}

@end
