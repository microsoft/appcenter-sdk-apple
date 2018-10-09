#import "MSDoubleTypedProperty.h"
#import "MSConstants+Internal.h"

@implementation MSDoubleTypedProperty

- (instancetype)init {
  if ((self = [super init])) {
    self.type = @"double";
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _value = @([coder decodeDoubleForKey:kMSTypedPropertyValue]);
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeDouble:[self.value doubleValue] forKey:kMSTypedPropertyValue];
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
  MSDoubleTypedProperty *validProperty = [MSDoubleTypedProperty new];
  validProperty.name = [self.name substringToIndex:MIN(kMSMaxPropertyKeyLength, [self.name length])];
  validProperty.value = self.value;
  return validProperty;
}

- (instancetype)createValidCopyForOneCollector {
  return self;
}

@end
