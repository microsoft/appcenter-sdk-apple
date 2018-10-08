#import "MSEventProperties.h"
#import "MSEventPropertiesInternal.h"
#import "MSBooleanTypedProperty.h"
#import "MSDateTimeTypedProperty.h"
#import "MSDoubleTypedProperty.h"
#import "MSLongTypedProperty.h"
#import "MSStringTypedProperty.h"

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
- (instancetype)initWithDictionary:(NSDictionary<NSString *, NSString *> *)properties {
  if ((self = [self init])) {
    for (NSString *propertyKey in properties) {
      MSStringTypedProperty *stringProperty = [MSStringTypedProperty new];
      stringProperty.name = propertyKey;
      stringProperty.value = properties[propertyKey];
      [_properties addObject:stringProperty];
    }
  }
  return self;
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.properties];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  if ((self = [super init])) {
    _properties = (NSMutableArray<MSTypedProperty *> *_Nonnull) [coder decodeObject];
  }
  return self;
}

#pragma mark - Public methods

/**
 * Set a string property.
 *
 * @param value Property value.
 * @param key Property key.
 */
- (void)setString:(NSString *)value
           forKey:(NSString *)key {
  MSStringTypedProperty *stringProperty = [MSStringTypedProperty new];
  stringProperty.name = key;
  stringProperty.value = value;
  [self.properties addObject:stringProperty];
}

/**
 * Set a double property.
 *
 * @param value Property value.
 * @param key Property key.
 */
- (void)setDouble:(double)value forKey:(NSString *)key {
  MSDoubleTypedProperty *doubleProperty = [MSDoubleTypedProperty new];
  doubleProperty.name = key;
  doubleProperty.value = value;
  [self.properties addObject:doubleProperty];
}

/**
 * Set a 64-bit integer property.
 *
 * @param value Property value.
 * @param key Property key.
 */
- (void)setInt64:(int64_t)value forKey:(NSString *)key {
  MSLongTypedProperty *longProperty = [MSLongTypedProperty new];
  longProperty.name = key;
  longProperty.value = value;
  [self.properties addObject:longProperty];
}

/**
 * Set a boolean property.
 *
 * @param value Property value.
 * @param key Property key.
 */
- (void)setBool:(BOOL)value forKey:(NSString *)key {
  MSBooleanTypedProperty *boolProperty = [MSBooleanTypedProperty new];
  boolProperty.name = key;
  boolProperty.value = value;
  [self.properties addObject:boolProperty];
}

/**
 * Set a Date property.
 *
 * @param value Property value.
 * @param key Property key.
 */
- (void)setDate:(NSDate *)value forKey:(NSString *)key {
  MSDateTimeTypedProperty *dateTimeProperty = [MSDateTimeTypedProperty new];
  dateTimeProperty.name = key;
  dateTimeProperty.value = value;
  [self.properties addObject:dateTimeProperty];
}

/**
 * Serialize this object to an array.
 *
 * @return An array representing this object.
 */
- (NSMutableArray *)serializeToArray {
  NSMutableArray *propertiesArray = [NSMutableArray new];
  for (MSTypedProperty *typedProperty in self.properties) {
    [propertiesArray addObject:[typedProperty serializeToDictionary]];
  }
  return propertiesArray;
}

@end