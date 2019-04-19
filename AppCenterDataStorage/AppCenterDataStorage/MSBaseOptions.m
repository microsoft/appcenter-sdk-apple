// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSBaseOptions.h"
#import "MSDataStore.h"

@implementation MSBaseOptions

@synthesize deviceTimeToLive = _deviceTimeToLive;

- (instancetype)initWithDeviceTimeToLive:(long)deviceTimeToLive {
  if ((self = [super init])) {
    _deviceTimeToLive = deviceTimeToLive;
  }
  return self;
}

@end
