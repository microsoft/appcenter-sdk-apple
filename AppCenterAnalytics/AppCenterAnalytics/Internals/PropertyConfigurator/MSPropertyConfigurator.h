#import <Foundation/Foundation.h>

#import "MSChannelDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSPropertyConfigurator : NSObject <MSChannelDelegate>

/**
 * Override the application version.
 *
 * @param appVersion New application version for a tranmission target.
 */
- (void)setAppVersion:(NSString *)appVersion;

/**
 * Override the application name.
 *
 * @param appName New application name for a tranmission target.
 */
- (void)setAppName:(NSString *)appName;

/**
 * Override the application locale.
 *
 * @param appLocale New application locale for a tranmission target.
 */
- (void)setAppLocale:(NSString *)appLocale;

NS_ASSUME_NONNULL_END

@end
