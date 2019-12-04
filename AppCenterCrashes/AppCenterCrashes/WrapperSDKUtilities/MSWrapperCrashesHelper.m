// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSWrapperCrashesHelper.h"
#import "MSCrashesInternal.h"
#import "MSErrorReportPrivate.h"

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
  [[MSCrashes sharedInstance] setAutomaticProcessingEnabled:automaticProcessing];
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

/**
 * Track handled exception directly as model form with user-defined custom properties.
 * This API is used by wrapper SDKs.
 */
+ (NSString *)trackModelException:(MSException *)exception
                   withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties
                  withAttachments:(nullable NSArray<MSErrorAttachmentLog *> *)attachments {
  return [[MSCrashes sharedInstance] trackModelException:exception withProperties:properties withAttachments:attachments];
}

+ (MSErrorReport *)buildHandledErrorReportWithErrorID:(NSString *)errorID {
  return [[MSCrashes sharedInstance] buildHandledErrorReportWithErrorID:errorID];
}

@end
