#import <Foundation/Foundation.h>
#import "MSUtil.h"


/**
 * Utility class that is used throughout the SDK.
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
