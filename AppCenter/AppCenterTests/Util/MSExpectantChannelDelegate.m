#import "MSExpectantChannelDelegate.h"

@implementation MSExpectantChannelDelegate

- (void)onFailedPersistingLog:(id<MSLog>)log withInternalId:(NSString *)internalId {
  (self.persistedHandler)(log, internalId, NO);
}

- (void)onFinishedPersistingLog:(id<MSLog>)log withInternalId:(NSString *)internalId {
  (self.persistedHandler)(log, internalId, YES);
}

- (BOOL)shouldFilterLog:(id<MSLog>)log {
  (void)log;
  return NO;
}

- (void)onEnqueuingLog:(id<MSLog>)log withInternalId:(NSString *)internalId {
  (void)log;
  (void)internalId;
  // Do nothing but define method so method is invoked on delegates
}

@end
