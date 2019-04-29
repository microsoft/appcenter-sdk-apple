// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSWriteOptions.h"
#import "MSData.h"

@implementation MSWriteOptions

+ (MSWriteOptions *)createInfiniteCacheOptions {
  return [[MSWriteOptions alloc] initWithDeviceTimeToLive:kMSDataTimeToLiveInfinite];
}

+ (MSWriteOptions *)createNoCacheOptions {
  return [[MSWriteOptions alloc] initWithDeviceTimeToLive:kMSDataTimeToLiveNoCache];
}

@end
