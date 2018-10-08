#import "MSPush.h"
#import "MSPushDelegate.h"
#import "MSServiceInternal.h"

/**
 * Keys for payload in push notification.
 */
static NSString *const kMSPushNotificationApsKey = @"aps";
static NSString *const kMSPushNotificationAlertKey = @"alert";
static NSString *const kMSPushNotificationTitleKey = @"title";
static NSString *const kMSPushNotificationMessageKey = @"body";
static NSString *const kMSPushNotificationCustomDataKey = @"appCenter";

// TODO remove this one as soon as the push backend removes it.
static NSString *const kMSPushNotificationOldCustomDataKey = @"mobile_center";

@protocol MSCustomApplicationDelegate;

#if TARGET_OS_OSX
@interface MSPush () <NSUserNotificationCenterDelegate>
#else
@interface MSPush ()
#endif

@property(nonatomic) id<MSPushDelegate> delegate;

@property(nonatomic) NSString *pushToken;

#if TARGET_OS_OSX
@property(nonatomic) id<NSUserNotificationCenterDelegate> originalUserNotificationCenterDelegate;
#endif

/**
 * Custom application delegate dedicated to Push.
 */
@property(nonatomic) id<MSCustomApplicationDelegate> appDelegate;

/**
 * Method to reset the singleton when running unit tests only. So calling sharedInstance returns a fresh instance.
 */
+ (void)resetSharedInstance;

/**
 * Method generates MSPushLog log and send it.
 *
 * @param token The push token converted to NSString.
 */
- (void)sendPushToken:(NSString *)token;

/**
 * Method converts NSData to NSString.
 *
 * @param token The push token.
 */
- (NSString *)convertTokenToString:(NSData *)token;

/**
 * Method registers notification settings and an application for remote notifications.
 */
- (void)registerForRemoteNotifications;

#if TARGET_OS_OSX

/**
 * Method to return a context for observing delegate changes.
 */
+ (void *)userNotificationCenterDelegateContext;

/**
 * Observer to register user notification center delegate when application launches.
 */
- (void)applicationDidFinishLaunching:(NSNotification *)notification;

/**
 * Method that is called by NSUserNotificationCenter when its delegate changes.
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
#endif

@end
