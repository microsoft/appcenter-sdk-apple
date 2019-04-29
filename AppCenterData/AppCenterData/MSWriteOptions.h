// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSBaseOptions.h"

@interface MSWriteOptions : MSBaseOptions

/**
 * Create an instance of MSWriteOptions with infinite cache time.
 *
 * @return A MSWriteOptions instance.
 */
+ (instancetype)createInfiniteCacheOptions;

/**
 * Create an instance of MSWriteOptions with no cache.
 *
 * @return A MSWriteOptions instance.
 */
+ (instancetype)createNoCacheOptions;

@end
