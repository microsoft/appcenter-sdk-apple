// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSMockLog.h"

static NSString *const kMSTypeMockLog = @"mockLog";

@implementation MSMockLog

- (instancetype)init {
  if ((self = [super init])) {
    self.type = kMSTypeMockLog;
  }
  return self;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];
  return dict;
}

@end
