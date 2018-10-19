#import "MSCSData.h"

@implementation MSCSData

#pragma mark - MSSerializableObject

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict;
  if (self.properties) {
    dict = [NSMutableDictionary new];
    [dict addEntriesFromDictionary:self.properties];
  }
  return dict;
}

#pragma mark - MSModel

- (BOOL)isValid {

  // All attributes are optional.
  return YES;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (![(NSObject *)object isKindOfClass:[MSCSData class]]) {
    return NO;
  }
  MSCSData *csData = (MSCSData *)object;
  return (!self.properties && !csData.properties) || [self.properties isEqualToDictionary:csData.properties];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  if ((self = [super init])) {
    _properties = [coder decodeObject];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeRootObject:self.properties];
}

@end
