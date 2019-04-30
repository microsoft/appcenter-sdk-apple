// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSBaseOptions.h"
#import "AppCenter+Internal.h"
#import "MSData.h"
#import "MSDataInternal.h"

@implementation MSBaseOptions

@synthesize deviceTimeToLive = _deviceTimeToLive;

- (instancetype)init {
  return [self initWithDeviceTimeToLive:kMSDataTimeToLiveDefault];
}

- (instancetype)initWithDeviceTimeToLive:(NSInteger)deviceTimeToLive {
  if (deviceTimeToLive < -1) {
    MSLogError([MSData logTag],
               @"Invalid argument, device time to live value should be greater than or equal to zero, or -1 for infinite.");
    return nil;
  }
  if ((self = [super init])) {
    _deviceTimeToLive = deviceTimeToLive;
  }
  return self;
}

@end
