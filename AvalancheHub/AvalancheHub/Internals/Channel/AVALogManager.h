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
@protocol AVALogManager <NSObject>

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

@required

/**
 *  Initializes a new `AVALogManager` instance.
 *
 *  @param sender a sender instance that is used to send batches of log items to
 * the backend
 *  @param storage a storage instance to store and read enqueued log items
 *
 *  @return the telemetry context
 */
- (instancetype)initWithSender:(id<AVASender>)sender
                       storage:(id<AVAStorage>)storage;

/**
 * Enqueues a new log item.
 *
 * param item The log item that should be enqueued
 */
- (void)enqueueItem:(id<AVALog>)item;

@end

NS_ASSUME_NONNULL_END
