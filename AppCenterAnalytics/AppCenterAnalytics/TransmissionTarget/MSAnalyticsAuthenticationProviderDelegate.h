#import <Foundation/Foundation.h>

#import "MSAnalyticsTransmissionTarget.h"

@class MSAnalyticsAuthenticationProvider;

/**
 * Completion handler that contains the authentication token.
 */
typedef void (^MSAcquireTokenCompletionHandler)(NSString *_Nullable token);

NS_ASSUME_NONNULL_BEGIN

@protocol MSAnalyticsAuthenticationProviderDelegate <NSObject>

@optional

//TODO To be decided which callback to use.

/**
 * Implement this method as part of you authentication flow.
 *
 * @param provider The authentication provider.
 * @param ticketKey The ticket key that you use to get a token from your
 * authentication/identity service/sdk.
 * @return the acquired authentication token.
 */
- (NSString *)authenticationProvider:(MSAnalyticsAuthenticationProvider *)provider
                         getTokenFor:(NSString *)ticketKey;

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
- (void)authenticationProvider:(MSAnalyticsAuthenticationProvider *)provider
                   getTokenFor:(NSString *)ticketKey
             completionHandler:(MSAcquireTokenCompletionHandler)handler;

@end

NS_ASSUME_NONNULL_END
