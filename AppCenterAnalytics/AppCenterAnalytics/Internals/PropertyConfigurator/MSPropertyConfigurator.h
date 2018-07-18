#import <Foundation/Foundation.h>
#import "MSChannelDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSPropertyConfigurator : NSObject <MSChannelDelegate>

- (void)setAppName:(NSString *)appName;
- (void)setAppVersion:(NSString *)appVersion;
- (void)setAppLocale:(NSString *)appLocale;

NS_ASSUME_NONNULL_END

@end
