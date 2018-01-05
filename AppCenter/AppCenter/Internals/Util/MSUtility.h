#import <Foundation/Foundation.h>

#import "MSUserDefaults.h"

#define MS_USER_DEFAULTS [MSUserDefaults shared]
#define MS_NOTIFICATION_CENTER [NSNotificationCenter defaultCenter]
#define MS_UUID_STRING [[NSUUID UUID] UUIDString]
#define MS_UUID_FROM_STRING(uuidString) [[NSUUID alloc] initWithUUIDString:uuidString]
#define MS_LOCALE [NSLocale currentLocale]
#define MS_CLASS_NAME_WITHOUT_PREFIX [NSStringFromClass([self class]) substringFromIndex:2]
#define MS_IS_APP_EXTENSION ([[[NSBundle mainBundle] executablePath] rangeOfString:@".appex/"].length > 0)
#define MS_APP_MAIN_BUNDLE [NSBundle mainBundle]

/**
 * Utility class that is used throughout the SDK.
 * Basic part.
 */
@interface MSUtility : NSObject

/**
 * Get the name of AppCenter SDK.
 */
+ (NSString *)sdkName;

/**
 * Get the current version of AppCenter SDK.
 */
+ (NSString *)sdkVersion;

@end
