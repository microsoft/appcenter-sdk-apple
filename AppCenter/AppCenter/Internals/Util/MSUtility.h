// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSAppCenterUserDefaults.h"

#if TARGET_OS_MACCATALYST
#define APP_CENTER_C_NAME "appcenter.maccatalyst"
#elif TARGET_OS_IOS
#define APP_CENTER_C_NAME "appcenter.ios"
#elif TARGET_OS_OSX
#define APP_CENTER_C_NAME "appcenter.macos"
#elif TARGET_OS_TV
#define APP_CENTER_C_NAME "appcenter.tvos"
#endif

#define MS_APP_CENTER_USER_DEFAULTS [MSAppCenterUserDefaults shared]
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

/**
 * Unarchive data.
 * 
 * @param data The data for unarchiving in NSData type.
 *
 * @return The unarchived data as an NSObject.
 */
+ (NSObject *)unarchiveKeyedData:(NSData *)data;

/**
 * Archive data.
 *
 * @param data The data for archiving.
 *
 * @return The archived data as an NSData.
 */
+ (NSData *)archiveKeyedData:(id)data;

@end
