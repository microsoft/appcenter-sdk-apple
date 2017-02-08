/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

#import "MSChannel.h"
#import "MSDeviceTracker.h"
#import "MSEnable.h"
#import "MSLogManagerDelegate.h"
#import "MSSender.h"
#import "MSStorage.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSLogManagerDefault ()

/**
 * Initializes a new `MSLogManager` instance.
 *
 * @param sender A sender instance that is used to send batches of log items to
 * the backend.
 * @param storage A storage instance to store and read enqueued log items.
 *
 * @return A new `MSLogManager` instance.
 */
- (instancetype)initWithSender:(id <MSSender>)sender storage:(id <MSStorage>)storage;

@end

NS_ASSUME_NONNULL_END
