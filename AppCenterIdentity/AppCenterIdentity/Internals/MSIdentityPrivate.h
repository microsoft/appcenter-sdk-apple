#import "MSChannelDelegate.h"
#import "MSIdentity.h"
#import "MSIdentityConfig.h"
#import "MSServiceInternal.h"

NS_ASSUME_NONNULL_BEGIN

// The eTag key to store the eTag of current configuration.
static NSString *const kMSIdentityETagKey = @"MSIdentityETagKey";

@class MSALPublicClientApplication;

@interface MSIdentity () <MSServiceInternal, MSChannelDelegate>

@property(nonatomic, nullable) MSALPublicClientApplication *clientApplication;

@property(nonatomic, nullable) NSString *accessToken;

@property(nonatomic, nullable) MSIdentityConfig *identityConfig;

@property(nonatomic) BOOL loginDelayed;

+ (void)resetSharedInstance;

- (NSString *)identityConfigFilePath;

- (void)downloadConfigurationWithETag:(nullable NSString *)eTag;

- (BOOL)loadConfigurationFromCache;

- (void)configAuthenticationClient;

@end

NS_ASSUME_NONNULL_END
