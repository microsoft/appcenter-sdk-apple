#import <MSAL/MSALPublicClientApplication.h>

#import "MSChannelDelegate.h"
#import "MSCustomApplicationDelegate.h"
#import "MSIdentity.h"
#import "MSIdentityConfig.h"
#import "MSIdentityConfigIngestion.h"
#import "MSServiceInternal.h"

NS_ASSUME_NONNULL_BEGIN

// The eTag key to store the eTag of current configuration.
static NSString *const kMSIdentityETagKey = @"MSIdentityETagKey";

// The key for Identity auth token stored in keychain.
static NSString *const kMSIdentityAuthTokenKey = @"MSIdentityAuthToken";

// The key for the MSALAccount homeAccountId stored in user defaults.
static NSString *const kMSIdentityMSALAccountHomeAccountKey = @"MSIdentityMSALAccountHomeAccount";

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
 * Ingestion instance (should not be deallocated).
 */
@property(nonatomic, nullable) MSIdentityConfigIngestion *ingestion;

/**
 * Custom application delegate dedicated to Identity.
 */
@property(nonatomic) id<MSCustomApplicationDelegate> appDelegate;

/**
 * Completion handler for sign-in.
 */
@property(atomic, nullable) MSSignInCompletionHandler signInCompletionHandler;

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

/**
 * Retrieve an updated token without user interaction.
 *
 * @param account The MSALAccount that is used to retrieve an authentication token.
 */
- (void)acquireTokenSilentlyWithMSALAccount:(MSALAccount *)account;

/**
 * Retrieve an updated token with user interaction.
 */
- (void)acquireTokenInteractively;

@end

NS_ASSUME_NONNULL_END
