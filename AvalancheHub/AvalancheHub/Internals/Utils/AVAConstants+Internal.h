/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#ifndef AVAConstants_Internal_h
#define AVAConstants_Internal_h

// API Error
static NSString* const kAVADefaultApiErrorDomain = @"AVADefaultApiErrorDomain";
static NSInteger const kAVADefaultApiMissingParamErrorCode = 234513;
static NSInteger const kAVAHttpErrorCodeMissingParameter = 422;



typedef NS_ENUM(NSInteger, AVASendPriority) {
  AVASendPriorityDefault,
  AVASendPriorityHight,
  AVASendPriorityBackground
};


typedef NS_ENUM(NSInteger, AVAHTTPCodesNo) {
  // Informational
  AVAHTTPCodesNo1XXInformationalUnknown = 1,
  AVAHTTPCodesNo100Continue = 100,
  AVAHTTPCodesNo101SwitchingProtocols = 101,
  AVAHTTPCodesNo102Processing = 102,
  
  // Success
  AVAHTTPCodesNo2XXSuccessUnknown = 2,
  AVAHTTPCodesNo200OK = 200,
  AVAHTTPCodesNo201Created = 201,
  AVAHTTPCodesNo202Accepted = 202,
  AVAHTTPCodesNo203NonAuthoritativeInformation = 203,
  AVAHTTPCodesNo204NoContent = 204,
  AVAHTTPCodesNo205ResetContent = 205,
  AVAHTTPCodesNo206PartialContent = 206,
  AVAHTTPCodesNo207MultiStatus = 207,
  AVAHTTPCodesNo208AlreadyReported = 208,
  AVAHTTPCodesNo209IMUsed = 209,
  
  // Redirection
  AVAHTTPCodesNo3XXSuccessUnknown = 3,
  AVAHTTPCodesNo300MultipleChoices = 300,
  AVAHTTPCodesNo301MovedPermanently = 301,
  AVAHTTPCodesNo302Found = 302,
  AVAHTTPCodesNo303SeeOther = 303,
  AVAHTTPCodesNo304NotModified = 304,
  AVAHTTPCodesNo305UseProxy = 305,
  AVAHTTPCodesNo306SwitchProxy = 306,
  AVAHTTPCodesNo307TemporaryRedirect = 307,
  AVAHTTPCodesNo308PermanentRedirect = 308,
  
  // Client error
  AVAHTTPCodesNo4XXSuccessUnknown = 4,
  AVAHTTPCodesNo400BadRequest = 400,
  AVAHTTPCodesNo401Unauthorised = 401,
  AVAHTTPCodesNo402PaymentRequired = 402,
  AVAHTTPCodesNo403Forbidden = 403,
  AVAHTTPCodesNo404NotFound = 404,
  AVAHTTPCodesNo405MethodNotAllowed = 405,
  AVAHTTPCodesNo406NotAcceptable = 406,
  AVAHTTPCodesNo407ProxyAuthenticationRequired = 407,
  AVAHTTPCodesNo408RequestTimeout = 408,
  AVAHTTPCodesNo409Conflict = 409,
  AVAHTTPCodesNo410Gone = 410,
  AVAHTTPCodesNo411LengthRequired = 411,
  AVAHTTPCodesNo412PreconditionFailed = 412,
  AVAHTTPCodesNo413RequestEntityTooLarge = 413,
  AVAHTTPCodesNo414RequestURITooLong = 414,
  AVAHTTPCodesNo415UnsupportedMediaType = 415,
  AVAHTTPCodesNo416RequestedRangeNotSatisfiable = 416,
  AVAHTTPCodesNo417ExpectationFailed = 417,
  AVAHTTPCodesNo418IamATeapot = 418,
  AVAHTTPCodesNo419AuthenticationTimeout = 419,
  AVAHTTPCodesNo420MethodFailureSpringFramework = 420,
  AVAHTTPCodesNo420EnhanceYourCalmTwitter = 4200,
  AVAHTTPCodesNo422UnprocessableEntity = 422,
  AVAHTTPCodesNo423Locked = 423,
  AVAHTTPCodesNo424FailedDependency = 424,
  AVAHTTPCodesNo424MethodFailureWebDaw = 4240,
  AVAHTTPCodesNo425UnorderedCollection = 425,
  AVAHTTPCodesNo426UpgradeRequired = 426,
  AVAHTTPCodesNo428PreconditionRequired = 428,
  AVAHTTPCodesNo429TooManyRequests = 429,
  AVAHTTPCodesNo431RequestHeaderFieldsTooLarge = 431,
  AVAHTTPCodesNo444NoResponseNginx = 444,
  AVAHTTPCodesNo449RetryWithMicrosoft = 449,
  AVAHTTPCodesNo450BlockedByWindowsParentalControls = 450,
  AVAHTTPCodesNo451RedirectMicrosoft = 451,
  AVAHTTPCodesNo451UnavailableForLegalReasons = 4510,
  AVAHTTPCodesNo494RequestHeaderTooLargeNginx = 494,
  AVAHTTPCodesNo495CertErrorNginx = 495,
  AVAHTTPCodesNo496NoCertNginx = 496,
  AVAHTTPCodesNo497HTTPToHTTPSNginx = 497,
  AVAHTTPCodesNo499ClientClosedRequestNginx = 499,
  
  
  // Server error
  AVAHTTPCodesNo5XXSuccessUnknown = 5,
  AVAHTTPCodesNo500InternalServerError = 500,
  AVAHTTPCodesNo501NotImplemented = 501,
  AVAHTTPCodesNo502BadGateway = 502,
  AVAHTTPCodesNo503ServiceUnavailable = 503,
  AVAHTTPCodesNo504GatewayTimeout = 504,
  AVAHTTPCodesNo505HTTPVersionNotSupported = 505,
  AVAHTTPCodesNo506VariantAlsoNegotiates = 506,
  AVAHTTPCodesNo507InsufficientStorage = 507,
  AVAHTTPCodesNo508LoopDetected = 508,
  AVAHTTPCodesNo509BandwidthLimitExceeded = 509,
  AVAHTTPCodesNo510NotExtended = 510,
  AVAHTTPCodesNo511NetworkAuthenticationRequired = 511,
  AVAHTTPCodesNo522ConnectionTimedOut = 522,
  AVAHTTPCodesNo598NetworkReadTimeoutErrorUnknown = 598,
  AVAHTTPCodesNo599NetworkConnectTimeoutErrorUnknown = 599
};


#endif /* AVAConstants_Internal_h */