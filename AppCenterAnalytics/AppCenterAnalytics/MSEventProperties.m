#import "MSEventProperties.h"
#import "MSEventPropertiesInternal.h"
#import "MSAnalyticsInternal.h"
#import "MSLogger.h"
#import "MSTypedProperty.h"

@implementation MSEventProperties

- (instancetype)init {
  if ((self = [super init])) {
    _properties = [NSMutableDictionary new];
  }
  return self;
}

- (instancetype)initWithDictionary:(NSDictionary<NSString *, NSString *> *)properties {
  if ((self = [self init])) {
    for (NSString *propertyKey in properties) {
      MSTypedProperty *stringProperty = [MSTypedProperty stringTypedProperty];
      stringProperty.name = propertyKey;
      stringProperty.value = properties[propertyKey];
      _properties[propertyKey] = stringProperty;
    }
  }
  return self;
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.properties];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  if ((self = [self init])) {
    [coder decodeObject];
  }
  return self;
}

#pragma mark - Public methods

- (instancetype)setString:(NSString *)value forKey:(NSString *)key {
  if ([MSEventProperties validateKey:key] && [MSEventProperties validateValue:value]) {
    MSTypedProperty *stringProperty = [MSTypedProperty stringTypedProperty];
    stringProperty.name = key;
    stringProperty.value = value;
    self.properties[key] = stringProperty;
  }
  return self;
}

- (instancetype)setDouble:(double)value forKey:(NSString *)key {
  if ([MSEventProperties validateKey:key]) {

    // NaN returns false for all statements, so the only way to check if value is NaN is by value != value.
    if (value == (double)INFINITY || value != value) {
      MSLogError([MSAnalytics logTag], @"Double value for property '%@' must be finite (cannot be INFINITY or NAN).", key);
      return self;
    }
    MSTypedProperty *doubleProperty = [MSTypedProperty doubleTypedProperty];
    doubleProperty.name = key;
    doubleProperty.value = @(value);
    self.properties[key] = doubleProperty;
  }
  return self;
}

- (instancetype)setInt64:(int64_t)value forKey:(NSString *)key {
  if ([MSEventProperties validateKey:key]) {
    MSTypedProperty *longProperty = [MSTypedProperty longTypedProperty];
    longProperty.name = key;
    longProperty.value = @(value);
    self.properties[key] = longProperty;
  }
  return self;
}

- (instancetype)setBool:(BOOL)value forKey:(NSString *)key {
  if ([MSEventProperties validateKey:key]) {
    MSTypedProperty *boolProperty = [MSTypedProperty boolTypedProperty];
    boolProperty.name = key;
    boolProperty.value = @(value);
    self.properties[key] = boolProperty;
  }
  return self;
}

- (instancetype)setDate:(NSDate *)value forKey:(NSString *)key {
  if ([MSEventProperties validateKey:key] && [MSEventProperties validateValue:value]) {
    MSTypedProperty *dateTimeProperty = [MSTypedProperty dateTypedProperty];
    dateTimeProperty.name = key;
    dateTimeProperty.value = value;
    self.properties[key] = dateTimeProperty;
  }
  return self;
}

#pragma mark - Internal methods

- (NSMutableArray *)serializeToArray {
  NSMutableArray *propertiesArray = [NSMutableArray new];
  for (MSTypedProperty *typedProperty in [self.properties objectEnumerator]) {
    [propertiesArray addObject:[typedProperty serializeToDictionary]];
  }
  return propertiesArray;
}

#pragma mark - Helper method

+ (BOOL)validateKey:(NSString *)key {
  if (!key) {
    MSLogError([MSAnalytics logTag], @"Key cannot be null. Property will not be added.");
    return NO;
  }
  return YES;
}

+ (BOOL)validateValue:(NSObject *)value {
  if (!value) {
    MSLogError([MSAnalytics logTag], @"Value cannot be null. Property will not be added.");
    return NO;
  }
  return YES;
}

@end
