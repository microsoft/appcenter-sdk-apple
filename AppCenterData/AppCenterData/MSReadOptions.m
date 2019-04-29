// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSData.h"
#import "MSReadOptions.h"

@implementation MSReadOptions

- (instancetype)initWithDeviceTimeToLive:(NSInteger)deviceTimeToLive {
  return [super initWithDeviceTimeToLive:deviceTimeToLive];
}

+ (MSReadOptions *)createInfiniteCacheOptions {
  return [[MSReadOptions alloc] initWithDeviceTimeToLive:kMSDataTimeToLiveInfinite];
}

+ (MSReadOptions *)createNoCacheOptions {
  return [[MSReadOptions alloc] initWithDeviceTimeToLive:kMSDataTimeToLiveNoCache];
}

@end
