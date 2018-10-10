#import "MSBooleanTypedProperty.h"
#import "MSConstants+Internal.h"

@implementation MSBooleanTypedProperty

- (instancetype)init {
  if ((self = [super init])) {
    self.type = @"boolean";
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

@end
