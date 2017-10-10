#import <Foundation/Foundation.h>
#import "MSCrashHandlerSetupDelegate.h"

@class MSErrorReport;
@class MSErrorAttachmentLog;

/**
 * This general class allows wrappers to supplement the Crashes SDK with their own
 * behavior.
 */
@interface MSWrapperCrashesHelper : NSObject

/**
 * Sets the crash handler setup delegate.
 */
+ (void)setCrashHandlerSetupDelegate:(id<MSCrashHandlerSetupDelegate>)delegate;

/**
 * Gets the crash handler setup delegate.
 */
+ (id<MSCrashHandlerSetupDelegate>)getCrashHandlerSetupDelegate;

/**
 * Disables automatic crash processing. Causes SDK not to send reports, even if ALWAYS_SEND is set.
 */
+ (void)setAutomaticProcessing:(BOOL)automaticProcessing;

/**
 * Gets a list of unprocessed crash reports.
 */
+ (NSArray<MSErrorReport *> *)getUnprocessedCrashReports;

/**
 * Resumes processing for a given subset of the unprocessed reports. Returns YES if should "AlwaysSend".
 */
+ (BOOL)sendCrashReportsOrAwaitUserConfirmationForFilteredIds:(NSArray<NSString *> *)filteredIds;

/**
 * Sends error attachments for a particular error report.
 */
+ (void)sendErrorAttachments:(NSArray<MSErrorAttachmentLog *> *)errorAttachments withIncidentIdentifier:(NSString *)incidentIdentifier;

@end
