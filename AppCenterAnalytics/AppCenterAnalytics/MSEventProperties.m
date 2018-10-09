#import "MSEventProperties.h"
#import "MSEventPropertiesInternal.h"
#import "MSAnalyticsInternal.h"
#import "MSLogger.h"
#import "MSTypedProperty.h"

static NSString *const kMSNullPropertyKeyMessage = @"Key cannot be null. Property will not be added.";
static NSString *const kMSNullPropertyValueMessage = @"Value cannot be null. Property will not be added.";

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
  if (!key) {
    MSLogWarning([MSAnalytics logTag], kMSNullPropertyKeyMessage);
    return self;
  }
  if (!value) {
    MSLogWarning([MSAnalytics logTag], kMSNullPropertyValueMessage);
    return self;
  }
  MSTypedProperty *stringProperty = [MSTypedProperty stringTypedProperty];
  stringProperty.name = key;
  stringProperty.value = value;
  self.properties[key] = stringProperty;
  return self;
}

- (instancetype)setDouble:(double)value forKey:(NSString *)key {
  if (!key) {
    MSLogWarning([MSAnalytics logTag], kMSNullPropertyKeyMessage);
    return self;
  }
  if (value == (double)INFINITY || value == (double)NAN) {
    MSLogError([MSAnalytics logTag], @"Double value for property '%@' must be finite (cannot be INFINITY or NAN).", key);
    return self;
  }
  MSTypedProperty *doubleProperty = [MSTypedProperty doubleTypedProperty];
  doubleProperty.name = key;
  doubleProperty.value = @(value);
  self.properties[key] = doubleProperty;
  return self;
}

- (instancetype)setInt64:(int64_t)value forKey:(NSString *)key {
  if (!key) {
    MSLogWarning([MSAnalytics logTag], kMSNullPropertyKeyMessage);
    return self;
  }
  MSTypedProperty *longProperty = [MSTypedProperty longTypedProperty];
  longProperty.name = key;
  longProperty.value = @(value);
  self.properties[key] = longProperty;
  return self;
}

- (instancetype)setBool:(BOOL)value forKey:(NSString *)key {
  if (!key) {
    MSLogWarning([MSAnalytics logTag], kMSNullPropertyKeyMessage);
    return self;
  }
  MSTypedProperty *boolProperty = [MSTypedProperty boolTypedProperty];
  boolProperty.name = key;
  boolProperty.value = @(value);
  self.properties[key] = boolProperty;
  return self;
}

- (instancetype)setDate:(NSDate *)value forKey:(NSString *)key {
  if (!key) {
    MSLogWarning([MSAnalytics logTag], kMSNullPropertyKeyMessage);
    return self;
  }
  if (!value) {
    MSLogWarning([MSAnalytics logTag], kMSNullPropertyValueMessage);
    return self;
  }
  MSTypedProperty *dateTimeProperty = [MSTypedProperty dateTypedProperty];
  dateTimeProperty.name = key;
  dateTimeProperty.value = value;
  self.properties[key] = dateTimeProperty;
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

@end
