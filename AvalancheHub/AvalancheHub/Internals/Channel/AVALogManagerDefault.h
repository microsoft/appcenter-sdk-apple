/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

#import "AVADeviceTracker.h"
#import "AVAChannel.h"
#import "AVALogManager.h"
#import "AVASender.h"
#import "AVAStorage.h"
#import "AVALogManagerListener.h"

NS_ASSUME_NONNULL_BEGIN

/**
 A log manager which triggers and manages the processing of log items on
 different channels. All items will be immediately passed to the persistence
 layer in order to make the queue crash safe. Once a maximum number of items
 have been enqueued or the internal timer finished running, events will be
 forwarded to the sender. Furthermore, its responsibility is to tell the
 persistence layer what to do with a pending batch based on the status code
 returned by the sender
 */
@interface AVALogManagerDefault : NSObject <AVALogManager>

/**
 * Initializes a new `AVALogManager` instance.
 *
 * @param sender A sender instance that is used to send batches of log items to
 * the backend.
 * @param storage A storage instance to store and read enqueued log items.
 *
 * @return A new `AVALogManager` instance.
 */
- (instancetype)initWithSender:(id<AVASender>)sender storage:(id<AVAStorage>)storage;

/**
 *  Array of log manager listeners.
 */
@property (nonatomic) NSMutableArray<id<AVALogManagerListener>>* listeners;

/**
 *  A sender instance that is used to send batches of log items to the backend.
 */
@property(nonatomic, strong, nullable) id<AVASender> sender;

/**
 *  A storage instance to store and read enqueued log items.
 */
@property(nonatomic, strong, nullable) id<AVAStorage> storage;

/**
 *  A queue which makes adding new items thread safe.
 */
@property(nonatomic, strong) dispatch_queue_t dataItemsOperations;

/**
 * A dictionary containing priority keys and their channel.
 */
@property(nonatomic, copy) NSMutableDictionary<NSNumber *, id<AVAChannel>> *channels;

/**
 *  Device tracker provides device information.
 */
@property(nonatomic) AVADeviceTracker *deviceTracker;

@end

NS_ASSUME_NONNULL_END
