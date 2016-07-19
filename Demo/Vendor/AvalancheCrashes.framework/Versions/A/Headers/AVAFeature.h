/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@protocol AVAFeature<NSObject>

+ (void)setEnable:(BOOL)isEnabled;
+ (BOOL)isEnabled;

@end
