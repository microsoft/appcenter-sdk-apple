/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@protocol AVAFeature <NSObject>

/**
 *  Enable feature.
 *
 *  @param isEnabled is featured enabled or not.
 */
+ (void)setEnabled:(BOOL)isEnabled;

/**
 *  Is feature enabled.
 *
 *  @return is enabled
 */
+ (BOOL)isEnabled;

/**
 * Log an error in case the SDK hasn't been initialized properly.
 */
- (void)logSDKNotInitializedError;

@end
