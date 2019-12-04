// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSHttpClient.h"

@class MS_Reachability;
@protocol MSHttpClientDelegate;

@interface MSHttpClient ()

/**
 * The HTTP session object.
 */
@property(nonatomic) NSURLSession *session;

/**
 * Reachability library object, which listens for changes in the network state.
 */
@property(nonatomic) MS_Reachability *reachability;

/**
 * Pending http calls.
 */
@property(nonatomic) NSMutableSet *pendingCalls;

/**
 * A boolean value set to YES if the client is paused or NO otherwise. While paused, the client will store new calls but not send them until
 * resumed.
 */
@property(nonatomic, getter=isPaused) BOOL paused;

/**
 * A boolean value set to YES if the client is enabled or NO otherwise. While disabled, the client will not store any calls.
 */
@property(nonatomic, getter=isEnabled) BOOL enabled;

/**
 * Configuration object for the NSURLSession. Need to store this because the session will need to be re-created after re-enabling the
 * client.
 */
@property(nonatomic) NSURLSessionConfiguration *sessionConfiguration;

/**
 * Hash table containing all the delegates as weak references.
 */
@property NSHashTable<id<MSHttpClientDelegate>> *delegates;

/**
 * Disables the client, deletes data, and cancels any calls.
 *
 * @param isEnabled Whether to enable or disable the client.
 * @param deleteData Whether to delete data on disabled.
 */
- (void)setEnabled:(BOOL)isEnabled andDeleteDataOnDisabled:(BOOL)deleteData;

@end
