#import <Foundation/Foundation.h>

#import "MSChannelProtocol.h"

@class MSLog;
typedef void (^enqueueCompletionBlock)(BOOL);

/**
 * TODO add some comments
 */
@protocol MSChannelUnitProtocol <MSChannelProtocol>

/**
 * Enqueues a new log item.
 *
 * @param item The log item that should be enqueued.
 * @param completion A completion block that gets called after the item was enqueued.
 */
- (void)enqueueItem:(id<MSLog>)item withCompletion:(nullable enqueueCompletionBlock)completion;

/**
 * Get a unique identifier for processing logs.
 *
 * @return A group ID for the logs.
 */
- (NSString *)groupId;


//TODO needed?
/**
 * Delete all logs from storage.
 *
 * @param error Error describing why all logs are deleted.
 */
- (void)deleteAllLogsWithError:(NSError *)error;

@end
