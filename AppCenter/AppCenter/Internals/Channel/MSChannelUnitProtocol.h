#import <Foundation/Foundation.h>

#import "MSChannelProtocol.h"
#import "MSChannelUnitConfiguration.h"
#import "MSLog.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^enqueueCompletionBlock)(BOOL);

/**
 * TODO add some comments
 */
@protocol MSChannelUnitProtocol <MSChannelProtocol>

/**
 * The configuration used by this channel.
 */
@property(nonatomic) MSChannelUnitConfiguration *configuration;

/**
 * Enqueues a new log item.
 *
 * @param item The log item that should be enqueued.
 */
- (void)enqueueItem:(id<MSLog>)item;

@end

NS_ASSUME_NONNULL_END
