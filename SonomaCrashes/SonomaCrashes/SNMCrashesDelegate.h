#import <Foundation/Foundation.h>

@class SNMErrorReport;
@class SNMCrashes;
@class SNMErrorAttachment;

@protocol SNMCrashesDelegate <NSObject>

@optional

/**
 * Callback method to check if the crash should be processed by the SDK.
 * @param crashes instance of SNMCrashes.
 * @param report object with error specific information. Use this to
 * determine if
 * the crash should be processed by the SDK.
 * @return YES if the SDK should process the crash, NO if you don't want it to
 * be sent to the server.
 */
- (BOOL)crashes:(SNMCrashes *)crashes shouldProcess:(SNMErrorReport *)report;

/**
 * Create an SNMErrorAttachment that will be attached to the error report.
 * @param crashes instance of SNMCrashes.
 * @param report The error report for the attachment.
 * @return instance of SNMErrorAttachment for custom data that the dev wants to
 * attach to the error.
 */
- (SNMErrorAttachment *)attachmentWithErrorReporting:(SNMCrashes *)crashes
                                      forErrorReport:(SNMErrorReport *)report;

/**
 * Callback method that will be called before each error will be send to the
 * server.
 * @param instance of SNMCrashes.
 */
- (void)crashesWillSend:(SNMCrashes *)crashes;

/**
 * Callback that will be called for each single error report if all retries have
 * been used and sending an error has failed.
 * @param crashes the instance of SNMCrashes.
 * @param report The error report that couldn't be send.
 * @param error The error object.
 */
- (void)crashes:(SNMCrashes *)crashes
        didFailSending:(SNMErrorReport *)report
             withError:(NSError *)error;

/**
 * Callback that will be called for each single error report as the report was
 * sent to the server successfully.
 * @param crashes the instance of SNMCrashes.
 * @param report The error report that was successfully sent.
 */
- (void)crashes:(SNMCrashes *)crashes didSucceedSending:(SNMErrorReport *)report;

@end
