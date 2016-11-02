/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@protocol SNMSenderDelegate;

@interface SNMHttpSender ()

@property(nonatomic, strong) NSURLSession *session;

/**
 * Retry intervals used by calls in case of recoverable errors.
 */
@property(nonatomic, strong) NSArray *callsRetryIntervals;

/**
 * Hash table containing all the delegates as weak references.
 */
@property(atomic, strong) NSHashTable<id<SNMSenderDelegate>> *delegates;

/**
 * A boolean value set to YES if the sender is enabled or NO otherwise.
 * Enable/disable does resume/suspend the sender as needed under the hood.
 */
@property(nonatomic) BOOL enabled;

@end
