#import "MSStringTypedProperty.h"
#import "MSACModelConstants.h"

@implementation MSStringTypedProperty

- (instancetype)init {
  if ((self = [super init])) {
    self.type = kMSStringTypedPropertyType;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _value = [coder decodeObjectForKey:kMSTypedPropertyValue];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.value forKey:kMSTypedPropertyValue];
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];
  dict[kMSTypedPropertyValue] = self.value;
  return dict;
}

- (BOOL)isEqual:(id)object {
  if (![(NSObject *)object isKindOfClass:[MSStringTypedProperty class]] || ![super isEqual:object]) {
    return NO;
  }
  MSStringTypedProperty *property = (MSStringTypedProperty *)object;
  return ((!self.value && !property.value) || [self.value isEqualToString:property.value]);
}

@end
