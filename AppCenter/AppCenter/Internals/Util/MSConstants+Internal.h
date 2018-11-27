#import <Foundation/Foundation.h>

// Device manufacturer
static NSString *const kMSDeviceManufacturer = @"Apple";

// HTTP Headers + Query string.
static NSString *const kMSHeaderAppSecretKey = @"App-Secret";
static NSString *const kMSHeaderInstallIDKey = @"Install-ID";
static NSString *const kMSHeaderContentTypeKey = @"Content-Type";
static NSString *const kMSAppCenterContentType = @"application/json";
static NSString *const kMSHeaderContentEncodingKey = @"Content-Encoding";
static NSString *const kMSHeaderContentEncoding = @"gzip";

// HTTP constants.
static short const kMSHTTPMinGZipLength = 1400;

/**
 * Enum with the different HTTP status codes.
 */
typedef NS_ENUM(NSInteger, MSHTTPCodesNo) { // Informational
  MSHTTPCodesNo1XXInformationalUnknown = 1,
  MSHTTPCodesNo100Continue = 100,
  MSHTTPCodesNo101SwitchingProtocols = 101,
  MSHTTPCodesNo102Processing = 102,

  // Success
  MSHTTPCodesNo2XXSuccessUnknown = 2,
  MSHTTPCodesNo200OK = 200,
  MSHTTPCodesNo201Created = 201,
  MSHTTPCodesNo202Accepted = 202,
  MSHTTPCodesNo203NonAuthoritativeInformation = 203,
  MSHTTPCodesNo204NoContent = 204,
  MSHTTPCodesNo205ResetContent = 205,
  MSHTTPCodesNo206PartialContent = 206,
  MSHTTPCodesNo207MultiStatus = 207,
  MSHTTPCodesNo208AlreadyReported = 208,
  MSHTTPCodesNo209IMUsed = 209,

  // Redirection
  MSHTTPCodesNo3XXSuccessUnknown = 3,
  MSHTTPCodesNo300MultipleChoices = 300,
  MSHTTPCodesNo301MovedPermanently = 301,
  MSHTTPCodesNo302Found = 302,
  MSHTTPCodesNo303SeeOther = 303,
  MSHTTPCodesNo304NotModified = 304,
  MSHTTPCodesNo305UseProxy = 305,
  MSHTTPCodesNo306SwitchProxy = 306,
  MSHTTPCodesNo307TemporaryRedirect = 307,
  MSHTTPCodesNo308PermanentRedirect = 308,

  // Client error
  MSHTTPCodesNo4XXSuccessUnknown = 4,
  MSHTTPCodesNo400BadRequest = 400,
  MSHTTPCodesNo401Unauthorised = 401,
  MSHTTPCodesNo402PaymentRequired = 402,
  MSHTTPCodesNo403Forbidden = 403,
  MSHTTPCodesNo404NotFound = 404,
  MSHTTPCodesNo405MethodNotAllowed = 405,
  MSHTTPCodesNo406NotAcceptable = 406,
  MSHTTPCodesNo407ProxyAuthenticationRequired = 407,
  MSHTTPCodesNo408RequestTimeout = 408,
  MSHTTPCodesNo409Conflict = 409,
  MSHTTPCodesNo410Gone = 410,
  MSHTTPCodesNo411LengthRequired = 411,
  MSHTTPCodesNo412PreconditionFailed = 412,
  MSHTTPCodesNo413RequestEntityTooLarge = 413,
  MSHTTPCodesNo414RequestURITooLong = 414,
  MSHTTPCodesNo415UnsupportedMediaType = 415,
  MSHTTPCodesNo416RequestedRangeNotSatisfiable = 416,
  MSHTTPCodesNo417ExpectationFailed = 417,
  MSHTTPCodesNo418IamATeapot = 418,
  MSHTTPCodesNo419AuthenticationTimeout = 419,
  MSHTTPCodesNo420MethodFailureSpringFramework = 420,
  MSHTTPCodesNo420EnhanceYourCalmTwitter = 4200,
  MSHTTPCodesNo422UnprocessableEntity = 422,
  MSHTTPCodesNo423Locked = 423,
  MSHTTPCodesNo424FailedDependency = 424,
  MSHTTPCodesNo424MethodFailureWebDaw = 4240,
  MSHTTPCodesNo425UnorderedCollection = 425,
  MSHTTPCodesNo426UpgradeRequired = 426,
  MSHTTPCodesNo428PreconditionRequired = 428,
  MSHTTPCodesNo429TooManyRequests = 429,
  MSHTTPCodesNo431RequestHeaderFieldsTooLarge = 431,
  MSHTTPCodesNo444NoResponseNginx = 444,
  MSHTTPCodesNo449RetryWithMicrosoft = 449,
  MSHTTPCodesNo450BlockedByWindowsParentalControls = 450,
  MSHTTPCodesNo451RedirectMicrosoft = 451,
  MSHTTPCodesNo451UnavailableForLegalReasons = 4510,
  MSHTTPCodesNo494RequestHeaderTooLargeNginx = 494,
  MSHTTPCodesNo495CertErrorNginx = 495,
  MSHTTPCodesNo496NoCertNginx = 496,
  MSHTTPCodesNo497HTTPToHTTPSNginx = 497,
  MSHTTPCodesNo499ClientClosedRequestNginx = 499,

  // Server error
  MSHTTPCodesNo5XXSuccessUnknown = 5,
  MSHTTPCodesNo500InternalServerError = 500,
  MSHTTPCodesNo501NotImplemented = 501,
  MSHTTPCodesNo502BadGateway = 502,
  MSHTTPCodesNo503ServiceUnavailable = 503,
  MSHTTPCodesNo504GatewayTimeout = 504,
  MSHTTPCodesNo505HTTPVersionNotSupported = 505,
  MSHTTPCodesNo506VariantAlsoNegotiates = 506,
  MSHTTPCodesNo507InsufficientStorage = 507,
  MSHTTPCodesNo508LoopDetected = 508,
  MSHTTPCodesNo509BandwidthLimitExceeded = 509,
  MSHTTPCodesNo510NotExtended = 510,
  MSHTTPCodesNo511NetworkAuthenticationRequired = 511,
  MSHTTPCodesNo522ConnectionTimedOut = 522,
  MSHTTPCodesNo598NetworkReadTimeoutErrorUnknown = 598,
  MSHTTPCodesNo599NetworkConnectTimeoutErrorUnknown = 599
};

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
