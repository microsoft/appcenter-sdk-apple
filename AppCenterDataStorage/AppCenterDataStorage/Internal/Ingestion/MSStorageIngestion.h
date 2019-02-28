#import <Foundation/Foundation.h>
#import "MSHttpIngestion.h"

NS_ASSUME_NONNULL_BEGIN

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
 *
 * @return An ingestion instance.
 */
- (id)initWithBaseUrl:(nullable NSString *)baseUrl
            appSecret:(NSString *)appSecret;

@end

NS_ASSUME_NONNULL_END
