#import <Foundation/Foundation.h>

#import "MSChannelDelegate.h"

/**
 * One Collector channel delegate used to redirect selected traffic to One Collector.
 */
@interface MSOneCollectorChannelDelegate : NSObject <MSChannelDelegate>

/**
 * Init a `MSOneCollectorChannelDelegate` with an install Id.
 *
 * @param installId A device install Id.
 *
 * @return A `MSOneCollectorChannelDelegate` instance.
 */
- (instancetype)initWithInstallId:(NSUUID *)installId oneCollectorBaseUrl:(NSString *)baseUrl;

/**
 * Change the base URL (schema + authority + port only) used to communicate with the backend.
 *
 * @param logUrl base URL to use for backend communication.
 */
- (void)setLogUrl:(NSString *)logUrl;

@end
