#import "MSAnalytics.h"
#import "MSServiceInternal.h"
#import "MSSessionTracker.h"
#import "MSSessionTrackerDelegate.h"
#import "MSAnalyticsDelegate.h"

@interface MSAnalytics () <MSSessionTrackerDelegate>

/**
 *  Session tracking component
 */
@property(nonatomic) MSSessionTracker *sessionTracker;

@property(nonatomic) BOOL autoPageTrackingEnabled;

@property(nonatomic) id<MSAnalyticsDelegate> delegate;

/**
 * Track an event.
 *
 * @param eventName  event name.
 * @param properties dictionary of properties.
 */
- (void)trackEvent:(NSString *)eventName withProperties:(NSDictionary<NSString *, NSString *> *)properties;

/**
 * Track a page.
 *
 * @param pageName  page name.
 * @param properties dictionary of properties.
 */
- (void)trackPage:(NSString *)pageName withProperties:(NSDictionary<NSString *, NSString *> *)properties;

/**
 * Method to reset the singleton when running unit tests only. So calling sharedInstance returns a fresh instance.
 */
+ (void)resetSharedInstance;
@end
