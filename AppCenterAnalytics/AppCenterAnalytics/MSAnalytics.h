#import "MSServiceAbstract.h"
#import "MSAnalyticsTenant.h"

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
+ (void)trackEvent:(NSString *)eventName withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties;

/**
 * Get a tenant.
 *
 * @param tenantId identifier of the tenant to retrieve.
 *
 * @returns The tenant object.
 */
+ (MSAnalyticsTenant *)getTenant:(NSString *)tenantId;

@end

NS_ASSUME_NONNULL_END
