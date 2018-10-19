#import "MSBooleanTypedProperty.h"
#import "MSACModelConstants.h"

@implementation MSBooleanTypedProperty

- (instancetype)init {
  if ((self = [super init])) {
    self.type = kMSBooleanTypedPropertyType;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _value = [coder decodeBoolForKey:kMSTypedPropertyValue];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeBool:self.value forKey:kMSTypedPropertyValue];
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];
  dict[kMSTypedPropertyValue] = @(self.value);
  return dict;
}

- (BOOL)isEqual:(id)object {
  if (![(NSObject *)object isKindOfClass:[MSBooleanTypedProperty class]] || ![super isEqual:object]) {
    return NO;
  }
  MSBooleanTypedProperty *property = (MSBooleanTypedProperty *)object;
  return (self.value == property.value);
}

@end
