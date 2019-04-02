// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSUserInformation : NSObject

/**
 * The account identifier for the user.
 */
@property(nonatomic, copy, nullable) NSString *accountId;

/**
 * Create user with account identifier.
 *
 * @param accountId account identifier for the user.
 *
 * @return user with account identifier.
 */
- (instancetype)initWithAccountId:(nullable NSString *)accountId;

/**
 * Confirm current user is equal to another user.
 *
 * @param userInfo the other user.
 *
 * @return `YES` if current user is equal to another user, `NO` not equal
 */
- (BOOL)isEqualTo:(MSUserInformation *)userInfo;

@end

NS_ASSUME_NONNULL_END
