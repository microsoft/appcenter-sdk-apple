#import "MSCrashes.h"
#import "MSServiceInternal.h"

@class MSException;
@class MSErrorAttachmentLog;

@interface MSCrashes () <MSServiceInternal>

/**
 * A flag that indicates whether automatic processing is enabled.
 */
@property(nonatomic) BOOL automaticProcessing;

/**
 * Gets a list of unprocessed crash reports.
 */
- (NSArray<MSErrorReport *> *)getUnprocessedCrashReports;

/**
 * Resumes processing for a given subset of the unprocessed reports.
 */
- (void)sendCrashReportsOrAwaitUserConfirmationForFilteredIds:(NSArray<NSString *> *)filteredIds;

/**
 * Sends error attachments for a particular error report.
 */
- (void)sendErrorAttachments:(NSArray<MSErrorAttachmentLog *> *)errorAttachments withIncidentIdentifier:(NSString *)incidentIdentifier;

/**
 * Configure PLCrashreporter.
 *
 * @param enableUncaughtExceptionHandler Flag that indicates if PLCrashReporter should register an uncaught exception
 handler.
 *
 * @discussion The parameter that is passed in here should be `YES` for the "regular" iOS SDK. This property was
 * introduced to provide proper behavior in case the native iOS SDK was wrapped by the Xamarin SDK. You must not
 * register an UncaughtExceptionHandler for Xamarin as we rely on the xamarin runtime to report NSExceptions.
 * Registering our own UncaughtExceptionHandler will cause the Xamarin debugger to not work properly: The debugger will
 * not stop for NSExceptions and it's impossible to handle them in a C# try-catch block. On Xamarin runtime, if we don't
 * register our own exception handler, the Xamarin runtime will catch NSExceptions and re-throw them as .Net-exceptions
 * which can be handled and are then reported by Mobile Center Crashes properly. Just as a reminder: this doesn't mean
 * that we are not using PLCrashReporter to catch crashes, it just means that we disable its ability to catch
 * crashes caused by NSExceptions, only those for the reasons mentioned in this paragraph.
 */
- (void)configureCrashReporterWithUncaughtExceptionHandlerEnabled:(BOOL)enableUncaughtExceptionHandler;

/*
 * Track handled exception directly as model form.
 * This API is not public and is used by wrapper SDKs.
 */
- (void)trackModelException:(MSException *)exception;

@end
