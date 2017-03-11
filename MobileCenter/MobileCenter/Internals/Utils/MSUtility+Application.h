#import <Foundation/Foundation.h>
#import "MSUtility.h"

/**
 *  App states
 */
typedef NS_ENUM(NSInteger, MSApplicationState) {
    
    /**
     * Application is active.
     */
    MSApplicationStateActive = UIApplicationStateActive,
    
    /**
     * Application is inactive.
     */
    MSApplicationStateInactive = UIApplicationStateInactive,
    
    /**
     * Application is in background.
     */
    MSApplicationStateBackground = UIApplicationStateBackground,
    
    /**
     * Application state can't be determined.
     */
    MSApplicationStateUnknown
};

/**
 * Utility class that is used throughout the SDK.
 * Application part.
 */
@interface MSUtility (Application)
/**
 * Get current application state.
 *
 * @discussion The application state may not be available anywhere. Application extensions doesn't have it for instance,
 * in that case the MSApplicationStateUnknown value is returned.
 * @return Current state of the application or MSApplicationStateUnknown while the state can't be determined.
 */
+ (MSApplicationState)applicationState;

@end
