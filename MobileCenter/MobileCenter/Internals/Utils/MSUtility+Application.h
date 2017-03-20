#import <Foundation/Foundation.h>
#import "MSUtility.h"

/*
 * Workaround for exporting symbols from category object files.
 */
extern NSString *MSUtilityApplicationCategory;

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
 * @return Current state of the application or MSApplicationStateUnknown while the state can't be determined.
 *
 * @discussion The application state may not be available anywhere. Application extensions doesn't have it for instance,
 * in that case the MSApplicationStateUnknown value is returned.
 */
+ (MSApplicationState)applicationState;

/**
 * Attempt to open the URL asynchronously.
 *
 * @param url The URL to open.
 * @param options A dictionary of options to use when opening the URL.
 * @param completion The block to execute with the results. A BOOL indicates whether the URL was opened successfully.
 */
+ (void)sharedAppOpenUrl:(NSURL *)url
                 options:(NSDictionary<NSString *, id> *)options
       completionHandler:(void (^__nullable)(BOOL success))completion;
@end
