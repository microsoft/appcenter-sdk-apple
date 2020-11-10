// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACDistributeInfoTracker.h"

@implementation MSACDistributeInfoTracker

- (void)channel:(id<MSACChannelProtocol>)__unused channel prepareLog:(id<MSACLog>)log {
  if (self.distributionGroupId == nil) {
    return;
  }

  // Set current distribution group ID.
  log.distributionGroupId = self.distributionGroupId;
}

- (void)updateDistributionGroupId:(NSString *)distributionGroupId {
  @synchronized(self) {
    self.distributionGroupId = distributionGroupId;
  }
}

- (void)removeDistributionGroupId {
  @synchronized(self) {
    self.distributionGroupId = nil;
  }
}

@end
