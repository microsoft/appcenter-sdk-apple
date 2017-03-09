#import "MSConstants+Internal.h"
#import <Foundation/Foundation.h>

@protocol MSLogManagerDelegate <NSObject>

@optional

/**
 *  On processing log callback.
 *
 *  @param log      log.
 *  @param internalId An internal Id that can be used to keep track of logs.
 *  @param priority priority.
 */
- (void)onProcessingLog:(id<MSLog>)log withInternalId:(NSString *)internalId andPriority:(MSPriority)priority;

/**
 * Callback that is called when a log has been processed, meaning it has been saved to disk. This was introduced to
 * implement the log buffer for Crashes.
 *
 *  @param log      log.
 *  @param internalId An internal Id that can be used to keep track of logs.
 *  @param priority priority.
 */
- (void)onFinishedProcessingLog:(id<MSLog>)log withInternalId:(NSString *)internalId andPriority:(MSPriority)priority;

/**
 * Callback that is called when a log has been processed, meaning it has been saved to disk. This was introduced to
 * implement the log buffer for Crashes.
 *
 *  @param log      log.
 *  @param internalId An internal Id that can be used to keep track of logs.
 *  @param priority priority.
 */
- (void)onFailedProcessingLog:(id<MSLog>)log withInternalId:(NSString *)internalId andPriority:(MSPriority)priority;


@end
