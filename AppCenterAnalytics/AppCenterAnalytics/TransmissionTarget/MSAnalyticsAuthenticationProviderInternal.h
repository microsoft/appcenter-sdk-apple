#import <Foundation/Foundation.h>

#import "MSAnalyticsAuthenticationProvider.h"

@interface MSAnalyticsAuthenticationProvider()

/**
 * Request a new token from the app.
 */
- (void)acquireTokenAsync;

@end
