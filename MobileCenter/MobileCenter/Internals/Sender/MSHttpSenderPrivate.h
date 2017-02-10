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
 * Retry intervals used by calls in case of recoverable errors.
 */
@property(nonatomic, strong) NSArray *callsRetryIntervals;

/**
 * Hash table containing all the delegates as weak references.
 */
@property(atomic, strong) NSHashTable<id<MSSenderDelegate>> *delegates;

/**
 * A boolean value set to YES if the sender is enabled or NO otherwise.
 * Enable/disable does resume/suspend the sender as needed under the hood.
 */
@property(nonatomic) BOOL enabled;

/**
 * Hide a secret replacing the N first characters by a hiding character.
 */
- (NSString *)hideSecret:(NSString *)secret;

// TODO (jaelim): Add doc here
- (NSURLRequest *)createRequest:(NSObject *)data;

// TODO (jaelim): Add doc here
- (NSString *)prettyPrintHeaders:(NSDictionary<NSString *, NSString *> *)headers;

@end
