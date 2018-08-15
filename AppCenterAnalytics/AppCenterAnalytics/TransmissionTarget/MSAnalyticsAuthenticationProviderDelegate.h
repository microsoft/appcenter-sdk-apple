#import <Foundation/Foundation.h>

/**
 * Completion handler that returns the authentication token.
 */
typedef void (^MSAnalyticsAuthenticationProviderCompletionBlock)(NSString *token, NSDate *expiryDate);

@protocol MSAnalyticsAuthenticationProviderDelegate <NSObject>

- (void)acquireTokenWithCompletionHandler:(MSAnalyticsAuthenticationProviderCompletionBlock)completionHandler;

@end
