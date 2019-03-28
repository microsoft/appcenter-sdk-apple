// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSTokenExchange.h"
#import "MSTokenResult.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSTokenExchange ()

/**
 * Return a cached (CosmosDB resource) token for a given partition name.
 *
 * @param partitionName The partition for which to return the token.
 * @return The cached token or `nil`.
 */
+ (MSTokenResult *_Nullable)retrieveCachedToken:(NSString *)partitionName;

@end

NS_ASSUME_NONNULL_END
