#import <Foundation/Foundation.h>

@class SNMErrorReport;
@class SNMCrashes;
@class SNMErrorAttachment;

@protocol SNMCrashesDelegate <NSObject>

@optional

/**
 * Callback method to check if the crash should be processed by the SDK.
 * @param errorReporting instance of SNMCrashes.
 * @param errorReport object with error specific information. Use this to
 * determine if
 * the crash should be processed by the SDK.
 * @return YES if the SDK should process the crash, NO if you don't want it to
 * be sent to the server.
 */
- (BOOL)errorReporting:(SNMCrashes *)errorReporting shouldProcess:(SNMErrorReport *)errorReport;

/**
 * Create an SNMErrorAttachment that will be attached to the error report.
 * @param errorReporting instance of SNMCrashes.
 * @param errorReport The error report for the attachment.
 * @return instance of SNMErrorAttachment for custom data that the dev wants to
 * attach to the error.
 */
- (SNMErrorAttachment *)attachmentWithErrorReporting:(SNMCrashes *)errorReporting
                                      forErrorReport:(SNMErrorReport *)errorReport;

/**
 * Callback method that will be called before each error will be send to the
 * server.
 * @param instance of SNMCrashes.
 */
- (void)errorReportingWillSend:(SNMCrashes *)errorReporting;

/**
 * Callback that will be called for each single error report if all retries have
 * been used and sending an error has failed.
 * @param errorReporting the instance of SNMCrashes.
 * @param errorReport The error report that couldn't be send.
 * @param error The error object.
 */
- (void)errorReporting:(SNMCrashes *)errorReporting
        didFailSending:(SNMErrorReport *)errorReport
             withError:(NSError *)error;

/**
 * Callback that will be called for each single error report as the report was
 * sent to the server successfully.
 * @param errorReporting the instance of SNMCrashes.
 * @param errorReport The error report that was successfully sent.
 */
- (void)errorReporting:(SNMCrashes *)errorReporting didSucceedSending:(SNMErrorReport *)errorReport;

@end
