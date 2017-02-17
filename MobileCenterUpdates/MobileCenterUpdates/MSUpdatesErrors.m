#import "MSUpdatesErrors.h"

#define MS_UPDATES_BASE_DOMAIN @"com.Microsoft.Azure.Mobile.MobileCenterUpdates."

#pragma mark - Domain

NSString *const kMSUDErrorDomain = MS_UPDATES_BASE_DOMAIN @"ErrorDomain";

#pragma mark - Update API token

// Error descriptions
NSString const *kMSUDUpdateTokenURLInvalidErrorDesc = @"Invalid update API token URL:";
NSString const *kMSUDUpdateTokenSchemeNotFoundErrorDesc = @"Custom URL scheme for updates not found.";
