#import <Foundation/Foundation.h>

@protocol MSLog;

@protocol MSChannelPersistDelegate <NSObject>

/**
 * A callback that is called when a log has been enqueued, before a log has been forwarded to persistence, etc.
 *
 * @param log The log.
 * @param internalId An internal Id that can be used to keep track of logs.
 */
- (void)willPersistLog:(id<MSLog>)log withInternalId:(NSString *)internalId;

/**
 * Callback that is called when persisting a log has completed.
 *
 * @param log The log.
 * @param internalId An internal Id that can be used to keep track of logs.
 */
- (void)completedEnqueuingLog:(id<MSLog>)log withInternalId:(NSString *)internalId withSuccess:(BOOL)success;

@end
