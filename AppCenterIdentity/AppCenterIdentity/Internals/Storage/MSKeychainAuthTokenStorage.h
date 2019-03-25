// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthTokenStorage.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSKeychainAuthTokenStorage : NSObject <MSAuthTokenStorage>

@property(nullable, nonatomic) NSMutableArray<MSAuthTokenInfo *> *authTokensHistoryState;

@end

NS_ASSUME_NONNULL_END
