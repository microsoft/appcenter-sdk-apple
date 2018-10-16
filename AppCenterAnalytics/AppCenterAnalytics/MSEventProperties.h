#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Contains typed event properties.
 */
@interface MSEventProperties : NSObject

/**
 * Set a string property.
 *
 * @param value Property value.
 * @param key Property key.
 */
- (instancetype)setString:(NSString *)value forKey:(NSString *)key;

/**
 * Set a double property.
 *
 * @param value Property value. Must be finite (`NAN` and `INFINITY` not allowed).
 * @param key Property key.
 */
- (instancetype)setDouble:(double)value forKey:(NSString *)key;

/**
 * Set a 64-bit integer property.
 *
 * @param value Property value.
 * @param key Property key.
 */
- (instancetype)setInt64:(int64_t)value forKey:(NSString *)key;

/**
 * Set a boolean property.
 *
 * @param value Property value.
 * @param key Property key.
 */
- (instancetype)setBool:(BOOL)value forKey:(NSString *)key;

/**
 * Set a Date property.
 *
 * @param value Property value.
 * @param key Property key.
 */
- (instancetype)setDate:(NSDate *)value forKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
