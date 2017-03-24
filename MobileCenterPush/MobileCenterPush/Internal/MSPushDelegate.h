#import <Foundation/Foundation.h>

@class MSPush;
@class MSPushLog;

@protocol MSPushDelegate <NSObject>

@optional

/**
 * Callback method that will be called before each push log is sent to the server.
 *
 * @param push The instance of MSPush.
 * @param pushLog The push log that will be sent.
 */
- (void)push:(MSPush *)push willSendInstallationLog:(MSPushLog *)pushLog;

/**
 * Callback method that will be called in case the SDK was able to send an push log to the server. Use this method to
 * provide custom behavior.
 *
 * @param push The instance of MSPush.
 * @param pushLog The push log that Mobile Center sent.
 */
- (void)push:(MSPush *)push didSucceedSendingInstallationLog:(MSPushLog *)pushLog;

/**
 * Callback method that will be called in case the SDK was unable to send an event log to the server.
 *
 * @param push The instance of MSPush.
 * @param pushLog The event log that Mobile Center tried to send.
 * @param error The error that occurred.
 */
- (void)push:(MSPush *)push didFailSendingInstallLog:(MSPushLog *)pushLog withError:(NSError *)error;

@end
