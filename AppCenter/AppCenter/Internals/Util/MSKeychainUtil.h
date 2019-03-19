// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Utility class for Keychain.
 */
@interface MSKeychainUtil : NSObject

/**
 * Serialize and store mutable array as a string in a Keychain with given key.
 *
 * @param mutableArray An array of data to be placed in Keychain.
 * @param key A unique key for the data.
 *
 * @return YES if stored successfully, NO otherwise.
 */
+ (BOOL)storeArray:(NSMutableArray *)mutableArray forKey:(NSString *)key;

/**
 * Get a string with the given key from Keychain, deserialize and return it as MutableArray.
 *
 * @param key A unique key for the data.
 *
 * @return A MutableArray data if exists.
 */
+ (nullable NSMutableArray *)arrayForKey:(NSString *)key;

/**
 * Store a string to Keychain with the given key.
 *
 * @param string A string data to be placed in Keychain.
 * @param key A unique key for the data.
 *
 * @return YES if stored successfully, NO otherwise.
 */
+ (BOOL)storeString:(NSString *)string forKey:(NSString *)key;

/**
 * Delete a string from Keychain with the given key.
 *
 * @param key A unique key for the data.
 *
 * @return A string data that was deleted.
 */
+ (NSString *_Nullable)deleteStringForKey:(NSString *)key;

/**
 * Get a string from Keychain with the given key.
 *
 * @param key A unique key for the data.
 *
 * @return A string data if exists.
 */
+ (NSString *_Nullable)stringForKey:(NSString *)key;

/**
 * Clear all keys and strings.
 *
 * @return YES if cleared successfully, NO otherwise.
 */
+ (BOOL)clear;

@end

NS_ASSUME_NONNULL_END
