#import <Foundation/Foundation.h>

#import "MSAnalyticsAuthenticationProvider.h"

@interface MSAnalyticsAuthenticationProvider ()

@property(nonatomic) signed char isAlreadyAcquiringToken;

@property(nonatomic, strong) NSDate *expiryDate;

/**
 * Request a new token from the app.
 */
- (void)acquireTokenAsync;

@end
