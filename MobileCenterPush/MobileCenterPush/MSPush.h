#import <UIKit/UIKit.h>
#import "MSServiceAbstract.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Mobile Center push service.
 */
@interface MSPush : MSServiceAbstract

/**
 * Callback for successful registration with push token.
 *
 * @param deviceToken The device token for remote notifications.
 */
+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;

/**
 * Callback for unsuccessful registration with error.
 *
 * @param error Error of unsuccessful registration.
 */
+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
