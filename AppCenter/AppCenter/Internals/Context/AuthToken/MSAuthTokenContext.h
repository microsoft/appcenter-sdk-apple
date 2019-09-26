// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MSAuthTokenContextDelegate;
@class MSAuthTokenValidityInfo;

/**
 * MSAuthTokenContext is a singleton responsible for keeping an in-memory reference to an auth token and token history.
 * This enables all App Center modules to access the token, token history, and receive a notification when the token changes or needs to be
 * refreshed.
 */
@interface MSAuthTokenContext : NSObject

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
 * Set current auth token and account id.
 *
 * @param authToken token to be added to the storage.
 * @param accountId account id to be added to the storage.
 * @param expiresOn expiration date of a token.
 */
- (void)setAuthToken:(nullable NSString *)authToken withAccountId:(nullable NSString *)accountId expiresOn:(nullable NSDate *)expiresOn;

/**
 * Returns current auth token.
 *
 * @return auth token.
 */
- (nullable NSString *)authToken;

/**
 * Returns current account identifier.
 *
 * @return account identifier.
 */
- (nullable NSString *)accountId;

/**
 * Returns array of auth tokens validity info.
 *
 * @return Array of MSAuthTokenValidityInfo.
 */
- (NSArray<MSAuthTokenValidityInfo *> *)authTokenValidityArray;

/**
 * Removes the token from history. Please note that only oldest token is
 * allowed to be removed. To reset current token to be anonymous, use
 * the setToken method with nil parameters instead.
 *
 * @param authToken Auth token to be removed. Despite the fact that only the oldest token can be removed, it's required to avoid removing
 * the wrong one on duplicated calls etc.
 */
- (void)removeAuthToken:(nullable NSString *)authToken;

/**
 * Checks if the given token is the last, soon expires and needs to be refreshed, sends refresh event if needed.
 *
 * @param tokenValidityInfo token validity object to be checked.
 */
- (void)checkIfTokenNeedsToBeRefreshed:(MSAuthTokenValidityInfo *)tokenValidityInfo;

/**
 * Finishes initialization process. Resets current token if nothing prevents it.
 */
- (void)finishInitialize;

/**
 * Prevents resetting the current auth token if it exists. Should be called during
 * initialization process if the current auth token should be kept.
 */
- (void)preventResetAuthTokenAfterStart;

/**
 * Manually forces the last refresh token to be nil. This will effectively force refresh on the next attempt.
 */
- (void)clearLastRefreshedCache;

@end

NS_ASSUME_NONNULL_END
