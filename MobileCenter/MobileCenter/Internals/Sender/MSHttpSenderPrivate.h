/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

static short const kMSMaxCharactersDisplayedForAppSecret = 8;
static NSString *const kMSHidingStringForAppSecret = @"*";

@protocol MSSenderDelegate;

@interface MSHttpSender ()

@property(nonatomic, strong) NSURLSession *session;

/**
 * Hash table containing all the delegates as weak references.
 */
@property(atomic, strong) NSHashTable<id <MSSenderDelegate>> *delegates;

/**
 * A boolean value set to YES if the sender is enabled or NO otherwise.
 * Enable/disable does resume/suspend the sender as needed under the hood.
 */
@property(nonatomic) BOOL enabled;

/**
 * Hide a secret replacing the N first characters by a hiding character.
 */
- (NSString *)hideSecret:(NSString *)secret;

/**
 * Retry intervals used by calls in case of recoverable errors.
 *
 * @return A list of retry intervals.
 */
- (NSArray *)retryIntervals;

/**
 * An API path in the URL that is used to talk to HTTP endpoint.
 *
 * @return An API path string.
 */
- (NSString *)apiPath;

@end
