// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACDistributionGroup.h"

@implementation MSACDistributionGroup

- (BOOL)isEqual:(id)object {
  if (![(NSObject *)object isKindOfClass:[MSACDistributionGroup class]]) {
    return NO;
  }
  return YES;
}

@end
