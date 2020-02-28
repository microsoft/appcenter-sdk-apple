// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

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
static NSString *const kMSRetryHeaderKey = @"x-ms-retry-after-ms";

// Token obfuscation.
static NSString *const kMSTokenKeyValuePattern = @"\"token\"\\s*:\\s*\"[^\"]+\"";
static NSString *const kMSTokenKeyValueObfuscatedTemplate = @"\"token\" : \"***\"";

// Redirect URI obfuscation.
static NSString *const kMSRedirectUriPattern = @"\"redirect_uri\"\\s*:\\s*\"[^\"]+\"";
static NSString *const kMSRedirectUriObfuscatedTemplate = @"\"redirect_uri\" : \"***\"";

// Info.plist key names.
static NSString *const kMSCFBundleURLTypes = @"CFBundleURLTypes";
static NSString *const kMSCFBundleURLSchemes = @"CFBundleURLSchemes";
static NSString *const kMSCFBundleTypeRole = @"CFBundleTypeRole";

// Other HTTP constants.
static short const kMSHTTPMinGZipLength = 1400;

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

/**
 * Default flush interval for channel.
 */
static NSUInteger const kMSFlushIntervalDefault = 3;
