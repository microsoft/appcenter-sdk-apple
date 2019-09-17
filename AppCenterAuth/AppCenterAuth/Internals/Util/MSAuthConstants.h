// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

/**
 * The path component of the Auth configuration file on disk.
 */
static NSString *const kMSAuthPathComponent = @"auth";

/**
 * Config URL format. Variable is app secret.
 */
static NSString *const kMSAuthConfigApiFormat = @"/auth/%@.json";

/**
 * Default base URL for remote configuration.
 */
static NSString *const kMSAuthDefaultBaseURL = @"https://config.appcenter.ms";

/**
 * Config filename on disk.
 */
static NSString *const kMSAuthConfigFilename = @"config.json";

/**
 * The eTag key to store the eTag of current configuration.
 */
static NSString *const kMSAuthETagKey = @"MSAuthETagKey";

/**
 * B2C authority type
 */
static NSString *const kMSAuthorityTypeB2C = @"B2C";

/**
 * AAD authority type
 */
static NSString *const kMSAuthorityTypeAAD = @"AAD";
