#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#ifndef MSAppDelegate
#define MSAppDelegate MSUIAppDelegate
#endif

NS_ASSUME_NONNULL_BEGIN

@class MSAppDelegateForwarder;

/**
 * Custom delegate matching `UIApplicationDelegate`.
 *
 * @discussion Delegates here are using swizzling. Any delegate that can be registered through the notification center
 * should not be registered through swizzling. Due to the early registration of swizzling on the original app delegate
 * each custom delegate must sign up for selectors to swizzle within the `load` method of a category over
 * the @see MSAppDelegateForwarder class.
 */
@protocol MSUIAppDelegate <NSObject>

@optional

/**
 * Asks the delegate to open a resource specified by a URL, and provides a dictionary of launch options.
 *
 * @param application The singleton app object.
 * @param url The URL resource to open. This resource can be a network resource or a file.
 * @param sourceApplication The bundle ID of the app that is requesting your app to open the URL (url).
 * @param annotation A Property list supplied by the source app to communicate information to the receiving app.
 * @param returnedValue Value returned by the original delegate implementation.
 *
 * @return `YES` if the delegate successfully handled the request or `NO` if the attempt to open the URL resource
 * failed.
 */
- (BOOL)application:(UIApplication *)application
              openURL:(NSURL *)url
    sourceApplication:(nullable NSString *)sourceApplication
           annotation:(id)annotation
        returnedValue:(BOOL)returnedValue;

/**
 * Asks the delegate to open a resource specified by a URL, and provides a dictionary of launch options.
 *
 * @param application The singleton app object.
 * @param url The URL resource to open. This resource can be a network resource or a file.
 * @param options A dictionary of URL handling options.
 * For information about the possible keys in this dictionary and how to handle them, @see
 * UIApplicationOpenURLOptionsKey. By default, the value of this parameter is an empty dictionary.
 * @param returnedValue Value returned by the original delegate implementation.
 *
 * @return `YES` if the delegate successfully handled the request or `NO` if the attempt to open the URL resource
 * failed.
 */
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options
      returnedValue:(BOOL)returnedValue;

/**
 * Tells the delegate that the app successfully registered with Apple Push Notification service (APNs).
 *
 * @param application The application that initiated the remote-notification registration process.
 * @param deviceToken A token that identifies the device to Apple Push Notification Service (APNS).
 * The token is an opaque data type because that is the form that the provider needs to submit to the APNS servers
 * when it sends a notification to a device. The APNS servers require a binary format for performance reasons.
 * The size of a device token is 32 bytes.
 */
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;

/**
 * Sent to the delegate when Apple Push Service cannot successfully complete the registration process.
 *
 * @param application The application that initiated the remote-notification registration process.
 * @param error An NSError object that encapsulates information why registration did not succeed. The application can
 * display this information to the user.
 */
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;

/**
 * Tells the app that a remote notification arrived that indicates there is data to be fetched.
 * Workaroud for iOS 10 bug. See https://forums.developer.apple.com/thread/54332
 *
 * @param application The singleton app object.
 * @param userInfo A dictionary that contains information related to the remote notification, potentially including a
 * badge number for the app icon, an alert sound, an alert message to display to the user, a notification identifier,
 * and custom data. The provider originates it as a JSON-defined dictionary that iOS converts to an @see NSDictionary
 * object; the dictionary may contain only property-list objects plus @see NSNull.
 */
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo;

/**
 * Tells the app that a remote notification arrived that indicates there is data to be fetched.
 *
 * @param application The singleton app object.
 * @param userInfo A dictionary that contains information related to the remote notification, potentially including a
 * badge number for the app icon, an alert sound, an alert message to display to the user, a notification identifier,
 * and custom data. The provider originates it as a JSON-defined dictionary that iOS converts to an @see NSDictionary
 * object; the dictionary may contain only property-list objects plus @see NSNull.
 * @param completionHandler The block to execute when the download operation is complete. When calling this block, pass
 * in the fetch result value that best describes the results of your download operation. You must call this handler and
 * should do so as soon as possible. For a list of possible values, see the @see UIBackgroundFetchResult type.
 */
- (void)application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;

@end

NS_ASSUME_NONNULL_END
