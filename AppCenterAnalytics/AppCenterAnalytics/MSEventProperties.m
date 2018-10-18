#import "MSAnalyticsInternal.h"
#import "MSBooleanTypedProperty.h"
#import "MSDateTimeTypedProperty.h"
#import "MSDoubleTypedProperty.h"
#import "MSEventProperties.h"
#import "MSEventPropertiesInternal.h"
#import "MSLogger.h"
#import "MSLongTypedProperty.h"
#import "MSStringTypedProperty.h"

@implementation MSEventProperties

- (instancetype)init {
  if ((self = [super init])) {
    _properties = [NSMutableDictionary new];
  }
  return self;
}

- (instancetype)initWithStringDictionary:(NSDictionary<NSString *, NSString *> *)properties {
  if ((self = [self init])) {
    for (NSString *propertyKey in properties) {
      MSStringTypedProperty *stringProperty = [MSStringTypedProperty new];
      stringProperty.name = propertyKey;
      stringProperty.value = properties[propertyKey];
      _properties[propertyKey] = stringProperty;
    }
  }
  return self;
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)coder {
  @synchronized(self.properties) {
    [coder encodeObject:self.properties];
  }
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  if ((self = [self init])) {
    _properties = (NSMutableDictionary *)[coder decodeObject];
  }
  return self;
}

#pragma mark - Public methods

- (instancetype)setString:(NSString *)value forKey:(NSString *)key {
  if ([MSEventProperties validateKey:key] && [MSEventProperties validateValue:value]) {
    MSStringTypedProperty *stringProperty = [MSStringTypedProperty new];
    stringProperty.name = key;
    stringProperty.value = value;
    @synchronized(self.properties) {
      self.properties[key] = stringProperty;
    }
  }
  return self;
}

- (instancetype)setDouble:(double)value forKey:(NSString *)key {
  if ([MSEventProperties validateKey:key]) {

    // NaN returns false for all statements, so the only way to check if value is NaN is by value != value.
    if (value == (double)INFINITY || value == -(double)INFINITY || value != value) {
      MSLogError([MSAnalytics logTag], @"Double value for property '%@' must be finite (cannot be INFINITY or NAN).", key);
      return self;
    }
    MSDoubleTypedProperty *doubleProperty = [MSDoubleTypedProperty new];
    doubleProperty.name = key;
    doubleProperty.value = value;
    @synchronized(self.properties) {
      self.properties[key] = doubleProperty;
    }
  }
  return self;
}

- (instancetype)setInt64:(int64_t)value forKey:(NSString *)key {
  if ([MSEventProperties validateKey:key]) {
    MSLongTypedProperty *longProperty = [MSLongTypedProperty new];
    longProperty.name = key;
    longProperty.value = value;
    @synchronized(self.properties) {
      self.properties[key] = longProperty;
    }
  }
  return self;
}

- (instancetype)setBool:(BOOL)value forKey:(NSString *)key {
  if ([MSEventProperties validateKey:key]) {
    MSBooleanTypedProperty *boolProperty = [MSBooleanTypedProperty new];
    boolProperty.name = key;
    boolProperty.value = value;
    @synchronized(self.properties) {
      self.properties[key] = boolProperty;
    }
  }
  return self;
}

- (instancetype)setDate:(NSDate *)value forKey:(NSString *)key {
  if ([MSEventProperties validateKey:key] && [MSEventProperties validateValue:value]) {
    MSDateTimeTypedProperty *dateTimeProperty = [MSDateTimeTypedProperty new];
    dateTimeProperty.name = key;
    dateTimeProperty.value = value;
    @synchronized(self.properties) {
      self.properties[key] = dateTimeProperty;
    }
  }
  return self;
}

#pragma mark - Internal methods

- (NSMutableArray *)serializeToArray {
  NSMutableArray *propertiesArray = [NSMutableArray new];
  @synchronized(self.properties) {
    for (MSTypedProperty *typedProperty in [self.properties objectEnumerator]) {
      [propertiesArray addObject:[typedProperty serializeToDictionary]];
    }
  }
  return propertiesArray;
}

- (BOOL)isEmpty {
  return [self.properties count] == 0;
}

- (BOOL)isEqual:(id)object {
  if (![(NSObject *)object isKindOfClass:[MSEventProperties class]]) {
    return NO;
  }
  MSEventProperties *properties = (MSEventProperties *)object;
  return ((!self.properties && !properties.properties) || [self.properties isEqualToDictionary:properties.properties]);
}

#pragma mark - Helper methods

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

- (void)mergeEventProperties:(MSEventProperties *__nonnull)eventProperties {
  [self.properties addEntriesFromDictionary:(NSDictionary<NSString *, MSTypedProperty *> *)eventProperties.properties];
}

@end
