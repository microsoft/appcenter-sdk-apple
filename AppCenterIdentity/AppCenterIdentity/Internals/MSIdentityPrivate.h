#import "MSChannelDelegate.h"
#import "MSIdentity.h"
#import "MSIdentityConfig.h"
#import "MSServiceInternal.h"

// The eTag key to store the eTag of current configuration.
static NSString *const kMSIdentityETagKey = @"MSIdentityETagKey";

@class MSALPublicClientApplication;

NS_ASSUME_NONNULL_BEGIN

@interface MSIdentity () <MSServiceInternal, MSChannelDelegate>

@property(nonatomic, nullable) MSALPublicClientApplication *clientApplication;

@property(nonatomic, nullable) NSString *accessToken;

@property(nonatomic, nullable) MSIdentityConfig *identityConfig;

@property(nonatomic) BOOL loginDelayed;

+ (void)resetSharedInstance;

- (NSString *)identityConfigFilePath;

@end

NS_ASSUME_NONNULL_END
