#import <Foundation/Foundation.h>

@protocol MSLog;
@protocol MSChannelProtocol;

@protocol MSChannelDelegate <NSObject>

@optional

/**
 * Callback method that will be called before each log will be send to the server.
 *
 * @param channel The channel object.
 * @param log The log to be sent.
 */
- (void)channel:(id<MSChannelProtocol>)channel willSendLog:(id<MSLog>)log;

/**
 * Callback method that will be called in case the SDK was able to send a log.
 *
 * @param channel The channel object.
 * @param log The log to be sent.
 */
- (void)channel:(id<MSChannelProtocol>)channel didSucceedSendingLog:(id<MSLog>)log;

/**
 * Callback method that will be called in case the SDK was unable to send a log.
 *
 * @param channel The channel object.
 * @param log The log to be sent.
 * @param error The error that occured.
 */
- (void)channel:(id<MSChannelProtocol>)channel didFailSendingLog:(id<MSLog>)log withError:(NSError *)error;

/**
 * Callback method that will determine if a log should be filtered out from the
 * usual processing pipeline. If any delegate returns true, the log is filtered.
 *
 * @param log The log to be filtered or not.
 *
 * @return `true` if the log should be filtered out.
 */
- (BOOL)shouldFilterLog:(id<MSLog>)log;

/**
 * A callback that is called when a log has been enqueued. Used to specify additional info.
 *
 * @param log The log.
 */
- (void)prepareLog:(id<MSLog>)log;

@end
