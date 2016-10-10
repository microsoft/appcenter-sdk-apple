/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "../Model/SNMLog.h"
#import "SNMLogManagerDelegate.h"
#import <Foundation/Foundation.h>
@protocol SNMChannelDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
 Defines A log manager which triggers and manages the processing of log items on
 different channels.
 */
@protocol SNMLogManager <NSObject>

@optional
/**
 *  Add delegate.
 *
 *  @param delegate delegate.
 */
- (void)addDelegate:(id<SNMLogManagerDelegate>)delegate;

/**
 *  Remove delegate.
 *
 *  @param delegate delegate.
 */
- (void)removeDelegate:(id<SNMLogManagerDelegate>)delegate;

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
 * @param priority The priority for processing the log.
 */
- (void)flushPendingLogsForPriority:(SNMPriority)priority;

/**
 * Add a delegate to each channel that has a certain priority.
 *
 * @param delegate A delegate for the channel.
 * @param priority The priority of a channel.
 */
- (void)addChannelDelegate:(id<SNMChannelDelegate>)channelDelegate forPriority:(SNMPriority)priority;

/**
 * Remove a delegate to each channel that has a certain priority.
 *
 * @param delegate A delegate for the channel.
 * @param priority The priority of a channel.
 */
- (void)removeChannelDelegate:(id<SNMChannelDelegate>)channelDelegate forPriority:(SNMPriority)priority;

@end

NS_ASSUME_NONNULL_END
