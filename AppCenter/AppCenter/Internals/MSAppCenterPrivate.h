#import "MSAppCenter.h"
#import "MSChannelUnitProtocol.h"

@class MSOneCollectorChannelDelegate;

@interface MSAppCenter ()

@property(nonatomic) id<MSChannelUnitProtocol> channelUnit;
@property(nonatomic) MSOneCollectorChannelDelegate *oneCollectorChannelDelegate;

/**
 * Method to reset the singleton when running unit tests only. So calling sharedInstance returns a fresh instance.
 */
+ (void)resetSharedInstance;

/**
 * Configure the SDK.
 *
 * @param appSecret A unique and secret key used to identify the application for App Center ingestion.
 * @param transmissionTargetToken A unique and secret key used to identify the application for One Collector ingestion.
 * @param fromApplication A flag indicating that the sdk is configured from an application.
 *
 * @return `YES` if configured successfully, otherwise `NO`.
 */
- (BOOL)configureWithAppSecret:(NSString *)appSecret
       transmissionTargetToken:(NSString *)transmissionTargetToken
               fromApplication:(BOOL)fromApplication;

@end
