#import "MSExpectantChannelDelegate.h"

@implementation MSExpectantChannelDelegate

- (void)onFailedPersistingLog:(id<MSLog>)log withInternalId:(NSString *)internalId {
  (self.persistedHandler)(log, internalId, NO);
}

- (void)onFinishedPersistingLog:(id<MSLog>)log withInternalId:(NSString *)internalId {
  (self.persistedHandler)(log, internalId, YES);
}

@end
