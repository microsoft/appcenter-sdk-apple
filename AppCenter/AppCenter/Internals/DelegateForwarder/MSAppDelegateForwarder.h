#import "MSCustomApplicationDelegate.h"
#import "MSDelegateForwarder.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSAppDelegateForwarder : MSDelegateForwarder <MSCustomApplicationDelegate>

@end

NS_ASSUME_NONNULL_END
