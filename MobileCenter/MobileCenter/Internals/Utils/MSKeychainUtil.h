#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Utility class for Keychain.
 */
@interface MSKeychainUtil : NSObject

/**
 * Store a string to Keychain with the given key and service name.
 *
 * @param string A string data to be placed in Keychain.
 * @param key A unique key for the data.
 * @param service A service name for the key.
 * @return YES if stored successfully, NO otherwise.
 */
+ (BOOL)storeString:(NSString *)string forKey:(NSString *)key service:(NSString *)service;

/**
 * Delete a key and a string for the given service name.
 *
 * @param key A unique key for the data.
 * @param service A service name for the key.
 * @return A string data that was deleted.
 */
+ (NSString *)deleteStringForKey:(NSString *)key service:(NSString *)service;

/**
 * Get a string from Keychain with the given key and service name.
 *
 * @param key A unique key for the data.
 * @param service A service name for the key.
 * @return A string data if exists.
 */
+ (NSString *)stringForKey:(NSString *)key service:(NSString *)service;

/**
 * Clear all keys and strings associated with the given service name.
 *
 * @param service A service name for keys.
 * @return YES if cleared successfully, NO otherwise.
 */
+ (BOOL)clearForService:(NSString *)service;

@end

NS_ASSUME_NONNULL_END
