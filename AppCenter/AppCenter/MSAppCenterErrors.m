#import "MSAppCenterErrors.h"

#define MS_APP_CENTER_BASE_DOMAIN @"com.Microsoft.AppCenter."

#pragma mark - Domain

NSString *const kMSACErrorDomain = MS_APP_CENTER_BASE_DOMAIN @"ErrorDomain";

#pragma mark - Log

// Error descriptions
NSString const *kMSACLogInvalidContainerErrorDesc = @"Invalid log container";

#pragma mark - Connection

// Error descriptions
NSString const *kMSACConnectionHttpErrorDesc = @"An HTTP error occured.";
NSString const *kMSACConnectionPausedErrorDesc = @"Cancelled, connection paused with log deletion.";

// Error user info keys
NSString const *kMSACConnectionHttpCodeErrorKey = MS_APP_CENTER_BASE_DOMAIN "HttpCodeKey";
