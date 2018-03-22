#import "MSAnalyticsTransmissionTargetInternal.h"
#import "MSAnalyticsInternal.h"

@implementation MSAnalyticsTransmissionTarget

- (instancetype)initWithTransmissionTargetToken:(NSString *)transmissionTargetToken {
  self = [super init];
  if (self) {
    self.transmissionTargetToken = transmissionTargetToken;
  }
  return self;
}

/**
 * Track an event.
 *
 * @param eventName  event name.
 */
- (void)trackEvent:(NSString *)eventName {
  [MSAnalytics trackEvent:eventName forTransmissionTarget:self];
}

/**
 * Track an event.
 *
 * @param eventName  event name.
 * @param properties dictionary of properties.
 */
- (void)trackEvent:(NSString *)eventName withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties {
  [MSAnalytics trackEvent:eventName withProperties:properties forTransmissionTarget:self];
}

@end
