/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "../Model/SNMLog.h"
#import "SNMLogManagerListener.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Defines a channel which manages a queue of log items.
 */
@protocol SNMLogManager <NSObject>

@optional
/**
 *  Add listener.
 *
 *  @param listener listener.
 */
- (void)addListener:(id<SNMLogManagerListener>)listener;

/**
 *  Remove listener.
 *
 *  @param listener listener.
 */
- (void)removeListener:(id<SNMLogManagerListener>)listener;

@required
/**
 * Triggers processing of a new log item.
 *
 * param item The log item that should be enqueued.
 * param priority The priority for processing the log.
 */
- (void)processLog:(id<SNMLog>)log withPriority:(SNMPriority)priority;

@end

NS_ASSUME_NONNULL_END
