// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSData.h"
#import "MSWriteOptions.h"

@implementation MSWriteOptions

- (instancetype)initWithDeviceTimeToLive:(NSInteger)deviceTimeToLive {
  return [super initWithDeviceTimeToLive:deviceTimeToLive];
}

+ (MSWriteOptions *)createInfiniteCacheOptions {
  return [[MSWriteOptions alloc] initWithDeviceTimeToLive:kMSDataTimeToLiveInfinite];
}

+ (MSWriteOptions *)createNoCacheOptions {
  return [[MSWriteOptions alloc] initWithDeviceTimeToLive:kMSDataTimeToLiveNoCache];
}

@end
