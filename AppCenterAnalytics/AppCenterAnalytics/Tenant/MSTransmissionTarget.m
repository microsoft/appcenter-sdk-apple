#import "MSAnalyticsTransmissionTargetInternal.h"
#import "MSAnalyticsInternal.h"

@implementation MSTransmissionTarget

- (instancetype)initWithTransmissionToken:(NSString *)transmissionToken {
  self = [super init];
  if (self) {
    self.transmissionToken = transmissionToken;
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
