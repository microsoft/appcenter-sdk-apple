/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "../Model/SNMLog.h"
#import "SNMLogManagerListener.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Defines A log manager which triggers and manages the processing of log items on
 different channels.
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

/**
 *  Clear the persisted storage.
 */
- (void)clearStorage;

@end

NS_ASSUME_NONNULL_END
