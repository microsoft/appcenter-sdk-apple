// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSAppCenterUserDefaults ()

/**
 * Returns an array of keys to be migrated.
 */
+ (NSDictionary *)keysToMigrate;

/**
 * Resets the shared instance of the class.
 */
+ (void)resetSharedInstance;

NS_ASSUME_NONNULL_END

@end
