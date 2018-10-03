#import "MSEventProperties.h"
#import "MSEventPropertiesInternal.h"

@implementation MSEventProperties

- (instancetype)init {
    if ((self = [super init])) {
        _properties = [NSMutableDictionary new];
    }
    return self;
}

/**
 * Creates an instance of EventProperties with a string-string properties dictionary.
 *
 * @param properties A dictionary of properties.
 * @return An instance of EventProperties.
 */
- (instancetype)initWithDictionary:(__unused NSDictionary<NSString *, NSString *> *)properties {
    return [self init];
}

/**
 * Set a string property.
 *
 * @param key Property key.
 * @param value Property value.
 */
- (void)setStringForKey:(NSString *)key
                  value:(NSString *)value {
    [self.properties setValue:value forKey:key];
}

/**
 * Set a double property.
 *
 * @param key Property key.
 * @param value Property value.
 */
- (void)setDoubleForKey:(NSString *)key
                  value:(double)value {
    [self.properties setValue:@(value) forKey:key];
}

/**
 * Set a long long (64-bit) property.
 *
 * @param key Property key.
 * @param value Property value.
 */
- (void)setLongLongForKey:(NSString *)key
                    value:(long long)value {
    [self.properties setValue:@(value) forKey:key];
}

/**
 * Set a boolean property.
 *
 * @param key Property key.
 * @param value Property value.
 */
- (void)setBoolForKey:(NSString *)key
                value:(BOOL)value {
    [self.properties setValue:@(value) forKey:key];
}

/**
 * Set a Date property.
 *
 * @param key Property key.
 * @param value Property value.
 */
- (void)setDateForKey:(NSString *)key
                value:(NSDate *)value {
    [self.properties setValue:value forKey:key];
}

/**
 * Serialize this object to a dictionary.
 *
 * @return A dictionary representing this object.
 */
- (NSMutableDictionary *)serializeToDictionary {
    //TODO implement!
    return nil;
}

@end