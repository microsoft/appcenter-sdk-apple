/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#ifndef AVAUtils_h
#define AVAUtils_h

#define mustOverride() NSAssert(NO, @"Method '%@' must be overriden in a subclass", NSStringFromSelector(_cmd))
#define kAVAUserDefaults [AVAUserDefaults shared]
#define kAVANotificationCenter [NSNotificationCenter defaultCenter]
#define kAVADevice [UIDevice currentDevice]
#define kAVAApplication [UIApplication sharedApplication]
#define kAVAUUIDString [[NSUUID UUID] UUIDString]
#define kAVAUUIDFromString(uuidString) [[NSUUID alloc] initWithUUIDString:uuidString]
#define kAVALocale [NSLocale currentLocale]
#endif /* AVAUtils_h */
