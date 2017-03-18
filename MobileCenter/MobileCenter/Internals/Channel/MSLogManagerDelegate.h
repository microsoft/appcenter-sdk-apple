 
                                                                   
                                                                 
    
#import "MSConstants+Internal.h"
#import <Foundation/Foundation.h>

@protocol MSLogManagerDelegate <NSObject>

@optional

/**
 *  A callback that is called when a log has been enqueued, before a log has been forwarded to persistence, etc.
 *
 *  @param log The log.
 *  @param internalId An internal Id that can be used to keep track of logs.
 *  @param priority priority.
 */
- (void)onEnqueuingLog:(id<MSLog>)log withInternalId:(NSString *)internalId andPriority:(MSPriority)priority;

/**
 * Callback that is called when a log has been persisted successfully. This was introduced to implement the
 * log buffer for Crashes.
 *
 *  @param log The log.
 *  @param internalId An internal Id that can be used to keep track of logs.
 *  @param priority The log's priority.
 *
 *  @discussion We had some discussion about the naming of the method. To match the
 *  onEnqueueingLog:withInternalId:andPriority (@see onEnqueueingLog:withInternalId:andPriority) callback, it should
 *  also use `enqueuing` in it's signature, yet, as of now, it indicates successful persistence of a log. This
 *  method's name might change in the future to make a distinction between a successfully enqueued log and a persisted
 *  log.
 */
- (void)onFinishedPersistingLog:(id<MSLog>)log withInternalId:(NSString *)internalId andPriority:(MSPriority)priority;

/**
 *  Callback that is called when persisting a log has failed, meaning it has not been saved to disk because the log was
 *  empty. This was introduced to implement the log buffer for Crashes.
 *
 *  @param log The log.
 *  @param internalId An internal Id that can be used to keep track of logs.
 *  @param priority priority.
 *
 *  @discussion We had some discussion about the naming of the method. To match the
 *  onEnqueueingLog:withInternalId:andPriority (@see onEnqueueingLog:withInternalId:andPriority) callback, it should
 *  also use `enqueuing` in it's signature, yet, as of now, it indicates successful persistence of a log. This
 *  method's name might change in the future to make a distinction between a successfully enqueued log and a persisted
 *  log.
 */
- (void)onFailedPersistingLog:(id<MSLog>)log withInternalId:(NSString *)internalId andPriority:(MSPriority)priority;

@end
