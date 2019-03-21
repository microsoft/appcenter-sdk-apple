// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@class MSAuthTokenInfo;

NS_ASSUME_NONNULL_BEGIN

@protocol MSAuthTokenStorage <NSObject>

/**
 * Returns current auth token.
 *
 * @return auth token.
 */
- (nullable NSString *)retrieveAuthToken;

/**
 * Returns current account identifier.
 *
 * @return account identifier.
 */
- (nullable NSString *)retrieveAccountId;

/**
 * Returns auth token info for the oldest entity in the the history.
 *
 * @return auth token info.
 */
- (MSAuthTokenInfo *)oldestAuthToken;

/**
 * Returns auth token info for the latest entity in the the history.
 *
 * @return auth token info.
 */
- (MSAuthTokenInfo *)latestAuthToken;

/**
 * Stores auth token and account ID to settings and keychain.
 *
 * @param authToken Auth token.
 * @param accountId Account identifier.
 */
- (void)saveAuthToken:(nullable NSString *)authToken withAccountId:(nullable NSString *)accountId expiresOn:(nullable NSDate *)expiresOn;

/**
 * Removes auth token from the history.
 *
 * @param authToken Auth token to delete.
 */
- (void)removeAuthToken:(nullable NSString *)authToken;

@end

NS_ASSUME_NONNULL_END
