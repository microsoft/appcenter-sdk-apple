#import "MSDistributeInfoTracker.h"

@implementation MSDistributeInfoTracker

- (void)channel:(id<MSChannelUnitProtocol>)channel didEnqueueLog:(id<MSLog>)log withInternalId:(NSString *)internalId {
  (void)channel;
  (void)internalId;
  if (self.distributionGroupId == nil) {
    return;
  }

  // Set current distribution group ID.
  log.distributionGroupId = self.distributionGroupId;
}

- (void) updateDistributionGroupId:(NSString *)distributionGroupId {
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
