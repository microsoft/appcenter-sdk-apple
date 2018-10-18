#import "MSTypedProperty.h"

static NSString *const kMSTypedPropertyType = @"type";
static NSString *const kMSTypedPropertyName = @"name";

@implementation MSTypedProperty

// Subclasses need to decode "value" since the type might be saved as a primitive.
- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _type = [coder decodeObjectForKey:kMSTypedPropertyType];
    _name = [coder decodeObjectForKey:kMSTypedPropertyName];
  }
  return self;
}

// Subclasses need to encode "value" since the type might be saved as a primitive.
- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.type forKey:kMSTypedPropertyType];
  [coder encodeObject:self.name forKey:kMSTypedPropertyName];
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];
  dict[kMSTypedPropertyType] = self.type;
  dict[kMSTypedPropertyName] = self.name;
  return dict;
}

- (BOOL)isEqual:(id)object {
  if (![(NSObject *)object isKindOfClass:[MSTypedProperty class]]) {
    return NO;
  }
  MSTypedProperty *property = (MSTypedProperty *)object;
  return ((!self.type && !property.type) || [self.type isEqualToString:property.type]);
}

@end
