// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *const kMSUserDefaultsPrefix = @"MSAppCenter";

/**
 * Persistent settings, a wrapper around NSUserDefaults capable of updating object or dictionary (including expiration).
 */
@interface MSAppCenterUserDefaults : NSObject

/**
 * @return the shared settings.
 */
+ (instancetype)shared;

/**
 * Returns an array of keys to be migrated.
 */
+ (NSDictionary<NSString *, NSString *> *)keysToMigrate;

/**
 * Append an array of keys to migrated.
 */
+ (void)addKeysToMigrate:(NSDictionary<NSString *, NSString *> *)keys;

/**
 * Migrates values for the old keys to new keys.
 * @param migratedKeys a dictionary for keys that contains old key as a key of dictionary and new key as a value.
 */
- (void)migrateKeys:(NSDictionary *)migratedKeys;

/**
 * Get an object in the settings, returning object if key was found, nil otherwise.
 *
 * @param key a unique key to identify the value.
 */
- (nullable id)objectForKey:(NSString *)key;

/**
 * Sets the value of the specified key in the settings.
 *
 * @param value the object to set.
 * @param key a unique key to identify the value.
 */
- (void)setObject:(id)value forKey:(NSString *)key;

/**
 * Removes a value from the settings.
 *
 * @param key the key to remove.
 */
- (void)removeObjectForKey:(NSString *)key;

/**
 * Resets the shared instance of the class.
 */
+ (void)resetSharedInstance;

NS_ASSUME_NONNULL_END

@end
