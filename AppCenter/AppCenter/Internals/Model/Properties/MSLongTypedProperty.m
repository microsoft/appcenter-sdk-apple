// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSLongTypedProperty.h"

@implementation MSLongTypedProperty

- (instancetype)init {
  if ((self = [super init])) {
    self.type = kMSLongTypedPropertyType;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _value = [coder decodeInt64ForKey:kMSTypedPropertyValue];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeInt64:self.value forKey:kMSTypedPropertyValue];
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];
  dict[kMSTypedPropertyValue] = @(self.value);
  return dict;
}

- (BOOL)isEqual:(id)object {
  if (![(NSObject *)object isKindOfClass:[MSLongTypedProperty class]] || ![super isEqual:object]) {
    return NO;
  }
  MSLongTypedProperty *property = (MSLongTypedProperty *)object;
  return (self.value == property.value);
}

@end
