// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MSAuthTokenContext;
@class MSUserInformation;

@protocol MSAuthTokenContextDelegate <NSObject>

@optional

/**
 * A callback that is called when an auth token is received.
 *
 * @param authTokenContext The auth token context.
 * @param authToken The new auth token.
 */
- (void)authTokenContext:(MSAuthTokenContext *)authTokenContext didUpdateAuthToken:(nullable NSString *)authToken;

/**
 * A callback that is called when a new user signs in.
 *
 * @param authTokenContext The auth token context.
 * @param accountId The new account ID. `nil` if a user signed out.
 */
- (void)authTokenContext:(MSAuthTokenContext *)authTokenContext didUpdateAccountId:(nullable NSString *)accountId;

/**
 * A callback that is called when a token needs to be refreshed.
 *
 * @param authTokenContext The auth token context.
 * @param accountId The account ID of the auth token that expires soon and needs to be refreshed.
 */
- (void)authTokenContext:(MSAuthTokenContext *)authTokenContext refreshAuthTokenForAccountId:(nullable NSString *)accountId;

@end

NS_ASSUME_NONNULL_END
