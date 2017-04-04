#import <Foundation/Foundation.h>

/**
 * Custom properties builder.
 * Collects multiple properties to send in one log.
 */
@interface MSCustomProperties : NSObject

/**
 * Set the specified property value with the specified key.
 * If the properties previously contained a property for the key, the old
 * value is replaced.
 *
 * @param key   key with which the specified value is to be set.
 * @param value value to be set with the specified key.
 * @return this instance.
 */
- (MSCustomProperties *)setString:(NSString *)value forKey:(NSString *)key;

/**
 * Set the specified property value with the specified key.
 * If the properties previously contained a property for the key, the old
 * value is replaced.
 *
 * @param key   key with which the specified value is to be set.
 * @param value value to be set with the specified key.
 * @return this instance.
 */
- (MSCustomProperties *)setNumber:(NSNumber *)value forKey:(NSString *)key;

/**
 * Set the specified property value with the specified key.
 * If the properties previously contained a property for the key, the old
 * value is replaced.
 *
 * @param key   key with which the specified value is to be set.
 * @param value value to be set with the specified key.
 * @return this instance.
 */
- (MSCustomProperties *)setBool:(BOOL)value forKey:(NSString *)key;

/**
 * Set the specified property value with the specified key.
 * If the properties previously contained a property for the key, the old
 * value is replaced.
 *
 * @param key   key with which the specified value is to be set.
 * @param value value to be set with the specified key.
 * @return this instance.
 */
- (MSCustomProperties *)setDate:(NSDate *)value forKey:(NSString *)key;

/**
 * Clear the property for the specified key.
 *
 * @param key key whose mapping is to be cleared.
 * @return this instance.
 */
- (MSCustomProperties *)clearPropertyForKey:(NSString *)key;

@end
