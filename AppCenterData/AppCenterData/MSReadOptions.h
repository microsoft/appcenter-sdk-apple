// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSBaseOptions.h"

@interface MSReadOptions : MSBaseOptions

/**
 * Create an instance of MSReadOptions with infinite cache time.
 *
 * @return A MSReadOptions instance.
 */
+ (instancetype)createInfiniteCacheOptions;

/**
 * Create an instance of MSReadOptions with no cache.
 *
 * @return A MSReadOptions instance.
 */
+ (instancetype)createNoCacheOptions;

@end
