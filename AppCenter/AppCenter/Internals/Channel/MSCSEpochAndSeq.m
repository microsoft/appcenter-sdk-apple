// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSCSEpochAndSeq.h"

@implementation MSCSEpochAndSeq

- (instancetype)initWithEpoch:(NSString *)epoch {
  if ((self = [super init])) {
    _epoch = epoch;
    _seq = 0;
  }
  return self;
}

@end
