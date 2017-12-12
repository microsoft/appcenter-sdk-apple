#import <Foundation/Foundation.h>

#import "MSHttpSender.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSIngestionSender : MSHttpSender

/**
 * Initialize the Sender.
 *
 * @param baseUrl Base url.
 * @param appSecret A unique and secret key used to identify the application.
 * @param installId A unique installation identifier.
 *
 * @return A sender instance.
 */
- (id)initWithBaseUrl:(NSString *)baseUrl appSecret:(NSString *)appSecret installId:(NSString *)installId;

@end

NS_ASSUME_NONNULL_END
