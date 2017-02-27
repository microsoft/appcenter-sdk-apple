#import "MSPush.h"
#import "MSServiceInternal.h"
#import "MSPushDelegate.h"
#import "MSChannelDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSPush () <MSServiceInternal, MSChannelDelegate>

+ (void)setDelegate:(nullable id <MSPushDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
