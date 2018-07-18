#import <Foundation/Foundation.h>

#import "MSChannelDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSPropertyConfigurator : NSObject <MSChannelDelegate>

/**
 * The application name to be overriden.
 *
 * @param appName The application name.
 */
- (void)setAppName:(NSString *)appName;

/**
 * The application version to be overriden.
 *
 * @param appVersion The application version.
 */
- (void)setAppVersion:(NSString *)appVersion;

/**
 * The application locale to be overriden.
 *
 * @param appLocale The application locale.
 */
- (void)setAppLocale:(NSString *)appLocale;

NS_ASSUME_NONNULL_END

@end
