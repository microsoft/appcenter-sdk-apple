// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MSAuthTokenStorage;
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
 * Cached home account identifier.
 */
@property(nullable, atomic, readonly) NSString *accountId;

/**
 * Instance of object responsible for storing auth data to settings and keychain.
 */
@property(nullable) id<MSAuthTokenStorage> storage;

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
 * Clear cached token and account id.
 *
 * @return `YES` if the auth token is cleared, `NO` otherwise.
 */
- (BOOL)clearAuthToken;

/**
 * Set current auth token and account id.
 *
 * @param authToken token to be added to the storage.
 * @param accountId account id to be added to the storage.
 * @param expiresOn expiration date of a token.
 */
- (void)setAuthToken:(nullable NSString *)authToken withAccountId:(nullable NSString *)accountId expiresOn:(nullable NSDate *)expiresOn;

/**
 * Cache auth token and account data to be used later on.
 */
- (void)cacheAuthToken;

/**
 * Reset singleton instance.
 */
+ (void)resetSharedInstance;

@end

NS_ASSUME_NONNULL_END
