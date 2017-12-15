

#import "MSKeychainUtil.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Keychain service name suffix.
 */
static NSString *const kMSServiceSuffix = @"AppCenter";

/**
 * Utility class for Keychain.
 */
@interface MSKeychainUtil ()

/**
 * Store a string to Keychain with the given key.
 *
 * @param string A string data to be placed in Keychain.
 * @param key A unique key for the data.
 * @param serviceName Keychain service name.
 *
 * @return YES if stored successfully, NO otherwise.
 */
+ (BOOL)storeString:(NSString *)string forKey:(NSString *)key withServiceName:(NSString *)serviceName;

/**
 * Delete a string from Keychain with the given key.
 *
 * @param key A unique key for the data.
 * @param serviceName Keychain service name.
 *
 * @return A string data that was deleted.
 */
+ (NSString *_Nullable)deleteStringForKey:(NSString *)key withServiceName:(NSString *)serviceName;

/**
 * Get a string from Keychain with the given key.
 *
 * @param key A unique key for the data.
 * @param serviceName Keychain service name.
 *
 * @return A string data if exists.
 */
+ (NSString *_Nullable)stringForKey:(NSString *)key withServiceName:(NSString *)serviceName;

@end

NS_ASSUME_NONNULL_END
