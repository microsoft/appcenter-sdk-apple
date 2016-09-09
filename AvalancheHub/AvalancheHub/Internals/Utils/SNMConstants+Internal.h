/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#ifndef SNMConstants_Internal_h
#define SNMConstants_Internal_h
#import <Foundation/Foundation.h>

// Device manufacturer
static NSString *const kSNMDeviceManufacturer = @"Apple";

// API Error
static NSString *const kSNMDefaultApiErrorDomain = @"SNMDefaultApiErrorDomain";
static NSInteger const kSNMDefaultApiMissingParamErrorCode = 234513;
static NSInteger const kSNMHttpErrorCodeMissingParameter = 422;

typedef NS_ENUM(NSInteger, SNMPriority) { SNMPriorityDefault, SNMPriorityHigh, SNMPriorityBackground };

typedef NS_ENUM(NSInteger, SNMHTTPCodesNo) {
  // Informational
  SNMHTTPCodesNo1XXInformationalUnknown = 1,
  SNMHTTPCodesNo100Continue = 100,
  SNMHTTPCodesNo101SwitchingProtocols = 101,
  SNMHTTPCodesNo102Processing = 102,

  // Success
  SNMHTTPCodesNo2XXSuccessUnknown = 2,
  SNMHTTPCodesNo200OK = 200,
  SNMHTTPCodesNo201Created = 201,
  SNMHTTPCodesNo202Accepted = 202,
  SNMHTTPCodesNo203NonAuthoritativeInformation = 203,
  SNMHTTPCodesNo204NoContent = 204,
  SNMHTTPCodesNo205ResetContent = 205,
  SNMHTTPCodesNo206PartialContent = 206,
  SNMHTTPCodesNo207MultiStatus = 207,
  SNMHTTPCodesNo208AlreadyReported = 208,
  SNMHTTPCodesNo209IMUsed = 209,

  // Redirection
  SNMHTTPCodesNo3XXSuccessUnknown = 3,
  SNMHTTPCodesNo300MultipleChoices = 300,
  SNMHTTPCodesNo301MovedPermanently = 301,
  SNMHTTPCodesNo302Found = 302,
  SNMHTTPCodesNo303SeeOther = 303,
  SNMHTTPCodesNo304NotModified = 304,
  SNMHTTPCodesNo305UseProxy = 305,
  SNMHTTPCodesNo306SwitchProxy = 306,
  SNMHTTPCodesNo307TemporaryRedirect = 307,
  SNMHTTPCodesNo308PermanentRedirect = 308,

  // Client error
  SNMHTTPCodesNo4XXSuccessUnknown = 4,
  SNMHTTPCodesNo400BadRequest = 400,
  SNMHTTPCodesNo401Unauthorised = 401,
  SNMHTTPCodesNo402PaymentRequired = 402,
  SNMHTTPCodesNo403Forbidden = 403,
  SNMHTTPCodesNo404NotFound = 404,
  SNMHTTPCodesNo405MethodNotAllowed = 405,
  SNMHTTPCodesNo406NotAcceptable = 406,
  SNMHTTPCodesNo407ProxyAuthenticationRequired = 407,
  SNMHTTPCodesNo408RequestTimeout = 408,
  SNMHTTPCodesNo409Conflict = 409,
  SNMHTTPCodesNo410Gone = 410,
  SNMHTTPCodesNo411LengthRequired = 411,
  SNMHTTPCodesNo412PreconditionFailed = 412,
  SNMHTTPCodesNo413RequestEntityTooLarge = 413,
  SNMHTTPCodesNo414RequestURITooLong = 414,
  SNMHTTPCodesNo415UnsupportedMediaType = 415,
  SNMHTTPCodesNo416RequestedRangeNotSatisfiable = 416,
  SNMHTTPCodesNo417ExpectationFailed = 417,
  SNMHTTPCodesNo418IamATeapot = 418,
  SNMHTTPCodesNo419AuthenticationTimeout = 419,
  SNMHTTPCodesNo420MethodFailureSpringFramework = 420,
  SNMHTTPCodesNo420EnhanceYourCalmTwitter = 4200,
  SNMHTTPCodesNo422UnprocessableEntity = 422,
  SNMHTTPCodesNo423Locked = 423,
  SNMHTTPCodesNo424FailedDependency = 424,
  SNMHTTPCodesNo424MethodFailureWebDaw = 4240,
  SNMHTTPCodesNo425UnorderedCollection = 425,
  SNMHTTPCodesNo426UpgradeRequired = 426,
  SNMHTTPCodesNo428PreconditionRequired = 428,
  SNMHTTPCodesNo429TooManyRequests = 429,
  SNMHTTPCodesNo431RequestHeaderFieldsTooLarge = 431,
  SNMHTTPCodesNo444NoResponseNginx = 444,
  SNMHTTPCodesNo449RetryWithMicrosoft = 449,
  SNMHTTPCodesNo450BlockedByWindowsParentalControls = 450,
  SNMHTTPCodesNo451RedirectMicrosoft = 451,
  SNMHTTPCodesNo451UnSNMilableForLegalReasons = 4510,
  SNMHTTPCodesNo494RequestHeaderTooLargeNginx = 494,
  SNMHTTPCodesNo495CertErrorNginx = 495,
  SNMHTTPCodesNo496NoCertNginx = 496,
  SNMHTTPCodesNo497HTTPToHTTPSNginx = 497,
  SNMHTTPCodesNo499ClientClosedRequestNginx = 499,

  // Server error
  SNMHTTPCodesNo5XXSuccessUnknown = 5,
  SNMHTTPCodesNo500InternalServerError = 500,
  SNMHTTPCodesNo501NotImplemented = 501,
  SNMHTTPCodesNo502BadGateway = 502,
  SNMHTTPCodesNo503ServiceUnSNMilable = 503,
  SNMHTTPCodesNo504GatewayTimeout = 504,
  SNMHTTPCodesNo505HTTPVersionNotSupported = 505,
  SNMHTTPCodesNo506VariantAlsoNegotiates = 506,
  SNMHTTPCodesNo507InsufficientStorage = 507,
  SNMHTTPCodesNo508LoopDetected = 508,
  SNMHTTPCodesNo509BandwidthLimitExceeded = 509,
  SNMHTTPCodesNo510NotExtended = 510,
  SNMHTTPCodesNo511NetworkAuthenticationRequired = 511,
  SNMHTTPCodesNo522ConnectionTimedOut = 522,
  SNMHTTPCodesNo598NetworkReadTimeoutErrorUnknown = 598,
  SNMHTTPCodesNo599NetworkConnectTimeoutErrorUnknown = 599
};

#endif /* SNMConstants_Internal_h */
