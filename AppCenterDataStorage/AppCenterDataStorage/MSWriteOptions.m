// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSWriteOptions.h"

@implementation MSWriteOptions

- (instancetype)initWithTimeToLive:(NSInteger)timeToLive {
  if ((self = [super initWithDeviceTimeToLive:timeToLive])) {
  }
  return self;
}

@end
