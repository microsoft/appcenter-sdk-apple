// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSUserInformation : NSObject

/**
 * The account identifier for the user.
 */
@property(nonatomic, copy, nullable) NSString *accountId;

- (instancetype)initWithAccountId:(nullable NSString *)accountId;

- (BOOL)compareUser:(MSUserInformation *)userInfor;

@end

NS_ASSUME_NONNULL_END
