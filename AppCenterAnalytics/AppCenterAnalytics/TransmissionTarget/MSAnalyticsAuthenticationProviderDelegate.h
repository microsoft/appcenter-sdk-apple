#import <Foundation/Foundation.h>

#import "MSAnalyticsTransmissionTarget.h"

@class MSAnalyticsAuthenticationProvider;

NS_ASSUME_NONNULL_BEGIN

@protocol MSAnalyticsAuthenticationProviderDelegate <NSObject>

//TODO To use delegate or callback method

/**
 * Implement this method as part of you authentication flow.
 *
 * @param provider The authentication provider.
 * @param ticketKey The ticket key that you use to get a token from your
 * authentication/identity service/sdk.
 * @return the acquired authentication token.
 */
- (NSString *)tokenWithAuthenticationProvider:(MSAnalyticsAuthenticationProvider *)provider
                         ticketKey:(NSString *)ticketKey;

@end

NS_ASSUME_NONNULL_END
