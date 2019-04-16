// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

@class MSAuthTokenInfo;

@interface MSAuthTokenContext ()

/**
 * Private field used to get and set auth tokens history array.
 */
@property(nullable, nonatomic) NSArray<MSAuthTokenInfo *> *authTokenHistoryArray;

/**
 * Reset singleton instance.
 */
+ (void)resetSharedInstance;

/**
 * Gets auth token history array.
 */
- (NSArray<MSAuthTokenInfo *> *)authTokenHistory;

/**
 * Sets auth token history array.
 */
- (void)setAuthTokenHistory:(nullable NSArray<MSAuthTokenInfo *> *)authTokenHistory;

@end
