#import "MSAnalyticsTransmissionTarget.h"
#import "MSServiceAbstract.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * App Center analytics service.
 */
@interface MSAnalytics : MSServiceAbstract

/**
 * Track an event.
 *
 * @param eventName  event name.
 */
+ (void)trackEvent:(NSString *)eventName;

/**
 * Track an event.
 *
 * @param eventName  event name.
 * @param properties dictionary of properties.
 */
+ (void)trackEvent:(NSString *)eventName
    withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties;

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
