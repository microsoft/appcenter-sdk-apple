#import "MSChannelDelegate.h"
#import "MSCustomApplicationDelegate.h"
#import "MSIdentity.h"
#import "MSIdentityConfig.h"
#import "MSServiceInternal.h"

NS_ASSUME_NONNULL_BEGIN

// The eTag key to store the eTag of current configuration.
static NSString *const kMSIdentityETagKey = @"MSIdentityETagKey";

// The key for Identity auth token stored in keychain.
static NSString *const kMSIdentityAuthTokenKey = @"MSIdentityAuthToken";

@class MSALPublicClientApplication;

@interface MSIdentity () <MSServiceInternal, MSChannelDelegate>

/**
 * The MSAL client for authentication.
 */
@property(nonatomic, nullable) MSALPublicClientApplication *clientApplication;

/**
 * The configuration for the Identity service.
 */
@property(nonatomic, nullable) MSIdentityConfig *identityConfig;

/**
 * The flag that indicates a user requested signIn before it is configured.
 */
@property(nonatomic) BOOL signInDelayed;

/**
 * Custom application delegate dedicated to Identity.
 */
@property(nonatomic) id<MSCustomApplicationDelegate> appDelegate;

/**
 * Rest singleton instance.
 */
+ (void)resetSharedInstance;

/**
 * Get a file path of identity config.
 *
 * @return The config file path.
 */
- (NSString *)identityConfigFilePath;

/**
 * Download identity configuration with an eTag.
 */
- (void)downloadConfigurationWithETag:(nullable NSString *)eTag;

/**
 * Load identity configuration from cache file.
 *
 * @return `YES` if the configuration loaded successfully, otherwise `NO`.
 */
- (BOOL)loadConfigurationFromCache;

/**
 * Config MSAL client.
 */
- (void)configAuthenticationClient;

@end

NS_ASSUME_NONNULL_END
