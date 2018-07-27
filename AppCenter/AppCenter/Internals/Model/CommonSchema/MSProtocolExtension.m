#import "MSProtocolExtension.h"
#import "MSCSModelConstants.h"

@implementation MSProtocolExtension

#pragma mark - MSSerializableObject

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];
  if (self.devMake) {
    dict[kMSDevMake] = self.devMake;
  }
  if (self.devModel) {
    dict[kMSDevModel] = self.devModel;
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
  if (![(NSObject *)object isKindOfClass:[MSProtocolExtension class]]) {
    return NO;
  }
  MSProtocolExtension *protocolExt = (MSProtocolExtension *)object;
  return ((!self.devMake && !protocolExt.devMake) ||
          [self.devMake isEqualToString:protocolExt.devMake]) &&
         ((!self.devModel && !protocolExt.devModel) ||
          [self.devModel isEqualToString:protocolExt.devModel]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  if ((self = [super init])) {
    _devMake = [coder decodeObjectForKey:kMSDevMake];
    _devModel = [coder decodeObjectForKey:kMSDevModel];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.devMake forKey:kMSDevMake];
  [coder encodeObject:self.devModel forKey:kMSDevModel];
}

@end
