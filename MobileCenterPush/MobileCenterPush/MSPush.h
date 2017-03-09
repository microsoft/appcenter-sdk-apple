#import <UIKit/UIKit.h>
#import "MSServiceAbstract.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Mobile Center push service.
 */
@interface MSPush : MSServiceAbstract

/**
 * Callback for successful registration with device token
 *
 * @param deviceToken The device token for remote notifications
 */
+ (void)didRegisterForRemoteNotificationsWith:(NSData *)deviceToken;

/**
 * Callback for unsuccessful registration with error
 *
 * @param error Error of unsuccessful registration
 */
+ (void)didFailToRegisterForRemoteNotificationsWith:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
