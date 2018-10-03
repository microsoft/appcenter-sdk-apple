#import <Foundation/Foundation.h>

#import "MSHttpIngestion.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * The header name for update token.
 */
static NSString *const kMSHeaderUpdateApiToken = @"x-api-token";

@interface MSDistributeIngestion : MSHttpIngestion

/**
 * AppSecret for the application.
 */
@property(nonatomic) NSString *appSecret;

/**
 * Initialize the Ingestion.
 *
 * @param baseUrl Base url.
 * @param appSecret A unique and secret key used to identify the application.
 * @param updateToken The update token stored in keychain. This parameter is optional and the update will be considered as public
 * distribution if it is nil.
 * @param distributionGroupId The distribution group Id stored in storage.
 * @param queryStrings An array of query strings.
 *
 * @return An ingestion instance.
 */
- (id)initWithBaseUrl:(nullable NSString *)baseUrl
              appSecret:(NSString *)appSecret
            updateToken:(NSString *)updateToken
    distributionGroupId:(NSString *)distributionGroupId
           queryStrings:(NSDictionary *)queryStrings;

@end

NS_ASSUME_NONNULL_END
