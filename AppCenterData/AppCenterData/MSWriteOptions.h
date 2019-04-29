// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSBaseOptions.h"

@interface MSWriteOptions : MSBaseOptions

/**
 * Initialize a MSWriteOptions object.
 *
 * @param deviceTimeToLive time, in seconds, that document will be kept in the device cache. Time is releative to now.
 *
 * @return A MSWriteOptions instance.
 */
- (instancetype)initWithDeviceTimeToLive:(NSInteger)deviceTimeToLive;

/**
 * Create an instance of MSWriteOptions with infinite cache time.
 *
 * @return A MSWriteOptions instance.
 */
+ (MSWriteOptions *)createInfiniteCacheOptions;

/**
 * Create an instance of MSWriteOptions with no cache.
 *
 * @return A MSWriteOptions instance.
 */
+ (MSWriteOptions *)createNoCacheOptions;

@end
