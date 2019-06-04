// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSUserInformation : NSObject

/**
 * The account identifier for the user.
 */
@property(nullable, nonatomic, copy) NSString *accountId;

/**
 * The access token for the user. This is a JWT that can be used with the Microsoft Graph API (https://developer.microsoft.com/en-us/graph).
 * It can also be decoded and parsed to obtain information about the current user.
 */
@property(nullable, nonatomic, copy) NSString *accessToken;

/**
 * The ID token for the user.
 */
@property(nullable, nonatomic, copy) NSString *idToken;

/**
 * Create user with account identifier.
 *
 * @param accountId The account identifier for the user.
 * @param accessToken The access token for the user.
 * @param idToken The ID token for the user.
 *
 * @return A new instance.
 */
- (instancetype)initWithAccountId:(nullable NSString *)accountId
                      accessToken:(nullable NSString *)accessToken
                          idToken:(nullable NSString *)idToken;

@end

NS_ASSUME_NONNULL_END
