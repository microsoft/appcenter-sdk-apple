#import "MSChannelDelegate.h"
#import "MSServiceInternal.h"

@import MSAL;

NS_ASSUME_NONNULL_BEGIN

@interface MSIdentity () <MSServiceInternal, MSChannelDelegate>

@property(nonatomic, nullable) MSALPublicClientApplication *clientApplication;

@property(nonatomic, nullable) NSString *accessToken;

@end

NS_ASSUME_NONNULL_END
