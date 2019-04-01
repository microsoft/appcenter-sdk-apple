// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

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

@end
