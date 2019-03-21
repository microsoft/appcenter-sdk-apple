// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

/**
 * The path component of the Identity configuration file on disk.
 */
static NSString *const kMSIdentityPathComponent = @"identity";

/**
 * Config URL format. Variable is app secret.
 */
static NSString *const kMSIdentityConfigApiFormat = @"/identity/%@.json";

/**
 * Default base URL for remote configuration.
 */
static NSString *const kMSIdentityDefaultBaseURL = @"https://config.appcenter.ms";

/**
 * Config filename on disk.
 */
static NSString *const kMSIdentityConfigFilename = @"config.json";

/**
 * The eTag key to store the eTag of current configuration.
 */
static NSString *const kMSIdentityETagKey = @"MSIdentityETagKey";

/**
 * The key for Identity auth token stored in keychain.
 */
static NSString *const kMSIdentityAuthTokenKey = @"MSIdentityAuthToken";

/**
 * The key for Identity auth token array stored in keychain.
 */
static NSString *const kMSIdentityAuthTokenArrayKey = @"MSIdentityAuthTokenArray";

/**
 * Maximum amount of available token stored in the keychain.
 */
static int const kMSIdentityMaxAuthTokenArraySize = 5;

/**
 * The key for the MSALAccount homeAccountId stored in user defaults.
 */
static NSString *const kMSIdentityMSALAccountHomeAccountKey = @"MSIdentityMSALAccountHomeAccount";
