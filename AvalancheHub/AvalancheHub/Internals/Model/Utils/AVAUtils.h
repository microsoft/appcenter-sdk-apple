/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#ifndef AVAUtils_h
#define AVAUtils_h

#define mustOverride() NSAssert(NO, @"Method '%@' must be overriden in a subclass", NSStringFromSelector(_cmd))
#define kAVAUserDefaults [NSUserDefaults standardUserDefaults]
#define kAVASettings [AVASettings shared]
#define kAVADevice [UIDevice currentDevice]
#define kAVAApplication [UIApplication sharedApplication]
#define kAVAUUID [NSUUID UUID]

#endif /* AVAUtils_h */
