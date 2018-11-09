#import <Foundation/Foundation.h>

#import "MSChannelProtocol.h"
#import "MSConstants+Flags.h"

NS_ASSUME_NONNULL_BEGIN

@class MSChannelUnitConfiguration;
@protocol MSLog;

/**
 * `MSChannelUnitProtocol` represents a kind of channel that is able to actually store/send logs (as opposed to a channel group, which
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
 * @param flags Options for the item being enqueued.
 */
- (void)enqueueItem:(id<MSLog>)item flags:(MSFlags)flags;

/**
 * Pause sending logs with the given transmission target token.
 *
 * @param token The transmission target token.
 *
 * @discussion The logs with the given token will continue to be persisted in the storage but they will only be sent once it resumes sending
 * logs.
 *
 * @see resumeSendingLogsWithToken:
 */
- (void)pauseSendingLogsWithToken:(NSString *)token;

/**
 * Resume sending logs with the given transmission target token.
 *
 * @param token The transmission target token.
 *
 * @see pauseSendingLogsWithToken:
 */
- (void)resumeSendingLogsWithToken:(NSString *)token;

@end

NS_ASSUME_NONNULL_END
