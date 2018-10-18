#import "MSDoubleTypedProperty.h"
#import "MSACModelConstants.h"

@implementation MSDoubleTypedProperty

- (instancetype)init {
  if ((self = [super init])) {
    self.type = kMSDoubleTypedPropertyType;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _value = [coder decodeDoubleForKey:kMSTypedPropertyValue];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeDouble:self.value forKey:kMSTypedPropertyValue];
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];
  dict[kMSTypedPropertyValue] = @(self.value);
  return dict;
}

- (BOOL)isEqual:(id)object {
  if (![(NSObject *)object isKindOfClass:[MSDoubleTypedProperty class]] || ![super isEqual:object]) {
    return NO;
  }
  MSDoubleTypedProperty *property = (MSDoubleTypedProperty *)object;
  return (self.value == property.value);
}

@end
