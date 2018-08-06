#import <Foundation/Foundation.h>

#import "MSAnalyticsTransmissionTarget.h"

@class MSAuthenticationProvider;

/**
 * Completion handler that contains the authentication token.
 */
typedef void (^MSAcquireTokenCompletionHandler)(NSString *_Nullable token);

@protocol MSTokenProvider <NSObject>

/**
 * Implement this method as part of your authentication flow and return your
 * authentication token inside the completion handler. None of it's parameters
 * can be nil.
 *
 * @param provider The authentication provider.
 * @param ticketKey The ticket key that you use to get a token from your
 * authentication/identity service/sdk.
 * @param handler The completion block to be called once the caller has acquired
 * an authentication token.
 */
- (void)authenticationProvider:(MSAuthenticationProvider *)provider
                   getTokenFor:(NSString *)ticketKey
             completionHandler:(MSAcquireTokenCompletionHandler)handler;

@end
