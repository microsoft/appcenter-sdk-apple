#import <Foundation/Foundation.h>

#import "MSHttpIngestion.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSAppCenterIngestion : MSHttpIngestion

/**
 * The app secret.
 */
@property(nonatomic, copy) NSString *appSecret;

/**
 * Initialize the Ingestion.
 *
 * @param baseUrl Base url.
 * @param installId A unique installation identifier.
 *
 * @return An ingestion instance.
 */
- (id)initWithBaseUrl:(NSString *)baseUrl installId:(NSString *)installId;

@end

NS_ASSUME_NONNULL_END
