/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@protocol AVAFeature <NSObject>

/**
 *  Enable feature
 *
 *  @param isEnabled is featured enabled or not
 */
+ (void)setEnable:(BOOL)isEnabled;

/**
 *  Is feature enabled
 *
 *  @return is enabled
 */
+ (BOOL)isEnabled;

@end
