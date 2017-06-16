#import <Foundation/Foundation.h>

#import "MSConstants+Internal.h"
#import "MSLog.h"

// TODO: We need to pass a sender instance in delegate methods or changing method name with a prefix of sender.
@protocol MSLogManagerDelegate <NSObject>

@optional

/**
 * A callback that is called when a log has been enqueued, before a log has been forwarded to persistence, etc.
 *
 * @param log The log.
 * @param internalId An internal Id that can be used to keep track of logs.
 */
- (void)onEnqueuingLog:(id<MSLog>)log withInternalId:(NSString *)internalId;

/**
 * Callback that is called when a log has been persisted successfully. This was introduced to implement the
 * log buffer for Crashes.
 *
 * @param log The log.
 * @param internalId An internal Id that can be used to keep track of logs.
 *
 * @discussion We had some discussion about the naming of the method. To match the
 * onEnqueueingLog:withInternalId (@see onEnqueueingLog:withInternalId) callback, it should
 * also use `enqueuing` in it's signature, yet, as of now, it indicates successful persistence of a log. This
 * method's name might change in the future to make a distinction between a successfully enqueued log and a persisted
 * log.
 */
- (void)onFinishedPersistingLog:(id<MSLog>)log withInternalId:(NSString *)internalId;

/**
 * Callback that is called when persisting a log has failed, meaning it has not been saved to disk because the log was
 * empty. This was introduced to implement the log buffer for Crashes.
 *
 * @param log The log.
 * @param internalId An internal Id that can be used to keep track of logs.
 *
 * @discussion We had some discussion about the naming of the method. To match the
 * onEnqueueingLog:withInternalId (@see onEnqueueingLog:withInternalId) callback, it should
 * also use `enqueuing` in it's signature, yet, as of now, it indicates successful persistence of a log. This
 * method's name might change in the future to make a distinction between a successfully enqueued log and a persisted
 * log.
 */
- (void)onFailedPersistingLog:(id<MSLog>)log withInternalId:(NSString *)internalId;

/**
 * Callback method that will be called before each log will be sent to the server.
 *
 * @param log The log to be sent.
 */
- (void)willSendLog:(id<MSLog>)log;

/**
 * Callback method that will be called in case the SDK was able to send a log.
 *
 * @param log The log to be sent.
 */
- (void)didSucceedSendingLog:(id<MSLog>)log;

/**
 * Callback method that will be called in case the SDK was unable to send a log.
 *
 * @param log The log to be sent.
 * @param error The error that occured.
 */
- (void)didFailSendingLog:(id<MSLog>)log withError:(NSError *)error;

/**
 * Get service unique key for storage purpose.
 *
 * @return A group ID of the service.
 */
- (NSString *)groupId;

@end
