#import "MSCrashesInternal.h"
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
    sharedInstance = [[MSWrapperCrashesHelper alloc] init];
  });
  return sharedInstance;
}

+ (void)setCrashHandlerSetupDelegate:(id<MSCrashHandlerSetupDelegate>)delegate {
  [[MSWrapperCrashesHelper sharedInstance] setCrashHandlerSetupDelegate:delegate];
}

+ (id<MSCrashHandlerSetupDelegate>)getCrashHandlerSetupDelegate {
  return [[MSWrapperCrashesHelper sharedInstance] crashHandlerSetupDelegate];
}

/**
 * Enables or disables automatic crash processing. Setting to 'NO'causes SDK not to send reports immediately, even if ALWAYS_SEND is set.
 */
+ (void)setAutomaticProcessing:(BOOL)automaticProcessing {
  [[MSCrashes sharedInstance] setAutomaticProcessing:automaticProcessing];
}

/**
 * Gets a list of unprocessed crash reports.
 */
+ (NSArray<MSErrorReport *> *)unprocessedCrashReports {
  return [[MSCrashes sharedInstance] unprocessedCrashReports];
}

/**
 * Resumes processing for a given subset of the unprocessed reports. Returns YES if should "AlwaysSend".
 */
+ (BOOL)sendCrashReportsOrAwaitUserConfirmationForFilteredIds:(NSArray<NSString *> *)filteredIds {
  return [[MSCrashes sharedInstance] sendCrashReportsOrAwaitUserConfirmationForFilteredIds:filteredIds];
}

/**
 * Sends error attachments for a particular error report.
 */
+ (void)sendErrorAttachments:(NSArray<MSErrorAttachmentLog *> *)errorAttachments withIncidentIdentifier:(NSString *)incidentIdentifier {
  [[MSCrashes sharedInstance] sendErrorAttachments:errorAttachments withIncidentIdentifier:incidentIdentifier];
}

@end
