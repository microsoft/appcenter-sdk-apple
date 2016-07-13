/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAChannel.h"
#import "AVALog.h"
#import "AVASender.h"
#import "AVAStorage.h"
#import "AVAConstants+Internal.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Defines a channel which manages a queue of log items.
 */
@protocol AVALogManager <NSObject>

@required

/**
 *  Initializes a new `AVALogManager` instance.
 *
 * @param sender a sender instance that is used to send batches of log items to
 * the backend
 * @param storage a storage instance to store and read enqueued log items
 * @param channels A list with channels, each representing a specific priority
 *
 *  @return the telemetry context
 */
- (instancetype)initWithSender:(id<AVASender>)sender
                       storage:(id<AVAStorage>)storage
                      channels:(NSArray<AVAChannel> *)channels;

/**
 * Triggers processing of a new log item.
 *
 * param item The log item that should be enqueued
 * param priority The priority for processing the log
 */
- (void)processLog:(id<AVALog>)log withPriority:(AVASendPriority)priority;

@end

NS_ASSUME_NONNULL_END
