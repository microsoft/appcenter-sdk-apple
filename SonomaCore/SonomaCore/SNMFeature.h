/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

/**
 *  Protocol declaring features logic.
 */
@protocol SNMFeature <NSObject>

/**
 *  Enable/disable this feature.
 *
 *  @param isEnabled whether this feature is enabled or not.
 *  @see isEnabled
 */
+ (void)setEnabled:(BOOL)isEnabled;

/**
 *  Is this feature enabled.
 *
 *  @return a boolean whether this feature is enabled or not.
 *  @see setEnabled:
 */
+ (BOOL)isEnabled;

@end
