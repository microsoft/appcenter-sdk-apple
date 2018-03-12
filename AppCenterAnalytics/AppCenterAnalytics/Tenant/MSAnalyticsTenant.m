#import "MSAnalyticsTenantInternal.h"
#import "MSAnalyticsInternal.h"

@implementation MSAnalyticsTenant

- (instancetype)initWithTenantId:(NSString *)tenantId {
  self = [super init];
  if (self) {
    self.tenantId = tenantId;
  }
  return self;
}

/**
 * Track an event.
 *
 * @param eventName  event name.
 */
- (void)trackEvent:(NSString *)eventName {
  [MSAnalytics trackEvent:eventName forTenant:self];
}

/**
 * Track an event.
 *
 * @param eventName  event name.
 * @param properties dictionary of properties.
 */
- (void)trackEvent:(NSString *)eventName withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties {
  [MSAnalytics trackEvent:eventName withProperties:properties forTenant:self];
}


@end
