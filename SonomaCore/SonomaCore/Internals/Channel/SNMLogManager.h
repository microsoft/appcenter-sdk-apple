/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "../Model/SNMLog.h"
#import "SNMEnable.h"
#import "SNMLogManagerListener.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Defines A log manager which triggers and manages the processing of log items on
 different channels.
 */
@protocol SNMLogManager <NSObject, SNMEnable>

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
 * @param item The log item that should be enqueued.
 * @param priority The priority for processing the log.
 */
- (void)processLog:(id<SNMLog>)log withPriority:(SNMPriority)priority;

/**
 *  Enable/disable this instance and delete data on disabled state.
 *
 *  @param isEnabled  A boolean value set to YES to enable the instance or NO to disable it.
 *  @param deleteData A boolean value set to YES to delete data or NO to keep it.
 *  @param forPriority A priority to enable/disable.
 */
- (void)setEnabled:(BOOL)isEnabled andDeleteDataOnDisabled:(BOOL)deleteData forPriority:(SNMPriority)priority;

/**
 * Send persisted logs that are not sent in previous session.
 *
 * param priority The priority for processing the log.
 */
- (void)flushPendingLogsForPriority:(SNMPriority)priority;

@end

NS_ASSUME_NONNULL_END
