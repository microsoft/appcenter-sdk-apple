#import "MSEventProperties.h"
#import "MSEventPropertiesInternal.h"
#import "MSTypedProperty.h"

@implementation MSEventProperties

- (instancetype)init {
    if ((self = [super init])) {
        _properties = [NSMutableArray new];
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
    //TODO implement this - convert to properties array
    return [self init];
}

/**
 * Set a string property.
 *
 * @param key Property key.
 * @param value Property value.
 */
- (void)setString:(NSString *)key
           forKey:(NSString *)value {
    [self.properties setValue:value forKey:key];
}

/**
 * Set a double property.
 *
 * @param key Property key.
 * @param value Property value.
 */
- (void)setDouble:(double)value forKey:(NSString *)key {
    [self.properties setValue:@(value) forKey:key];
}

/**
 * Set a long long (64-bit) property.
 *
 * @param key Property key.
 * @param value Property value.
 */
- (void)setLongLong:(long long)value forKey:(NSString *)key {
    [self.properties setValue:@(value) forKey:key];
}

/**
 * Set a boolean property.
 *
 * @param key Property key.
 * @param value Property value.
 */
- (void)setBool:(BOOL)value forKey:(NSString *)key {
    [self.properties setValue:@(value) forKey:key];
}

/**
 * Set a Date property.
 *
 * @param key Property key.
 * @param value Property value.
 */
- (void)setDate:(NSDate *)value forKey:(NSString *)key {
    [self.properties setValue:value forKey:key];
}

/**
 * Serialize this object to an array.
 *
 * @return An array representing this object.
 */
- (NSMutableArray *)serializeToArray {
    NSMutableArray *propertiesArray = [NSMutableArray new];
    for (MSTypedProperty * typedProperty in self.properties) {
        [propertiesArray addObject:[typedProperty serializeToDictionary]];
    }
    return propertiesArray;
}

@end