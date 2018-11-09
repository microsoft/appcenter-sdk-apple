#import "MSDelegateForwarder.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const kMSUserNotificationCenterDelegateForwarderEnabledKey = @"AppCenterUserNotificationCenterDelegateForwarderEnabled";

/**
 * The @c MSUserNotificationCenterDelegateForwarder is responsible for swizzling the @c UNUserNotificationCenterDelegate and forwarding
 * delegate calls to Push and customer implementation. The @c UNUserNotificationCenterDelegate is a push only delegate so the forwarder is
 * directly communicating with Push.
 */
@interface MSUserNotificationCenterDelegateForwarder : MSDelegateForwarder

/**
 * This is an empty method to be used to force load this class into the runtime.
 */
+(void)doNothingButForceLoadTheClass;

@end

NS_ASSUME_NONNULL_END
