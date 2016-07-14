/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

#import "AVAConstants+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@interface AVAChannelConfiguration : NSObject

/*
 * A readble name for this priority.
 */
@property(nonatomic, copy, readonly) NSString *name;

/*
 * Threshold after which the queue will be flushed.
 */
@property(nonatomic, readonly) NSUInteger batchSizeLimit;

/*
 * Maximum number of batches forwarded to the sender at the same time.
 */
@property(nonatomic, readonly) NSUInteger pendingBatchesLimit;

/*
 * Interval for flushing the queue.
 *
 * Default: 15.0
 */
@property(nonatomic, readonly) float flushInterval;

/**
 * Initializes new `AVAChannelConfiguration' instance based on given settings.
 *
 * @param name the name used by the channel to determine the subdirectory for
 * persisting new logs
 * @param flushInterval the interval after which a new batch will be forwarded
 * to the sender component
 * @param batchSizeLimit the maximum number of logs after which a new batch will
 * be forwarded to the sender component
 * @param pendingBatchesLimit the maximum number of batches that have currently
 * been forwarded to the sender component
 *
 * @return a fully configured `AVAChannelConfiguration` instance
 */
- (id)initWithPriorityName:(NSString *)name
             flushInterval:(float)flushInterval
            batchSizeLimit:(NSUInteger)batchSizeLimit
       pendingBatchesLimit:(NSUInteger)pendingBatchesLimit;

/**
 * Initializes and configures a predefined `AVAChannelConfiguration' instance
 * based on
 * a given priority enum value.
 *
 * @param priority the enum value which determines which configurations to us
 * as presets.
 *
 * @return a fully configured `AVAChannelConfiguration` instance
 */
+ (instancetype)configurationForPriority:(AVAPriority)priority;

@end

NS_ASSUME_NONNULL_END