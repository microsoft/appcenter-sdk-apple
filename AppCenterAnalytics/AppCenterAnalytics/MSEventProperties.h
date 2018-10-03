#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Contains typed event properties.
 */
@interface MSEventProperties : NSObject

/**
 * Set a string property.
 *
 * @param key Property key.
 * @param value Property value.
 */
- (void)setStringForKey:(NSString *)key
                  value:(NSString *)value;

/**
 * Set a double property.
 *
 * @param key Property key.
 * @param value Property value.
 */
- (void)setDoubleForKey:(NSString *)key
                  value:(double)value;

/**
 * Set a long long (64-bit) property.
 *
 * @param key Property key.
 * @param value Property value.
 */
- (void)setLongLongForKey:(NSString *)key
                    value:(long long)value;

/**
 * Set a boolean property.
 *
 * @param key Property key.
 * @param value Property value.
 */
- (void)setBoolForKey:(NSString *)key
                value:(BOOL)value;

/**
 * Set a Date property.
 *
 * @param key Property key.
 * @param value Property value.
 */
- (void)setDateForKey:(NSString *)key
                value:(NSDate *)value;

@end

NS_ASSUME_NONNULL_END