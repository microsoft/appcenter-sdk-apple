/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@protocol AVAFeature<NSObject>

+ (void)enable;
+ (void)disable;
+ (BOOL)isEnabled;

@end
