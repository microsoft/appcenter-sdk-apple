#import "MSMetadataExtension.h"

@implementation MSMetadataExtension

#pragma mark - MSSerializableObject

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict;
  if (self.metadata) {
    dict = [NSMutableDictionary new];
    [dict addEntriesFromDictionary:self.metadata];
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
  if (![(NSObject *)object isKindOfClass:[MSMetadataExtension class]]) {
    return NO;
  }
  MSMetadataExtension *csMetadata = (MSMetadataExtension *)object;
  return (!self.metadata && !csMetadata) || [self.metadata isEqualToDictionary:csMetadata.metadata];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  if ((self = [super init])) {
    _metadata = [coder decodeObject];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeRootObject:self.metadata];
}

@end
