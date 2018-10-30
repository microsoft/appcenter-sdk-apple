#import "MSCustomApplicationDelegate.h"
#import "MSDelegateForwarder.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const kMSAppDelegateForwarderEnabledKey = @"AppCenterAppDelegateForwarderEnabled";

@interface MSAppDelegateForwarder : MSDelegateForwarder <MSCustomApplicationDelegate>

@end

NS_ASSUME_NONNULL_END
