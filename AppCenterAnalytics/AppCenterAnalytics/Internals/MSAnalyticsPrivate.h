#import "MSAnalytics.h"
#import "MSAnalyticsDelegate.h"
#import "MSAnalyticsTransmissionTarget.h"
#import "MSServiceInternal.h"
#import "MSSessionTracker.h"
#import "MSSessionTrackerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSAnalytics () <MSSessionTrackerDelegate>

/**
 *  Session tracking component.
 */
@property(nonatomic) MSSessionTracker *sessionTracker;

@property(nonatomic) BOOL autoPageTrackingEnabled;

@property(nonatomic, nullable) id<MSAnalyticsDelegate> delegate;

/**
 * Transmission targets.
 */
@property(nonatomic)
    NSMutableDictionary<NSString *, MSAnalyticsTransmissionTarget *>
        *transmissionTargets;

/**
 * Default transmission target.
 */
@property(nonatomic) MSAnalyticsTransmissionTarget *defaultTransmissionTarget;

/**
 * Track an event.
 *
 * @param eventName  event name.
 * @param properties dictionary of properties.
 * @param transmissionTarget Transmission target to associate with the event.
 */
- (void)trackEvent:(NSString *)eventName
           withProperties:
               (nullable NSDictionary<NSString *, NSString *> *)properties
    forTransmissionTarget:
        (nullable MSAnalyticsTransmissionTarget *)transmissionTarget;

/**
 * Track a page.
 *
 * @param pageName  page name.
 * @param properties dictionary of properties.
 */
- (void)trackPage:(NSString *)pageName
    withProperties:(nullable NSDictionary<NSString *, NSString *> *)properties;

/**
 * Get a transmissionTarget.
 *
 * @param transmissionTargetToken Token of the transmission target to retrieve.
 *
 * @returns The transmission target object.
 */
- (MSAnalyticsTransmissionTarget *)transmissionTargetFor:
    (NSString *)transmissionTargetToken;

/**
 * Method to reset the singleton when running unit tests only. So calling
 * sharedInstance returns a fresh instance.
 */
+ (void)resetSharedInstance;

@end

NS_ASSUME_NONNULL_END
