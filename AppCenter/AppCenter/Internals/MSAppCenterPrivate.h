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
 * @param secretString A unique and secret key used to identify the application.
 * @param fromApplication A flag indicating that the sdk is configured from an application.
 *
 * @return `YES` if configured successfully, otherwise `NO`.
 */
- (BOOL)configureWithSecretString:(NSString *)secretString fromApplication:(BOOL)fromApplication;

@end
