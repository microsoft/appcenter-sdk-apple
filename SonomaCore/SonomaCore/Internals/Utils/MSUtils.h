/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#ifndef SNMUtils_h
#define SNMUtils_h

#define mustOverride() NSAssert(NO, @"Method '%@' must be overriden in a subclass", NSStringFromSelector(_cmd))
#define kMSUserDefaults [MSUserDefaults shared]
#define kMSNotificationCenter [NSNotificationCenter defaultCenter]
#define kSMDevice [UIDevice currentDevice]
#define kSNMApplication [UIApplication sharedApplication]
#define kSNMUUIDString [[NSUUID UUID] UUIDString]
#define kMSUUIDFromString(uuidString) [[NSUUID alloc] initWithUUIDString:uuidString]
#define kSMLocale [NSLocale currentLocale]
#define CLASS_NAME_WITHOUT_PREFIX [NSStringFromClass([self class]) substringFromIndex:3]
#endif /* SNMUtils_h */
