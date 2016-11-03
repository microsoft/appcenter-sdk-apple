/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#ifndef MSUtils_h
#define MSUtils_h

#define mustOverride() NSAssert(NO, @"Method '%@' must be overriden in a subclass", NSStringFromSelector(_cmd))
#define kMSUserDefaults [MSUserDefaults shared]
#define kMSNotificationCenter [NSNotificationCenter defaultCenter]
#define kMSDevice [UIDevice currentDevice]
#define kMSApplication [UIApplication sharedApplication]
#define kMSUUIDString [[NSUUID UUID] UUIDString]
#define kMSUUIDFromString(uuidString) [[NSUUID alloc] initWithUUIDString:uuidString]
#define kMSLocale [NSLocale currentLocale]
#define CLASS_NAME_WITHOUT_PREFIX [NSStringFromClass([self class]) substringFromIndex:3]
#endif /* MSUtils_h */
