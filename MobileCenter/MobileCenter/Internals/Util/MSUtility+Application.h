#import <Foundation/Foundation.h>
#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#else
#import <UIKit/UIKit.h>
#endif

#import "MSUtility.h"

#if !TARGET_OS_OSX
#define MS_DEVICE [UIDevice currentDevice]
#endif

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
#if TARGET_OS_OSX
  MSApplicationStateActive,
#else
  MSApplicationStateActive = UIApplicationStateActive,
#endif

/**
 * Application is inactive.
 */
#if TARGET_OS_OSX
  MSApplicationStateInactive,
#else
  MSApplicationStateInactive = UIApplicationStateInactive,
#endif

/**
 * Application is in background.
 */
#if TARGET_OS_OSX
  MSApplicationStateBackground,
#else
  MSApplicationStateBackground = UIApplicationStateBackground,
#endif

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

#if TARGET_OS_OSX

// TODO: ApplicationDelegate is not yet implemented for macOS.
#else

/**
 * Get the App Delegate.
 *
 * @return The delegate of the app object or nil if not accessible.
 */
+ (id<UIApplicationDelegate>)sharedAppDelegate;
#endif

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
