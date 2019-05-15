// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <CommonCrypto/CommonCryptor.h>
#import <Foundation/Foundation.h>

// Device manufacturer
static NSString *const kMSDeviceManufacturer = @"Apple";

// HTTP method names.
static NSString *const kMSHttpMethodGet = @"GET";
static NSString *const kMSHttpMethodPost = @"POST";
static NSString *const kMSHttpMethodDelete = @"DELETE";

// HTTP Headers + Query string.
static NSString *const kMSHeaderAppSecretKey = @"App-Secret";
static NSString *const kMSHeaderInstallIDKey = @"Install-ID";
static NSString *const kMSHeaderContentTypeKey = @"Content-Type";
static NSString *const kMSAppCenterContentType = @"application/json";
static NSString *const kMSHeaderContentEncodingKey = @"Content-Encoding";
static NSString *const kMSHeaderContentEncoding = @"gzip";
static NSString *const kMSAuthorizationHeaderKey = @"Authorization";
static NSString *const kMSRetryHeaderKey = @"x-ms-retry-after-ms";

// Token obfuscation.
static NSString *const kMSTokenKeyValuePattern = @"\"token\" : \"[^\"]+\"";
static NSString *const kMSTokenKeyValueObfuscatedTemplate = @"\"token\" : \"***\"";

/**
 * The key for auth token history array stored in keychain.
 */
static NSString *const kMSAuthTokenHistoryKey = @"MSAppCenterAuthTokenHistory";

/**
 * Maximum amount of available token stored in the keychain.
 */
static int const kMSMaxAuthTokenArraySize = 5;

// Other HTTP constants.
static short const kMSHTTPMinGZipLength = 1400;
static NSString *const kMSBearerTokenHeaderFormat = @"Bearer %@";

/**
 * Enum indicating result of a MSIngestionCall.
 */
typedef NS_ENUM(NSInteger, MSIngestionCallResult) {
  MSIngestionCallResultSuccess = 100,
  MSIngestionCallResultRecoverableError = 500,
  MSIngestionCallResultFatalError = 999
};

/**
 * Constants for maximum number and length of log properties.
 */
/**
 * Maximum properties per log.
 */
static const int kMSMaxPropertiesPerLog = 20;

/**
 * Minimum properties key length.
 */
static const int kMSMinPropertyKeyLength = 1;

/**
 * Maximum properties key length.
 */
static const int kMSMaxPropertyKeyLength = 125;

/**
 * Maximum properties value length.
 */
static const int kMSMaxPropertyValueLength = 125;

/**
 * Maximum allowable size of a common schema log in bytes.
 */
static const long kMSMaximumCommonSchemaLogSizeInBytes = 2 * 1024 * 1024;

/**
 * Suffix for One Collector group ID.
 */
static NSString *const kMSOneCollectorGroupIdSuffix = @"/one";

/**
 * Bit mask for persistence flags.
 */
static const NSUInteger kMSPersistenceFlagsMask = 0xFF;

/**
 * Common schema prefix separator used in various field values.
 */
static NSString *const kMSCommonSchemaPrefixSeparator = @":";

// Encryption constants.
static int const kMSEncryptionAlgorithm = kCCAlgorithmAES;
static NSString *const kMSEncryptionAlgorithmName = @"AES";
static NSString *const kMSEncryptionCipherMode = @"CBC";

// One year.
static NSTimeInterval const kMSEncryptionKeyLifetimeInSeconds = 365 * 24 * 60 * 60;
static int const kMSEncryptionKeySize = kCCKeySizeAES256;
static NSString *const kMSEncryptionKeyMetadataKey = @"MSEncryptionKeyMetadata";
static NSString *const kMSEncryptionKeyTagAlternate = @"kMSEncryptionKeyTagAlternate";
static NSString *const kMSEncryptionKeyTagOriginal = @"kMSEncryptionKeyTag";

// This separator is used for key metadata, as well as between metadata that is prepended to the cipher text.
static NSString *const kMSEncryptionMetadataInternalSeparator = @"/";

// This separator is only used between the metadata and cipher text of the encryption result.
static NSString *const kMSEncryptionMetadataSeparator = @":";
static NSString *const kMSEncryptionPaddingMode = @"PKCS7";
