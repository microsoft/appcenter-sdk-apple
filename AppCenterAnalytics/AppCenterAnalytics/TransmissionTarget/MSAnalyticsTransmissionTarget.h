#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSAnalyticsTransmissionTarget : NSObject

/**
 * Set an event property to be attached to events tracked by this transmission target and its child transmission
 * targets.
 *
 * @param propertyValue Property value.
 * @param propertyKey Property key.
 *
 * @discussion A property set in a child transmission target overrides a property with the same key inherited from its
 * parents. Also, the properties passed to the `trackEvent:withProperties:` override any property with the same key
 * from the transmission target itself or its parents.
 */
- (void)setEventPropertyString:(NSString *)propertyValue forKey:(NSString *)propertyKey;

/**
 * Remove an event property from this transmission target.
 *
 * @param propertyKey Property key.
 *
 * @discussion This won't remove properties with the same name declared in other nested transmission targets.
 */
- (void)removeEventPropertyforKey:(NSString *)propertyKey;

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

/**
 * Get a nested transmission target.
 *
 * @param token The token of the transmission target to retrieve.
 *
 * @returns A transmission target object nested to this parent transmission target.
 */
- (MSAnalyticsTransmissionTarget *)transmissionTargetForToken:(NSString *)token
    NS_SWIFT_NAME(transmissionTarget(forToken:));

/**
 * Enable or disable this transmission target. It will also enable or disable nested transmission targets.
 *
 * @param isEnabled YES to enable, NO to disable.
 * @see isEnabled
 */
- (void)setEnabled:(BOOL)isEnabled;

/**
 * Check whether this transmission target is enabled or not.
 *
 * @return YES if enabled, NO otherwise.
 * @see setEnabled:
 */
- (BOOL)isEnabled;

@end

NS_ASSUME_NONNULL_END
