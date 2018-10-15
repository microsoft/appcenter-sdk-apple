#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSPropertyConfigurator : NSObject

/**
 * Override the application version.
 *
 * @param appVersion New application version for a transmission target.
 */
- (void)setAppVersion:(nullable NSString *)appVersion;

/**
 * Override the application name.
 *
 * @param appName New application name for a transmission target.
 */
- (void)setAppName:(nullable NSString *)appName;

/**
 * Override the application locale.
 *
 * @param appLocale New application locale for a transmission target.
 */
- (void)setAppLocale:(nullable NSString *)appLocale;

/**
 * Set an event property to be attached to events tracked by this transmission target and its child transmission targets.
 *
 * @param propertyValue Property value.
 * @param propertyKey Property key.
 *
 * @discussion A property set in a child transmission target overrides a property with the same key inherited from its parents. Also, the
 * properties passed to the `trackEvent:withProperties:` override any property with the same key from the transmission target itself or its
 * parents.
 */
- (void)setEventPropertyString:(NSString *)propertyValue forKey:(NSString *)propertyKey;

/**
 * Remove an event property from this transmission target.
 *
 * @param propertyKey Property key.
 *
 * @discussion This won't remove properties with the same name declared in other nested transmission targets.
 */
- (void)removeEventPropertyForKey:(NSString *)propertyKey;

/**
 * Once called, the App Center SDK will automatically add UIDevice.identifierForVendor to common schema logs.
 *
 * @discussion Call this before starting the SDK. This setting is not persisted, so you need to call this when setting up the SDK every
 * time. If you want to provide a way for users to opt-in or opt-out of this setting, it is on you to persist their choice and configure the
 * App Center SDK accordingly.
 */
- (void)collectDeviceId;

NS_ASSUME_NONNULL_END

@end
