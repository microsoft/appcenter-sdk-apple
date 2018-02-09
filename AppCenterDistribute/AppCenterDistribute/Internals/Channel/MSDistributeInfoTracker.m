#import "MSDistributeInfoTracker.h"

@implementation MSDistributeInfoTracker

- (void)onEnqueuingLog:(id<MSLog>)log withInternalId:(NSString *)internalId {
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
