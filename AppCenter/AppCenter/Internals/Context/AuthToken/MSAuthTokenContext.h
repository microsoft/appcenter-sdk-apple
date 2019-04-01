// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MSUserInformation;
@protocol MSAuthTokenContextDelegate;

/**
 * MSAuthTokenContext is a singleton responsible for keeping an in-memory reference to an auth token that the Identity service provides.
 * This enables all App Center modules to access the token, and receive a notification when the token changes.
 */
@interface MSAuthTokenContext : NSObject

/**
 * Cached authorization token.
 */
@property(nullable, atomic, readonly) NSString *authToken;

/**
 * The last value of user information.
 */
@property(nonatomic, strong, readonly) MSUserInformation *homeUser;

/**
 * Get singleton instance.
 */
+ (instancetype)sharedInstance;

/**
 * Add delegate.
 *
 * @param delegate Delegate.
 */
- (void)addDelegate:(id<MSAuthTokenContextDelegate>)delegate;

/**
 * Remove delegate.
 *
 * @param delegate Delegate.
 */
- (void)removeDelegate:(id<MSAuthTokenContextDelegate>)delegate;

/**
 * Clear cached token and user information.
 *
 * @return `YES` if the auth token is cleared, `NO` otherwise.
 */
- (BOOL)clearAuthToken;

/**
 * Set current auth token and user information.
 */
- (void)setAuthToken:(NSString *)authToken withUserInformation:(MSUserInformation *)userInformation;

/**
 * Reset singleton instance.
 */
+ (void)resetSharedInstance;

@end

NS_ASSUME_NONNULL_END
