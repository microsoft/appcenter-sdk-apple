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

/**
 * Serialize this object to a dictionary.
 *
 * @return A dictionary representing this object.
 */
- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];
  dict[kMSTypedPropertyValue] = @(self.value);
  return dict;
}

- (instancetype)createValidCopyForAppCenter {
  [super createValidCopyForAppCenter];
  MSBooleanTypedProperty *validProperty = [MSBooleanTypedProperty new];
  validProperty.name = [self.name substringToIndex:kMSMaxPropertyKeyLength];
  validProperty.value = self.value;
  return validProperty;
}

- (instancetype)createValidCopyForOneCollector {
  return self;
}

@end