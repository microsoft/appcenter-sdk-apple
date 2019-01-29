#import "MSChannelDelegate.h"
#import "MSIdentity.h"
#import "MSIdentityConfig.h"
#import "MSServiceInternal.h"

@class MSALPublicClientApplication;

NS_ASSUME_NONNULL_BEGIN

@interface MSIdentity () <MSServiceInternal, MSChannelDelegate>

@property(nonatomic, nullable) MSALPublicClientApplication *clientApplication;

@property(nonatomic, nullable) NSString *accessToken;

@property(nonatomic, nullable) MSIdentityConfig *identityConfig;

@property(nonatomic) BOOL loginDelayed;

+ (void)resetSharedInstance;

@end

NS_ASSUME_NONNULL_END
