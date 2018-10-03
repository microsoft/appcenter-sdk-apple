#import <Foundation/Foundation.h>

#import "MSCustomApplicationDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MSCustomPushApplicationDelegate <MSCustomApplicationDelegate>

@optional

/**
 * Tells the delegate that the app successfully registered with Apple Push Notification service (APNs).
 *
 * @param application The application that initiated the remote-notification registration process.
 * @param deviceToken A token that identifies the device to Apple Push Notification Service (APNS). The token is an opaque data type because
 * that is the form that the provider needs to submit to the APNS servers when it sends a notification to a device. The APNS servers require
 * a binary format for performance reasons. The size of a device token is 32 bytes.
 */
- (void)application:(MSApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;

/**
 * Sent to the delegate when Apple Push Service cannot successfully complete the registration process.
 *
 * @param application The application that initiated the remote-notification registration process.
 * @param error An NSError object that encapsulates information why registration did not succeed. The application can display this
 * information to the user.
 */
- (void)application:(MSApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;

/**
 * Tells the app that a remote notification arrived that indicates there is data to be fetched. Used for macOS and as a workaround for iOS
 * 10 bug (See https://forums.developer.apple.com/thread/54332).
 *
 * @param application The singleton app object.
 * @param userInfo A dictionary that contains information related to the remote notification, potentially including a badge number for the
 * app icon, an alert sound, an alert message to display to the user, a notification identifier, and custom data. The provider originates it
 * as a JSON-defined dictionary that iOS converts to an @see NSDictionary object; the dictionary may contain only property-list objects plus
 * @see NSNull.
 */
- (void)application:(MSApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo;

#if !TARGET_OS_OSX

/**
 * Tells the app that a remote notification arrived that indicates there is data to be fetched.
 *
 * @param application The singleton app object.
 * @param userInfo A dictionary that contains information related to the remote notification, potentially including a badge number for the
 * app icon, an alert sound, an alert message to display to the user, a notification identifier, and custom data. The provider originates it
 * as a JSON-defined dictionary that iOS converts to an @see NSDictionary object; the dictionary may contain only property-list objects plus
 * @see NSNull.
 * @param completionHandler The block to execute when the download operation is complete. When calling this block, pass in the fetch result
 * value that best describes the results of your download operation. You must call this handler and should do so as soon as possible. For a
 * list of possible values, see the @see UIBackgroundFetchResult type.
 */
- (void)application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;

#endif

@end

NS_ASSUME_NONNULL_END
