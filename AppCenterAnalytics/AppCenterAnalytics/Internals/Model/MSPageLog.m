// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "AppCenter+Internal.h"
#import "MSPageLog.h"

static NSString *const kMSTypePage = @"page";

@implementation MSPageLog

- (instancetype)init {
  if ((self = [super init])) {
    self.type = kMSTypePage;
  }
  return self;
}

- (BOOL)isEqual:(id)object {
  return [(NSObject *)object isKindOfClass:[MSPageLog class]] && [super isEqual:object];
}

@end
