#import "MSAnalytics.h"
#import "MSAnalyticsDelegate.h"
#import "MSAnalyticsTransmissionTarget.h"
#import "MSChannelDelegate.h"
#import "MSServiceInternal.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSAnalytics () <MSServiceInternal, MSChannelDelegate>

/**
 * Track an event.
 *
 * @param eventName  Event name.
 * @param properties Dictionary of properties.
 * @param transmissionTarget  The transmission target to associate to this
 * event.
 */
+ (void)trackEvent:(NSString *)eventName
           withProperties:
               (nullable NSDictionary<NSString *, NSString *> *)properties
    forTransmissionTarget:
        (nullable MSAnalyticsTransmissionTarget *)transmissionTarget;

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
+ (void)trackPage:(NSString *)pageName
    withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties;

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

+ (void)setDelegate:(nullable id<MSAnalyticsDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
