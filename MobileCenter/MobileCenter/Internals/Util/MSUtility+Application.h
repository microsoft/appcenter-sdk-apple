#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "MSUtility.h"

#define MS_DEVICE [UIDevice currentDevice]

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

typedef NS_ENUM(NSInteger, MSOpenURLState) {

  /**
   * Not being able to determine whether a URL has been processed or not.
   */
  MSOpenURLStateUnknown,

  /**
   * A URL has been processed successfully.
   */
  MSOpenURLStateSucceed,

  /**
   * A URL could not be processed.
   */
  MSOpenURLStateFailed
};

/**
 * Utility class that is used throughout the SDK.
 * Application part.
 */
@interface MSUtility (Application)

/**
 * Get the App Delegate.
 *
 * @return The delegate of the app object or nil if not accessible.
 */
+ (id<UIApplicationDelegate>)sharedAppDelegate;

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
 * @param completion The block to execute with the results.
 */
+ (void)sharedAppOpenUrl:(NSURL *)url
                 options:(NSDictionary<NSString *, id> *)options
       completionHandler:(void (^)(MSOpenURLState state))completion;
@end
