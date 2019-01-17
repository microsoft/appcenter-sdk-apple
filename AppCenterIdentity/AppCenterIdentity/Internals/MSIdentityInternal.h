#import "MSChannelDelegate.h"
#import "MSServiceInternal.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSIdentity () <MSServiceInternal, MSChannelDelegate>

+ (void)resetSharedInstance;

@end

NS_ASSUME_NONNULL_END
