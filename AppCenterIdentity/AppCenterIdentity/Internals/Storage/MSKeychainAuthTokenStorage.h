// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthTokenStorage.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSKeychainAuthTokenStorage : NSObject <MSAuthTokenStorage>

/**
 * Used to get and set auth tokens history array.
 */
@property(nullable, nonatomic) NSArray<MSAuthTokenInfo *> *authTokenHistory;

@end

NS_ASSUME_NONNULL_END
