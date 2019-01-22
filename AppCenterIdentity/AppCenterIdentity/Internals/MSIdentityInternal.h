#import "MSChannelDelegate.h"
#import "MSIdentity.h"
#import "MSServiceInternal.h"

@import MSAL;

NS_ASSUME_NONNULL_BEGIN

@interface MSIdentity () <MSServiceInternal, MSChannelDelegate>

@property(nonatomic, nullable) MSALPublicClientApplication *clientApplication;

@property(nonatomic, nullable) NSString *accessToken;

+ (void)resetSharedInstance;

@end

NS_ASSUME_NONNULL_END
