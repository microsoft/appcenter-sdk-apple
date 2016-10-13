/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

#import "SNMChannel.h"
#import "SNMChannelConfiguration.h"
#import "SNMSender.h"
#import "SNMStorage.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^enqueueCompletionBlock)(BOOL);

@interface SNMChannelDefault : NSObject <SNMChannel>

/**
 * A queue on which the handler is called on.
 */
@property(nonatomic, strong) dispatch_queue_t callbackQueue;

/**
 *  Array of channel delegate.
 */
@property(nonatomic) NSMutableArray<id<SNMChannelDelegate>> *delegates;
/**
 * A sender instance that is used to send batches of log items to the backend.
 */
@property(nonatomic, strong, nullable) id<SNMSender> sender;

/**
 * A storage instance to store and read enqueued log items.
 */
@property(nonatomic, strong, nullable) id<SNMStorage> storage;

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
 * A list used to keep track of batches that have been forwarded to the sender component.
 */
@property(nonatomic, copy) NSMutableArray *pendingBatchIds;

/**
 * A boolean value set to YES if there is at least one available batch from the storage.
 */
@property(nonatomic) BOOL availableBatchFromStorage;

/**
 * A boolean value set to YES if the pending batch queue is full.
 */
@property(nonatomic) BOOL pendingBatchQueueFull;

/**
 * Enqueues a new log item.
 *
 * @param item The log item that should be enqueued.
 * @param completion A completion block that gets called after the item was
 * enqueued.
 */
- (void)enqueueItem:(id<SNMLog>)item withCompletion:(nullable enqueueCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
