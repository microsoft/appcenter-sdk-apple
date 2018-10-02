#import "MSEventProperties.h"

static NSDictionary *properties;

@implementation MSEventProperties

/**
 * Set a string property.
 *
 * @param key Property key.
 * @param value Property value.
 */
- (void)setStringForKey:(NSString *)key
                  value:(NSString *)value {
    [properties setValue:value forKey:key];
}

/**
 * Set a double property.
 *
 * @param key Property key.
 * @param value Property value.
 */
- (void)setDoubleForKey:(NSString *)key
                  value:(double)value {
    [properties setValue:value forKey:key];
}

/**
 * Set a long long (64-bit) property.
 *
 * @param key Property key.
 * @param value Property value.
 */
- (void)setLongLongForKey:(NSString *)key
                    value:(long long)value {
    [properties setValue:value forKey:key];
}

/**
 * Set a boolean property.
 *
 * @param key Property key.
 * @param value Property value.
 */
- (void)setBoolForKey:(NSString *)key
                value:(BOOL)value {
    [properties setValue:value forKey:key];
}

/**
 * Set a Date property.
 *
 * @param key Property key.
 * @param value Property value.
 */
- (void)setDateForKey:(NSString *)key
                value:(NSDate *)value {
    [properties setValue:value forKey:key];
}

@end