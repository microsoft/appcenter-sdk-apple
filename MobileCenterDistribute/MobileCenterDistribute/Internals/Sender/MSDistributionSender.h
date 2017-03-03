#import <Foundation/Foundation.h>
#import "MSHttpSender.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * The header name for update token.
 */
static NSString *const kMSHeaderUpdateApiToken = @"x-api-token";

@interface MSDistributionSender : MSHttpSender

/**
 * AppSecret for the application.
 */
@property(nonatomic) NSString *appSecret;

/**
 * Initialize the Sender.
 *
 * @param baseUrl Base url.
 * @param appSecret A unique and secret key used to identify the application.
 * @param updateToken The update token stored in keychain.
 *
 * @return A sender instance.
 */
- (id)initWithBaseUrl:(NSString *)baseUrl appSecret:(NSString *)appSecret updateToken:(NSString *)updateToken;

@end

NS_ASSUME_NONNULL_END
