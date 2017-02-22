#import "MSServiceAbstract.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Mobile Center push service.
 */
@interface MSPush : MSServiceAbstract

/**
 * Register for remote notifications
 */
+ (void)registerForRemoteNotifications;

/**
 * Callback for succesfull registration with device token
 *
 * @param deviceToken The device token for remote notifications
 */
+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;

/**
 * Callback for unsuccesfull registration with error
 *
 * @param error Error of unsuccesfull registration
 */
+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
