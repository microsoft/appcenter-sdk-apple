// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSBaseOptions.h"

@implementation MSBaseOptions

@synthesize deviceTimeToLive = _deviceTimeToLive;

- (instancetype)initWithDeviceTimeToLive:(NSInteger)deviceTimeToLive {
  self = [super init];
  if (self) {
    self.deviceTimeToLive = deviceTimeToLive;
  }
  return self;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    self.deviceTimeToLive = 3600; // one hour in seconds
  }
  return self;
}

@end
