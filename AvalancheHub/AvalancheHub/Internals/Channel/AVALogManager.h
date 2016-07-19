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
 * Initializes a new `AVALogManager` instance.
 *
 * @param sender A sender instance that is used to send batches of log items to
 * the backend.
 * @param storage A storage instance to store and read enqueued log items.
 *
 * @return A new `AVALogManager` instance.
 */
- (instancetype)initWithSender:(id<AVASender>)sender
                       storage:(id<AVAStorage>)storage;

/**
 * Triggers processing of a new log item.
 *
 * param item The log item that should be enqueued.
 * param priority The priority for processing the log.
 */
- (void)processLog:(id<AVALog>)log withPriority:(AVAPriority)priority;

@end

NS_ASSUME_NONNULL_END
