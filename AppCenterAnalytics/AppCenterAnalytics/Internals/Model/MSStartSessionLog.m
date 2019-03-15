// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSStartSessionLog.h"

static NSString *const kMSTypeEndSession = @"startSession";

@implementation MSStartSessionLog

- (instancetype)init {
  if ((self = [super init])) {
    self.type = kMSTypeEndSession;
  }
  return self;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
}

@end
