/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "../Model/MSLog.h"
#import "MSEnable.h"
#import "MSLogManagerDelegate.h"
#import <Foundation/Foundation.h>
@protocol MSChannelDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
 Defines A log manager which triggers and manages the processing of log items on
 different channels.
 */
@protocol MSLogManager <NSObject, MSEnable>

@optional
/**
 *  Add delegate.
 *
 *  @param delegate delegate.
 */
- (void)addDelegate:(id<MSLogManagerDelegate>)delegate;

/**
 *  Remove delegate.
 *
 *  @param delegate delegate.
 */
- (void)removeDelegate:(id<MSLogManagerDelegate>)delegate;

@required
/**
 * Triggers processing of a new log item.
 *
 * @param item The log item that should be enqueued.
 * @param priority The priority for processing the log.
 */
- (void)processLog:(id<MSLog>)log withPriority:(SNMPriority)priority;

/**
 *  Enable/disable this instance and delete data on disabled state.
 *
 *  @param isEnabled  A boolean value set to YES to enable the instance or NO to disable it.
 *  @param deleteData A boolean value set to YES to delete data or NO to keep it.
 *  @param forPriority A priority to enable/disable.
 */
- (void)setEnabled:(BOOL)isEnabled andDeleteDataOnDisabled:(BOOL)deleteData forPriority:(SNMPriority)priority;

/**
 * Add a delegate to each channel that has a certain priority.
 *
 * @param delegate A delegate for the channel.
 * @param priority The priority of a channel.
 */
- (void)addChannelDelegate:(id<MSChannelDelegate>)channelDelegate forPriority:(SNMPriority)priority;

/**
 * Remove a delegate to each channel that has a certain priority.
 *
 * @param delegate A delegate for the channel.
 * @param priority The priority of a channel.
 */
- (void)removeChannelDelegate:(id<MSChannelDelegate>)channelDelegate forPriority:(SNMPriority)priority;

@end

NS_ASSUME_NONNULL_END
