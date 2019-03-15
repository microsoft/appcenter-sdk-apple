// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDistributeInfoTracker.h"

@implementation MSDistributeInfoTracker

- (void)channel:(id<MSChannelProtocol>)__unused channel prepareLog:(id<MSLog>)log {
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
