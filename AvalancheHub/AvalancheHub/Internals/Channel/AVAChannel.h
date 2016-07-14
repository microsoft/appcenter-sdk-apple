/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVALog.h"
#import "AVASender.h"
#import "AVAStorage.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Defines a channel which manages a queue of log items.
 */
@protocol AVAChannel <NSObject>

/*
 * Threshold after which the queue will be flushed.
 *
 * Default: 50
 */
@property(nonatomic) NSUInteger batchSize;

/*
 * Interval for flushing the queue.
 *
 * Default: 15.0
 */
@property(nonatomic) float flushInterval;

/**
 * Timestamp of the last queued log
 */
@property(nonatomic) NSDate *lastQueuedLogTime;

@required

/**
 * Enqueues a new log item.
 *
 * param item The log item that should be enqueued
 */
- (void)enqueueItem:(id<AVALog>)item;

@end

NS_ASSUME_NONNULL_END
