#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSAnalyticsTransmissionTarget : NSObject

/**
 * Track an event.
 *
 * @param eventName  event name.
 */
- (void)trackEvent:(NSString *)eventName;

/**
 * Track an event.
 *
 * @param eventName  event name.
 * @param properties dictionary of properties.
 */
- (void)trackEvent:(NSString *)eventName withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties;

@end

NS_ASSUME_NONNULL_END
