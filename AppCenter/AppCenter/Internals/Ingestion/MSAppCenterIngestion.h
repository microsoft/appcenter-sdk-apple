#import <Foundation/Foundation.h>

#import "MSHttpIngestion.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSAppCenterIngestion : MSHttpIngestion

/**
 * Initialize the Sender.
 *
 * @param baseUrl Base url.
 * @param installId A unique installation identifier.
 *
 * @return A sender instance.
 */
- (id)initWithBaseUrl:(NSString *)baseUrl installId:(NSString *)installId;

@end

NS_ASSUME_NONNULL_END
