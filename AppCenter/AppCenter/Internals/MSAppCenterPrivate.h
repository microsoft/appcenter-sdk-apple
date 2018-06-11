#import "MSAppCenter.h"
#import "MSChannelUnitProtocol.h"
#import "MSOneCollectorChannelDelegate.h"

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
 * @discussion This may be called only once per application process lifetime.
 * @param appSecret A unique and secret key used to identify the application.
 */
// FIXME: Rename to configureWithAppSecret
- (BOOL)configure:(NSString *)appSecret;

@end
