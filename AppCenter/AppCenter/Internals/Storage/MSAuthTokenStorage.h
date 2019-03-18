// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@class MSAuthTokenInfo;

NS_ASSUME_NONNULL_BEGIN

@protocol MSAuthTokenStorage <NSObject>

- (nullable NSString *)retrieveAuthToken;

- (nullable NSString *)retrieveAccountId;

- (MSAuthTokenInfo *)oldestAuthToken;

- (void)saveAuthToken:(nullable NSString *)authToken withAccountId:(nullable NSString *)accountId;

- (void)removeAuthToken:(nullable NSString *)authToken;

@end

NS_ASSUME_NONNULL_END
