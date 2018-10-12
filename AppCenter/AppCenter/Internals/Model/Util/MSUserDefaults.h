#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Persistent settings, a wrapper around NSUserDefaults capable of updating object or dictionary (including expiration)
 */
@interface MSUserDefaults : NSObject

/**
 * @return the shared settings.
 */
+ (instancetype)shared;

/**
 * Updates a dictionary in the settings, returning what was actually updated (returning all if expiration time is reached).
 *
 * @param dict the dictionary to update.
 * @param key a unique key to identify the value.
 * @param expiration maximum time (in seconds) to keep dict values in the cache.
 */
- (NSDictionary *)updateDictionary:(NSDictionary *)dict
                            forKey:(NSString *)key
                        expiration:(float)expiration;

/**
 * Updates a dictionary in the settings, returning what was actually updated (no expiration).
 *
 * @param dict the dictionary to update
 * @param key a unique key to identify the value
 */
- (NSDictionary *)updateDictionary:(NSDictionary *)dict forKey:(NSString *)key;

/**
 * Updates an object in the settings, returning YES if object was updated, NO otherwise. It will return YES if expiration time is reached.
 *
 * @param o the object to update.
 * @param key a unique key to identify the value.
 * @param expiration maximum time (in seconds) to keep object in the cache.
 */
- (BOOL)updateObject:(id)o forKey:(NSString *)key expiration:(float)expiration;

/**
 * Updates an object in the settings, returning YES if object was updated, NO otherwise.
 *
 * @param o the object to update.
 * @param key a unique key to identify the value.
 */
- (BOOL)updateObject:(id)o forKey:(NSString *)key;

/**
 * Get an object in the settings, returning object if key was found, NULL otherwise.
 *
 * @param key a unique key to identify the value.
 */
- (nullable id)objectForKey:(NSString *)key;

/**
 * Sets the value of the specified key in the settings.
 *
 * @param o the object to set.
 * @param key a unique key to identify the value.
 */
- (void)setObject:(id)o forKey:(NSString *)key;

/**
 * Removes a value from the settings.
 *
 * @param key the key to remove.
 */
- (void)removeObjectForKey:(NSString *)key;

NS_ASSUME_NONNULL_END

@end
