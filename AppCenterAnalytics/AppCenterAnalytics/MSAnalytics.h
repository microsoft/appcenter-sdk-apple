#import "MSAnalyticsTransmissionTarget.h"
#import "MSServiceAbstract.h"

@class MSEventProperties;

NS_ASSUME_NONNULL_BEGIN

/**
 * App Center analytics service.
 */
@interface MSAnalytics : MSServiceAbstract

/**
 * Track an event.
 *
 * @param eventName  Event name.
 */
+ (void)trackEvent:(NSString *)eventName;

/**
 * Track an event with properties.
 *
 * @param eventName  Event name.
 * @param properties Dictionary of properties.
 */
+ (void)trackEvent:(NSString *)eventName withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties;

/**
 * Track an event with typed properties.
 *
 * @param eventName  Event name.
 * @param properties An MSEventProperties object.
 *
 * @discussion For events going to App Center, the following validation rules are applied:
 * - The event name cannot be longer than 256 and is truncated otherwise.
 * - The property names cannot be empty.
 * - The property names and values are limited to 125 characters each (truncated).
 * - The number of properties per event is limited to 20 (truncated).
 */
+ (void)trackEvent:(NSString *)eventName withTypedProperties:(nullable MSEventProperties *)properties;

/**
 * Pause transmission of Analytics logs. While paused, Analytics logs are saved to disk.
 *
 * @see resume
 */
+ (void)pause;

/**
 * Resume transmission of Analytics logs. Any Analytics logs that accumulated on disk while paused are sent to the
 * server.
 *
 * @see pause
 */
+ (void)resume;

/**
 * Get a transmission target.
 *
 * @param token The token of the transmission target to retrieve.
 *
 * @returns The transmission target object.
 *
 * @discussion This method does not need to be annotated with
 * NS_SWIFT_NAME(transmissionTarget(forToken:)) as this is a static method that
 * doesn't get translated like a setter in Swift.
 *
 * @see MSAnalyticsTransmissionTarget for comparison.
 */
+ (MSAnalyticsTransmissionTarget *)transmissionTargetForToken:(NSString *)token;

@end

NS_ASSUME_NONNULL_END
