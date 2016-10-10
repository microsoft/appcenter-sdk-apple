/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "../Model/SNMLog.h"
#import "SNMLogManagerDelegate.h"
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
- (void)addDelegate:(id<SNMLogManagerDelegate>)listener;

/**
 *  Remove listener.
 *
 *  @param listener listener.
 */
- (void)removeDelegate:(id<SNMLogManagerDelegate>)listener;

@required
/**
 * Triggers processing of a new log item.
 *
 * @param item The log item that should be enqueued.
 * @param priority The priority for processing the log.
 */
- (void)processLog:(id<SNMLog>)log withPriority:(SNMPriority)priority;

/**
 *  Delete logs from the storage for the given priority.
 *
 *  @param priority The priority related to the logs being deleted.
 */
- (void)deleteLogsForPriority:(SNMPriority)priority;

/**
 * Send persisted logs that are not sent in previous session.
 *
 * param priority The priority for processing the log.
 */
- (void)flushPendingLogsForPriority:(SNMPriority)priority;

@end

NS_ASSUME_NONNULL_END
