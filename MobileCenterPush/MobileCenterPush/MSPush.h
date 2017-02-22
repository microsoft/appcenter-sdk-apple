#import "MSServiceAbstract.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Mobile Center analytics service.
 */
@interface MSPush : MSServiceAbstract

/**
 *  Register with push service.
 *
 */
+ (void)registerPush;

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
