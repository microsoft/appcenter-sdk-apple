#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#ifndef MSAppDelegate
#define MSAppDelegate MSNSAppDelegate
#define MSApplicationDelegate NSApplicationDelegate
#endif

NS_ASSUME_NONNULL_BEGIN

@class MSAppDelegateForwarder;

/**
 * Custom delegate matching `NSApplicationDelegate`.
 *
 * @discussion Delegates here are using swizzling. Any delegate that can be registered through the notification center
 * should not be registered through swizzling. Due to the early registration of swizzling on the original app delegate
 * each custom delegate must sign up for selectors to swizzle within the `load` method of a category over
 * the @see MSAppDelegateForwarder class.
 */
@protocol MSNSAppDelegate <NSObject>

@optional

/**
 * Tells the delegate that the app successfully registered with Apple Push Notification service (APNs).
 *
 * @param application The application that initiated the remote-notification registration process.
 * @param deviceToken A token that identifies the device to Apple Push Notification Service (APNS).
 * The token is an opaque data type because that is the form that the provider needs to submit to the APNS servers
 * when it sends a notification to a device. The APNS servers require a binary format for performance reasons.
 * The size of a device token is 32 bytes.
 */
- (void)application:(NSApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;

/**
 * Sent to the delegate when Apple Push Service cannot successfully complete the registration process.
 *
 * @param application The application that initiated the remote-notification registration process.
 * @param error An NSError object that encapsulates information why registration did not succeed. The application can
 * display this information to the user.
 */
- (void)application:(NSApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;

/**
 * Sent by the default notification center after the application has been launched and initialized but before it has
 * received its first event.
 *
 * @param notification A notification that caused the application launch.
 */
- (void)applicationDidFinishLaunching:(NSNotification *)notification;

@end

NS_ASSUME_NONNULL_END
