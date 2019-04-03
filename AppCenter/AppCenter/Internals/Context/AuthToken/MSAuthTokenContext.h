// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAppCenterInternal.h"
#import "MSAuthTokenContextDelegate.h"
#import "MSAuthTokenInfo.h"
#import "MSAuthTokenValidityInfo.h"
#import "MSConstants+Internal.h"
#import "MSKeychainUtil.h"
#import "MSLogger.h"
#import "MSUtility.h"

NS_ASSUME_NONNULL_BEGIN

@class MSUserInformation;
@protocol MSAuthTokenContextDelegate;

/**
 * MSAuthTokenContext is a singleton responsible for keeping an in-memory reference to an auth token and token history.
 * This enables all App Center modules to access the token, token history, and receive a notification when the token changes or needs to be
 * refreshed.
 */
@interface MSAuthTokenContext : NSObject

/**
 * Cached authorization token.
 */
@property(nullable, atomic, readonly) NSString *authToken;

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
 * Set current auth token and user information.
 *
 * @param authToken token to be added to the storage.
 * @param accountId account Id to be added to the storage.
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
 * Returns current user account Id.
 *
 * @return account Id.
 */
- (nullable NSString *)accountId;

/**
 * Returns array of auth tokens validity info.
 *
 * @return Array of MSAuthTokenValidityInfo.
 */
- (NSMutableArray<MSAuthTokenValidityInfo *> *)authTokenValidityArray;

/**
 * Removes the token from history. Please note that only oldest token is
 * allowed to be removed. To reset current token to be anonymous, use
 * the setToken method with nil parameters instead.
 *
 * @param authToken Auth token to be removed. Despite the fact that only the oldest token can be removed, it's required to avoid removing
 * the wrong one on duplicated calls etc.
 */
- (void)removeAuthToken:(nullable NSString *)authToken;

@end

NS_ASSUME_NONNULL_END
