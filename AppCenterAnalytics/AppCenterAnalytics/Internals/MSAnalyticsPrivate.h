#import "MSAnalytics.h"
#import "MSAnalyticsDelegate.h"
#import "MSAnalyticsTenant.h"
#import "MSServiceInternal.h"
#import "MSSessionTracker.h"
#import "MSSessionTrackerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSAnalytics () <MSSessionTrackerDelegate>

/**
 *  Session tracking component
 */
@property(nonatomic) MSSessionTracker *sessionTracker;

@property(nonatomic) BOOL autoPageTrackingEnabled;

@property(nonatomic) id<MSAnalyticsDelegate> delegate;

/**
 * Tenants
 */
@property(nonatomic) NSMutableDictionary *tenants;

/**
 * Track an event.
 *
 * @param eventName  event name.
 * @param properties dictionary of properties.
 * @param tenant tenant to associate with the event.
 */
- (void)trackEvent:(NSString *)eventName withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties forTenant:(nullable MSAnalyticsTenant *)tenant;

/**
 * Track a page.
 *
 * @param pageName  page name.
 * @param properties dictionary of properties.
 */
- (void)trackPage:(NSString *)pageName withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties;

/**
 * Get a tenant.
 *
 * @param tenantId identifier of the tenant to retrieve.
 *
 * @returns The tenant object.
 */
- (MSAnalyticsTenant *)getTenant:(NSString *)tenantId;

/**
 * Method to reset the singleton when running unit tests only. So calling sharedInstance returns a fresh instance.
 */
+ (void)resetSharedInstance;
@end

NS_ASSUME_NONNULL_END
