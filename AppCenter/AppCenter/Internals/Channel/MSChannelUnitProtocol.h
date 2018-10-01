#import <Foundation/Foundation.h>

#import "MSChannelProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class MSChannelUnitConfiguration;
@protocol MSLog;

/**
 * `MSChannelUnitProtocol` represents a kind of channel that is able
 * to actually store/send logs (as opposed to a channel group, which
 * simply contains a collection of channel units).
 */
@protocol MSChannelUnitProtocol <MSChannelProtocol>

/**
 * The configuration used by this channel unit.
 */
@property(nonatomic) MSChannelUnitConfiguration *configuration;

/**
 * Queue used to process logs.
 */
@property(nonatomic) dispatch_queue_t logsDispatchQueue;

/**
 * Enqueue a new log item.
 *
 * @param item The log item that should be enqueued.
 */
- (void)enqueueItem:(id<MSLog>)item;

@end

NS_ASSUME_NONNULL_END
