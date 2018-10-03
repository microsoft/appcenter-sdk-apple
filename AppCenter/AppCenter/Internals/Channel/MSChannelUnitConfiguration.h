#import <Foundation/Foundation.h>

#import "MSConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSChannelUnitConfiguration : NSObject

/**
 * The groupId that will be used for storage by this channel.
 */
@property(nonatomic, copy, readonly) NSString *groupId;

/**
 * The priority of logs for this channel
 */
@property(nonatomic, assign, readonly) MSPriority priority;

/**
 * Threshold after which the queue will be flushed.
 */
@property(nonatomic, readonly) NSUInteger batchSizeLimit;

/**
 * Maximum number of batches forwarded to the ingestion at the same time.
 */
@property(nonatomic, readonly) NSUInteger pendingBatchesLimit;

/**
 * Interval for flushing the queue.
 */
@property(nonatomic, readonly) float flushInterval;

/**
 * Initializes a new instance based on given settings.
 *
 * @param groupId The id used by the channel to determine a group of logs.
 * @param priority The priority of logs being sent by the channel.
 * @param flushInterval The interval after which a new batch will be finished.
 * @param batchSizeLimit The maximum number of logs after which a new batch will be finished.
 * @param pendingBatchesLimit The maximum number of batches that have currently been forwarded to another component.
 *
 * @return a fully configured `MSChannelUnitConfiguration` instance.
 */
- (instancetype)initWithGroupId:(NSString *)groupId
                       priority:(MSPriority)priority
                  flushInterval:(float)flushInterval
                 batchSizeLimit:(NSUInteger)batchSizeLimit
            pendingBatchesLimit:(NSUInteger)pendingBatchesLimit;

/**
 * Initializes a new instance with default settings.
 *
 * @param groupId The id used by the channel to determine a group of logs.
 *
 * @return a fully configured `MSChannelConfiguration` instance with default settings.
 */
- (instancetype)initDefaultConfigurationWithGroupId:(NSString *)groupId;

@end

NS_ASSUME_NONNULL_END
