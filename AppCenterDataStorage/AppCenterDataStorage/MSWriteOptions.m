// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSWriteOptions.h"

@implementation MSWriteOptions

- (instancetype)initWithTtl:(NSInteger)ttl {
  if ((self = [super initWithDeviceTimeToLive:ttl])) {
  }
  return self;
}

@end
