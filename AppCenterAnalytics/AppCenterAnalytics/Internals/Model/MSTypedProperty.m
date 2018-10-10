#import "MSConstants+Internal.h"
#import "MSTypedProperty.h"
#import "MSUtility+Date.h"

static NSString *const kMSTypedPropertyType = @"type";

static NSString *const kMSTypedPropertyName = @"name";

static NSString *const kMSTypedPropertyValue = @"value";

static NSString *const kMSPropertyTypeLong = @"long";

static NSString *const kMSPropertyTypeDouble = @"double";

@implementation MSTypedProperty

// Subclasses need to decode "value" since the type might be saved as a primitive.
- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _type = [coder decodeObjectForKey:kMSTypedPropertyType];
    _name = [coder decodeObjectForKey:kMSTypedPropertyName];
    _value = [coder decodeObjectForKey:kMSTypedPropertyValue];
  }
  return self;
}

// Subclasses need to encode "value" since the type might be saved as a primitive.
- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.type forKey:kMSTypedPropertyType];
  [coder encodeObject:self.name forKey:kMSTypedPropertyName];
  [coder encodeObject:self.value forKey:kMSTypedPropertyValue];
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];
  dict[kMSTypedPropertyType] = self.type;
  dict[kMSTypedPropertyName] = self.name;
  dict[kMSTypedPropertyValue] = self.value;
  return dict;
}

+ (instancetype)stringTypedProperty {
  MSTypedProperty *property = [MSTypedProperty new];
  property.type = kMSPropertyTypeString;
  return property;
}

+ (instancetype)longTypedProperty {
  MSTypedProperty *property = [MSTypedProperty new];
  property.type = kMSPropertyTypeLong;
  return property;
}

+ (instancetype)doubleTypedProperty {
  MSTypedProperty *property = [MSTypedProperty new];
  property.type = kMSPropertyTypeDouble;
  return property;
}

+ (instancetype)boolTypedProperty {
  MSTypedProperty *property = [MSTypedProperty new];
  property.type = kMSPropertyTypeBoolean;
  return property;
}

+ (instancetype)dateTypedProperty {
  MSTypedProperty *property = [MSTypedProperty new];
  property.type = kMSPropertyTypeDateTime;
  return property;
}
@end
