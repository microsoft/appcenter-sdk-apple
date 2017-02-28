#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define MS_USER_DEFAULTS [MSUserDefaults shared]
#define MS_NOTIFICATION_CENTER [NSNotificationCenter defaultCenter]
#define MS_DEVICE [UIDevice currentDevice]
#define MS_UUID_STRING [[NSUUID UUID] UUIDString]
#define MS_UUID_FROM_STRING(uuidString) [[NSUUID alloc] initWithUUIDString:uuidString]
#define MS_LOCALE [NSLocale currentLocale]
#define MS_CLASS_NAME_WITHOUT_PREFIX [NSStringFromClass([self class]) substringFromIndex:2]
#define MS_IS_APP_EXTENSION [[[NSBundle mainBundle] executablePath] containsString:@".appex/"]
#define MS_APP_MAIN_BUNDLE [NSBundle mainBundle]

/**
 *  App environment
 */
typedef NS_ENUM(NSInteger, MSEnvironment) {
  /**
   *  App has been downloaded from the AppStore.
   */
  MSEnvironmentAppStore = 0,
  /**
   *  App has been downloaded from TestFlight.
   */
  MSEnvironmentTestFlight = 1,
  /**
   *  App has been installed by some other mechanism.
   *  This could be Ad-Hoc, Enterprise, etc.
   */
  MSEnvironmentOther = 99
};

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
 */
@interface MSUtil : NSObject

/**
 * Detect the environment that the app is running in.
 *
 * @return the MSEnvironment of the app.
 */
+ (MSEnvironment)currentAppEnvironment;

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
 * Let the OS open the given URL.
 *
 * @param url URL to open.
 *
 * @discussion This method is not available for app extensions and will do nothing in such case.
 */
+ (void)sharedAppOpenURL:(NSURL *)url;

/**
 * Determine whether the OS can open the URL or not.
 *
 * @param url URL to test.
 *
 * @return `YES` if the given URL can be opened `NO` otherwise.
 *
 * @discussion This method is not available for app extensions and will always return `NO` in such case.
 */
+ (BOOL)sharedAppCanOpenURL:(NSURL *)url;

/**
 * Return the current date (aka NOW) in ms.
 *
 * @return current time in ms with sub-ms precision if necessary
 *
 * @discussion
 * Utility function that returns NOW as a NSTimeInterval but in ms instead of seconds with sub-ms precision.
 * We're using NSTimeInterval here instead of long long because we might be interested in sub-millisecond precision
 * which we keep with NSTimeInterval as NSTimeInterval is actually NSDouble.
 */
+ (NSTimeInterval)nowInMilliseconds;

/**
 * Add dashes to the given string to format it as a UUID string.
 *
 * @param aString String to format as a UUID string.
 *
 * @return a UUID string or `nil` if formatting failed.
 */
+ (NSString *)formatToUUIDString:(NSString *)aString;

@end
