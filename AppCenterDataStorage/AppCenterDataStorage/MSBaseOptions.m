// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSBaseOptions.h"
#import "MSDataStore.h"

@implementation MSBaseOptions

@synthesize deviceTimeToLive = _deviceTimeToLive;

- (instancetype)initWithDeviceTimeToLive:(NSTimeInterval)deviceTimeToLive {
  self = [super init];
  if (self) {
    self.deviceTimeToLive = deviceTimeToLive;
  }
  return self;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _deviceTimeToLive = MSDataStoreTimeToLiveDefault;
  }
  return self;
}

@end
