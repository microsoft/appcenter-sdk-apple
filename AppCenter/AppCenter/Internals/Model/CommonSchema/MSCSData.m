#import "MSCSData.h"

static NSString *const kMSDataProperties = @"properties";

@implementation MSCSData

#pragma mark - MSSerializableObject

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];
  if (self.properties) {
    dict[kMSDataProperties] = self.properties;
  }
  return dict;
}

#pragma mark - MSModel

- (BOOL)isValid {
  return self.properties;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[MSCSData class]]) {
    return NO;
  }
  MSCSData *csData = (MSCSData *)object;
  return (!self.properties && !csData.properties) || [self.properties isEqualToDictionary:csData.properties];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  if ((self = [super init])) {
    _properties = [coder decodeObjectForKey:kMSDataProperties];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.properties forKey:kMSDataProperties];
}

@end
