#import "MSEventProperties.h"
#import "MSEventPropertiesInternal.h"
#import "MSAnalyticsInternal.h"
#import "MSBooleanTypedProperty.h"
#import "MSDateTimeTypedProperty.h"
#import "MSDoubleTypedProperty.h"
#import "MSLogger.h"
#import "MSLongTypedProperty.h"
#import "MSStringTypedProperty.h"

static NSString *const kMSNullPropertyKeyMessage = @"Key cannot be null. Property will not be added.";
static NSString *const kMSNullPropertyValueMessage = @"Value cannot be null. Property will not be added.";

@implementation MSEventProperties

- (instancetype)init {
  if ((self = [super init])) {
    _properties = [NSMutableArray new];
  }
  return self;
}

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

- (void)setString:(NSString *)value forKey:(NSString *)key {
  if (!key) {
    MSLogWarning([MSAnalytics logTag], kMSNullPropertyKeyMessage);
    return;
  }
  if (!value) {
    MSLogWarning([MSAnalytics logTag], kMSNullPropertyValueMessage);
    return;
  }
  MSStringTypedProperty *stringProperty = [MSStringTypedProperty new];
  stringProperty.name = key;
  stringProperty.value = value;
  [self.properties addObject:stringProperty];
}

- (void)setDouble:(double)value forKey:(NSString *)key {
  if (!key) {
    MSLogWarning([MSAnalytics logTag], kMSNullPropertyKeyMessage);
    return;
  }
  MSDoubleTypedProperty *doubleProperty = [MSDoubleTypedProperty new];
  doubleProperty.name = key;
  doubleProperty.value = value;
  [self.properties addObject:doubleProperty];
}

- (void)setInt64:(int64_t)value forKey:(NSString *)key {
  if (!key) {
    MSLogWarning([MSAnalytics logTag], kMSNullPropertyKeyMessage);
    return;
  }
  MSLongTypedProperty *longProperty = [MSLongTypedProperty new];
  longProperty.name = key;
  longProperty.value = value;
  [self.properties addObject:longProperty];
}

- (void)setBool:(BOOL)value forKey:(NSString *)key {
  if (!key) {
    MSLogWarning([MSAnalytics logTag], kMSNullPropertyKeyMessage);
    return;
  }
  MSBooleanTypedProperty *boolProperty = [MSBooleanTypedProperty new];
  boolProperty.name = key;
  boolProperty.value = value;
  [self.properties addObject:boolProperty];
}

- (void)setDate:(NSDate *)value forKey:(NSString *)key {
  if (!key) {
    MSLogWarning([MSAnalytics logTag], kMSNullPropertyKeyMessage);
    return;
  }
  if (!value) {
    MSLogWarning([MSAnalytics logTag], kMSNullPropertyValueMessage);
    return;
  }
  MSDateTimeTypedProperty *dateTimeProperty = [MSDateTimeTypedProperty new];
  dateTimeProperty.name = key;
  dateTimeProperty.value = value;
  [self.properties addObject:dateTimeProperty];
}

- (NSMutableArray *)serializeToArray {
  NSMutableArray *propertiesArray = [NSMutableArray new];
  for (MSTypedProperty *typedProperty in self.properties) {
    [propertiesArray addObject:[typedProperty serializeToDictionary]];
  }
  return propertiesArray;
}

@end