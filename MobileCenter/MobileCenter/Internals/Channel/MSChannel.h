/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSChannelConfiguration.h"
#import "MSConstants+Internal.h"
#import "MSEnable.h"
#import "MSLog.h"
#import "MSSender.h"
#import "MSSenderDelegate.h"
#import "MSStorage.h"
@import Foundation;
@protocol MSChannelDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
 Defines a channel which manages a queue of log items.
 */
@protocol MSChannel <NSObject, MSSenderDelegate, MSEnable>

@required

/*
 * The configuration used by this channel.
 */
@property(nonatomic, strong) MSChannelConfiguration *configuration;

/**
 * Initializes a new `MSChannelDefault` instance.
 *
 * @param sender A sender instance that is used to send batches of log items to
 * the backend.
 * @param storage A storage instance to store and read enqueued log items.
 * @param configuration The configuration used by this channel.
 * @param logsDispatchQueue Queue used to process logs.
 *
 * @return A new `MSChannelDefault` instance.
 */
- (instancetype)initWithSender:(id<MSSender>)sender
                       storage:(id<MSStorage>)storage
                 configuration:(MSChannelConfiguration *)configuration
             logsDispatchQueue:(dispatch_queue_t)logsDispatchQueue;

/**
 * Enqueues a new log item.
 *
 * @param item The log item that should be enqueued.
 */
- (void)enqueueItem:(id<MSLog>)item;

/**
 * Delete all logs from storage.
 *
 * @param error Error describing why all logs are deleted.
 */
- (void)deleteAllLogsWithError:(NSError *)error;

/**
 *  Add delegate.
 *
 *  @param delegate delegate.
 */
- (void)addDelegate:(id<MSChannelDelegate>)delegate;

/**
 *  Remove delegate.
 *
 *  @param delegate delegate.
 */
- (void)removeDelegate:(id<MSChannelDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
