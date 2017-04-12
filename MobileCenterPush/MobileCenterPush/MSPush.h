#import <UIKit/UIKit.h>
#import "MSServiceAbstract.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Mobile Center push service.
 */
@interface MSPush : MSServiceAbstract

/**
 * Callback for successful registration with push token
 *
 * @param pushToken The push token for remote notifications
 */
+ (void)didRegisterForRemoteNotificationsWith:(NSData *)pushToken;

/**
 * Callback for unsuccessful registration with error
 *
 * @param error Error of unsuccessful registration
 */
+ (void)didFailToRegisterForRemoteNotificationsWith:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
