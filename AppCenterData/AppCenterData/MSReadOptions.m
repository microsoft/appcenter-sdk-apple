// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSReadOptions.h"
#import "MSData.h"

@implementation MSReadOptions

- (instancetype)initWithDeviceTimeToLive:(NSInteger)deviceTimeToLive {
  return [super initWithDeviceTimeToLive:deviceTimeToLive];
}

+ (instancetype)createInfiniteCacheOptions {
  return [[MSReadOptions alloc] initWithDeviceTimeToLive:kMSDataTimeToLiveInfinite];
}

+ (instancetype)createNoCacheOptions {
  return [[MSReadOptions alloc] initWithDeviceTimeToLive:kMSDataTimeToLiveNoCache];
}

@end
