#import "MSHttpSender.h"

@interface MSOneCollectorIngestion : MSHttpSender

/**
 * Initialize the Sender.
 *
 * @param baseUrl Base url.
 *
 * @return A sender instance.
 */
- (id)initWithBaseUrl:(NSString *)baseUrl;

@end
