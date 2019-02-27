#import <Foundation/Foundation.h>
#import "MSHttpIngestion.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * The header name for update token.
 */
static NSString *const kMSHeaderUpdateApiToken = @"x-api-token";

@interface MSStorageIngestion : MSHttpIngestion

/**
 * AppSecret for the application.
 */
@property(nonatomic) NSString *appSecret;


/**
 * Initialize the Ingestion.
 *
 * @param baseUrl Base url.
 * @param appSecret A unique and secret key used to identify the application.
 * distribution if it is nil.
 *
 * @return An ingestion instance.
 */
- (id)initWithBaseUrl:(nullable NSString *)baseUrl
            appSecret:(NSString *)appSecret;

@end

NS_ASSUME_NONNULL_END
