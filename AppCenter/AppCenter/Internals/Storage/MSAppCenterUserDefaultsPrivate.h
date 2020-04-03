// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSAppCenterUserDefaults ()

/**
 * Returns an array of keys to be migrated.
 */
+ (NSDictionary<NSString *, NSString *> *)keysToMigrate;

/**
 * Migrates values for the old keys to new keys.
 * @param migratedKeys a dictionary for keys that contains new key as a key of dictionary and old key as a value.
 */
- (void)migrateKeys:(NSDictionary *)migratedKeys;

/**
 * Resets the shared instance of the class.
 */
+ (void)resetSharedInstance;

NS_ASSUME_NONNULL_END

@end
