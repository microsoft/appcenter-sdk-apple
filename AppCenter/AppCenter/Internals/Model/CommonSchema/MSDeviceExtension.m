#import "MSDeviceExtension.h"
#import "MSCSModelConstants.h"

@implementation MSDeviceExtension

#pragma mark - MSSerializableObject

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict;
  if (self.localId) {
    dict = [NSMutableDictionary new];
    dict[kMSDeviceLocalId] = self.localId;
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
  if (![(NSObject *)object isKindOfClass:[MSDeviceExtension class]]) {
    return NO;
  }
  MSDeviceExtension *deviceExt = (MSDeviceExtension *)object;
  return (!self.localId && !deviceExt.localId) || [self.localId isEqualToString:deviceExt.localId];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  if ((self = [super init])) {
    _localId = [coder decodeObjectForKey:kMSDeviceLocalId];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.localId forKey:kMSDeviceLocalId];
}

@end
