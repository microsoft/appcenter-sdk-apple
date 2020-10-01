// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "AppCenter+Internal.h"
#import "MSACPageLog.h"

static NSString *const kMSACTypePage = @"page";

@implementation MSACPageLog

- (instancetype)init {
  if ((self = [super init])) {
    self.type = kMSACTypePage;
  }
  return self;
}

- (BOOL)isEqual:(id)object {
  return [(NSObject *)object isKindOfClass:[MSACPageLog class]] && [super isEqual:object];
}

@end
