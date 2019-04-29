// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSWriteOptions.h"
#import "MSData.h"

@implementation MSWriteOptions

+ (instancetype)createInfiniteCacheOptions {
  return [[MSWriteOptions alloc] initWithDeviceTimeToLive:kMSDataTimeToLiveInfinite];
}

+ (instancetype)createNoCacheOptions {
  return [[MSWriteOptions alloc] initWithDeviceTimeToLive:kMSDataTimeToLiveNoCache];
}

@end
