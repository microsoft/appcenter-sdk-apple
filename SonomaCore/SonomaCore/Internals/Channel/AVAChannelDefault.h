/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

#import "AVAChannel.h"
#import "AVAChannelConfiguration.h"
#import "AVASender.h"
#import "AVAStorage.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^enqueueCompletionBlock)(BOOL);

@interface AVAChannelDefault : NSObject <AVAChannel>

/**
 * A queue on which the handler is called on.
 */
@property(nonatomic, strong) dispatch_queue_t callbackQueue;

/**
 * A sender instance that is used to send batches of log items to the backend.
 */
@property(nonatomic, strong, nullable) id<AVASender> sender;

/**
 * A storage instance to store and read enqueued log items.
 */
@property(nonatomic, strong, nullable) id<AVAStorage> storage;

/**
 * A timer source which is used to flush the queue after a certain amount of
 * time.
 */
@property(nonatomic, strong, nullable) dispatch_source_t timerSource;

/**
 * A counter that keeps tracks of the number of logs added to the queue.
 */
@property(nonatomic, assign) NSUInteger itemsCount;

/**
 *  A list used to keep track of batches that have been forwarded to the sender component.
 */
@property(nonatomic, copy) NSMutableArray *pendingLogsIds;

/**
 * Enqueues a new log item.
 *
 * @param item The log item that should be enqueued.
 * @param completion A completion block that gets called after the item was
 * enqueued.
 */
- (void)enqueueItem:(id<AVALog>)item withCompletion:(nullable enqueueCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END