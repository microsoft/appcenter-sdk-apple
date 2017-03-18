#import <Foundation/Foundation.h>

#import "MSConstants+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSChannelConfiguration : NSObject

/**
 * The groupID that will be used for storage by this channel configuration.
 */
@property(nonatomic, copy, readonly) NSString *groupID;

/**
 * Threshold after which the queue will be flushed.
 */
@property(nonatomic, readonly) NSUInteger batchSizeLimit;

/**
 * Maximum number of batches forwarded to the sender at the same time.
 */
@property(nonatomic, readonly) NSUInteger pendingBatchesLimit;

/**
 * Interval for flushing the queue.
 *
 * Default: 15.0
 */
@property(nonatomic, readonly) float flushInterval;

/**
 * Initializes new `MSChannelConfiguration' instance based on given settings.
 *
 * @param groupID The id used by the channel to determine a group of logs.
 * @param flushInterval The interval after which a new batch will be finished.
 * @param batchSizeLimit The maximum number of logs after which a new batch will be finished.
 * @param pendingBatchesLimit The maximum number of batches that have currently been forwarded to another component.
 *
 * @return a fully configured `MSChannelConfiguration` instance.
 */
- (instancetype)initWithGroupID:(NSString *)groupID
                  flushInterval:(float)flushInterval
                 batchSizeLimit:(NSUInteger)batchSizeLimit
            pendingBatchesLimit:(NSUInteger)pendingBatchesLimit;

/**
 * Initializes and configures a predefined `MSChannelConfiguration' instance based on a given priority enum value.
 *
 * @param priority the enum value which determines which configurations to us as presets.
 * @param groupID The groupID that will be used to determine a group of logs.
 *
 * @return a fully configured `MSChannelConfiguration` instance.
 */
+ (instancetype)configurationForPriority:(MSPriority)priority groupID:(NSString *)groupID;

@end

NS_ASSUME_NONNULL_END
