#import <Foundation/Foundation.h>

@protocol MSLog;
@protocol MSChannelUnitProtocol;
@protocol MSChannelGroupProtocol;

@protocol MSChannelDelegate <NSObject>

@optional

/**
 * A callback that is called when a channel unit is added to the channel group.
 *
 * @param channelGroup The channel group.
 * @param channel The newly added channel.
 */
- (void)channelGroup:(id<MSChannelGroupProtocol>)channelGroup didAddChannelUnit:(id<MSChannelUnitProtocol>)channel;

/**
 * Callback method that will be called before each log will be send to the server.
 *
 * @param log The log to be sent.
 */
- (void)channel:(id<MSChannelUnitProtocol>)channel willSendLog:(id<MSLog>)log;

/**
 * Callback method that will be called in case the SDK was able to send a log.
 *
 * @param log The log to be sent.
 */
- (void)channel:(id<MSChannelUnitProtocol>)channel didSucceedSendingLog:(id<MSLog>)log;

/**
 * Callback method that will be called in case the SDK was unable to send a log.
 *
 * @param log The log to be sent.
 * @param error The error that occured.
 */
- (void)channel:(id<MSChannelUnitProtocol>)channel didFailSendingLog:(id<MSLog>)log withError:(NSError *)error;

/**
 * A callback that is called when a log has been enqueued, before a log has been forwarded to persistence, etc.
 *
 * @param channel The channel.
 * @param log The log.
 * @param internalId An internal Id that can be used to keep track of logs.
 */
- (void)channel:(id<MSChannelUnitProtocol>)channel didEnqueueLog:(id<MSLog>)log withInternalId:(NSString *)internalId;

/**
 * A callback that is called when setEnabled has been invoked.
 *
 * @param channel The channel.
 * @param isEnabled The boolean that indicates enabled.
 * @param deletedData The boolean that indicates deleting data on disabled.
 */
- (void)channel:(id<MSChannelUnitProtocol>)channel didSetEnabled:(BOOL)isEnabled andDeleteDataOnDisabled:(BOOL)deletedData;

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
 * Callback that is called when a log has been persisted successfully. This was introduced to implement the
 * log buffer for Crashes.
 *
 * @param log The log.
 * @param internalId An internal Id that can be used to keep track of logs.
 */
- (void)onFinishedPersistingLog:(id<MSLog>)log withInternalId:(NSString *)internalId;

/**
 * Callback that is called when persisting a log has failed, meaning it has not been saved to disk because the log was
 * empty. This was introduced to implement the log buffer for Crashes.
 *
 * @param log The log.
 * @param internalId An internal Id that can be used to keep track of logs.
 */
- (void)onFailedPersistingLog:(id<MSLog>)log withInternalId:(NSString *)internalId;

@end
