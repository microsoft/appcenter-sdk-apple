// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@class MSAuthTokenInfo;
@class MSAuthTokenHistoryState;

NS_ASSUME_NONNULL_BEGIN

@protocol MSAuthTokenStorage <NSObject>

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
 * Returns array of auth tokens.
 *
 * @return Array of MSAuthTokenInfo
 */
- (NSMutableArray<MSAuthTokenHistoryState *> *)authTokenArray;

/**
 * Stores auth token and account ID to settings and keychain.
 *
 * @param authToken Auth token.
 * @param accountId Account identifier.
 */
- (void)saveAuthToken:(nullable NSString *)authToken withAccountId:(nullable NSString *)accountId expiresOn:(nullable NSDate *)expiresOn;

/**
 * Removes the token from history. Please note that only oldest token is
 * allowed to remove. To reset current to anonymous, use
 * the saveToken method with nil value instead.
 *
 * @param authToken Auth token to remove. Despite the fact that only the oldest
 *                  token can be removed, it's required to avoid removing
 *                  the wrong one on duplicated calls etc.
 */
- (void)removeAuthToken:(nullable NSString *)authToken;

@end

NS_ASSUME_NONNULL_END
