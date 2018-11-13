#import "MSAnalytics.h"
#import "MSAnalyticsDelegate.h"
#import "MSAnalyticsTransmissionTarget.h"
#import "MSChannelDelegate.h"
#import "MSServiceInternal.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSAnalytics () <MSServiceInternal, MSChannelDelegate>

/**
 * Track an event with typed properties.
 *
 * @param eventName  Event name.
 * @param properties The typed event properties.
 * @param transmissionTarget  The transmission target to associate to this event.
 * @param flags      Optional flags. Events tracked with the MSFlagsPersistenceCritical flag will take precedence over all other events in
 * storage. An event tracked with this option will only be dropped if storage must make room for a newer event that is also marked with the
 * MSFlagsPersistenceCritical flag.
 */
+ (void)trackEvent:(NSString *)eventName
      withTypedProperties:(nullable MSEventProperties *)properties
    forTransmissionTarget:(nullable MSAnalyticsTransmissionTarget *)transmissionTarget
                    flags:(MSFlags)flags;

// Temporarily hiding tracking page feature.
/**
 * Track a page.
 *
 * @param pageName  page name.
 */
+ (void)trackPage:(NSString *)pageName;

/**
 * Track a page.
 *
 * @param pageName  page name.
 * @param properties dictionary of properties.
 */
+ (void)trackPage:(NSString *)pageName withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties;

/**
 * Set the page auto-tracking property.
 *
 * @param isEnabled is page tracking enabled or disabled.
 */
+ (void)setAutoPageTrackingEnabled:(BOOL)isEnabled;

/**
 * Indicate if auto page tracking is enabled or not.
 *
 * @return YES if page tracking is enabled and NO if disabled.
 */
+ (BOOL)isAutoPageTrackingEnabled;

/**
 * Set the MSAnalyticsDelegate object.
 *
 * @param delegate The delegate to be set.
 */
+ (void)setDelegate:(nullable id<MSAnalyticsDelegate>)delegate;

/**
 * Pause transmission target for the given token.
 *
 * @param token The token of the transmission target.
 */
+ (void)pauseTransmissionTargetForToken:(NSString *)token;

/**
 * Resume transmission target for the given token.
 *
 * @param token The token of the transmission target.
 */
+ (void)resumeTransmissionTargetForToken:(NSString *)token;

@end

NS_ASSUME_NONNULL_END
