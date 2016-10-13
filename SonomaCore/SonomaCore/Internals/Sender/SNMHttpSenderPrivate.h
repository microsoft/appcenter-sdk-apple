/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@protocol SNMSenderDelegate;

@interface SNMHttpSender ()

@property(nonatomic, strong) NSURLSession *session;

/**
 * Hash table containing all the delegates as weak references.
 */
@property(atomic, strong) NSHashTable<id<SNMSenderDelegate>> *delegates;

/**
 * A boolean value set to YES if the sender is enabled or NO otherwise.
 * Enable/disable does resume/suspend the sender as needed under the hood.
 */
@property(nonatomic) BOOL enabled;

/**
 * A boolean value set to YES if the sender is suspended or NO otherwise.
 */
@property(nonatomic) BOOL suspended;

/**
 * Suspend the sender.
 * A sender is suspended when it becomes disabled or on network issues.
 * A suspended sender still persists logs but doesn't forward them to the sender.
 * A suspended state doesn't impact the current enabled state.
 * @see resume.
 */
- (void)suspend;

/**
 * Resume the sender.
 * @see suspend.
 */
- (void)resume;

@end
