/**
 * The path component of Identity for configuration.
 */
static NSString *const kMSIdentityPathComponent = @"identity";

/**
 * Config URL format. Variables are base URL then appSecret.
 */
static NSString *const kMSIdentityConfigFilename = @"%@/identity/%@.json";

/**
 * Default base URL for remote configuration.
 */
static NSString *const kMSIdentityDefaultBaseUrl = @"https://config.appcenter.ms";

/**
 *The eTag key to store the eTag of current configuration.
 */
static NSString *const kMSIdentityETagKey = @"MSIdentityETagKey";

/**
 *The key for Identity auth token stored in keychain.
 */
static NSString *const kMSIdentityAuthTokenKey = @"MSIdentityAuthToken";

/**
 *The key for the MSALAccount homeAccountId stored in user defaults.
 */
static NSString *const kMSIdentityMSALAccountHomeAccountKey = @"MSIdentityMSALAccountHomeAccount";

