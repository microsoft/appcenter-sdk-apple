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

/**
 * Create a request based on data. Must override this method in sub classes.
 * @param data A data instance that will be transformed to request body.
 * @return A URL request.
 */
- (NSURLRequest *)createRequest:(NSObject *)data;

/**
 * Convert key/value pairs for headers to a string.
 * @param headers A dictionary that contains header as key/value pair.
 * @return A string that contains headers.
 */
- (NSString *)prettyPrintHeaders:(NSDictionary<NSString *, NSString *> *)headers;

@end
