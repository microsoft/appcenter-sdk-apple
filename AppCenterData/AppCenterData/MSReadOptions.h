// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSBaseOptions.h"

@interface MSReadOptions : MSBaseOptions

/**
 * Initialize a MSReadOptions object.
 *
 * @param deviceTimeToLive time, in seconds, that document will be kept in the device cache. Time is releative to now.
 *
 * @return A MSWriteOptions instance.
 */
- (instancetype)initWithDeviceTimeToLive:(NSInteger)deviceTimeToLive;

/**
 * Create an instance of MSReadOptions with infinite cache time.
 *
 * @return A MSReadOptions instance.
 */
+ (MSReadOptions *)createInfiniteCacheOptions;

/**
 * Create an instance of MSReadOptions with no cache.
 *
 * @return A MSReadOptions instance.
 */
+ (MSReadOptions *)createNoCacheOptions;

@end
