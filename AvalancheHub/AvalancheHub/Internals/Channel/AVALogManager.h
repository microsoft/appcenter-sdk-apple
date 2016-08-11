/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "../Model/AVALog.h"
#import "AVALogManagerListener.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Defines a channel which manages a queue of log items.
 */
@protocol AVALogManager <NSObject>

@optional
/**
 *  Add listener.
 *
 *  @param listener listener.
 */
- (void)addListener:(id <AVALogManagerListener>)listener;

/**
 *  Remove listener.
 *
 *  @param listener listener.
 */
- (void)removeListener:(id <AVALogManagerListener>)listener;

@required
/**
 * Triggers processing of a new log item.
 *
 * param item The log item that should be enqueued.
 * param priority The priority for processing the log.
 */
- (void)processLog:(id<AVALog>)log withPriority:(AVAPriority)priority;

@end

NS_ASSUME_NONNULL_END
