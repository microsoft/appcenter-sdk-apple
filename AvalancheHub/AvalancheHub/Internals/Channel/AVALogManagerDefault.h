/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

#import "AVALogManager.h"
#import "AVASender.h"
#import "AVAStorage.h"
#import "AVAChannel.h"

NS_ASSUME_NONNULL_BEGIN

/**
 A log manager which triggeres and manages the processing of log items on
 different channels. All items will be immediately passed to the persistence
 layer in order to make the queue crash safe. Once a maximum number of items
 have been enqueued or the internal timer finished running, events will be
 forwarded to the sender. Furthermore, its responsibility is to tell the
 persitence layer what to do with a pending batch based on the status code
 returned by the sender
 */
@interface AVALogManagerDefault : NSObject <AVALogManager>

/**
 *  A queue which makes adding new items thread safe.
 */
@property(nonatomic, strong) dispatch_queue_t dataItemsOperations;

/**
 * A dictionary containing priority keys and their channel.
 */
@property(nonatomic, strong) NSDictionary<NSNumber *, id<AVAChannel>> *channels;

@end

NS_ASSUME_NONNULL_END
