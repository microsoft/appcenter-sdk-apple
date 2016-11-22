/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#ifndef MSUtils_h
#define MSUtils_h

#define MS_USER_DEFAULTS [MSUserDefaults shared]
#define MS_NOTIFICATION_CENTER [NSNotificationCenter defaultCenter]
#define MS_DEVICE [UIDevice currentDevice]
#define MS_UUID_STRING [[NSUUID UUID] UUIDString]
#define MS_UUID_FROM_STRING(uuidString) [[NSUUID alloc] initWithUUIDString:uuidString]
#define MS_LOCALE [NSLocale currentLocale]
#define MS_CLASS_NAME_WITHOUT_PREFIX [NSStringFromClass([self class]) substringFromIndex:2]
#define MS_IS_APP_EXTENSION [[[NSBundle mainBundle] executablePath] containsString:@".appex/"]
#endif /* MSUtils_h */
