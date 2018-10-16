#import "MSCSModelConstants.h"
#import "MSProtocolExtension.h"

@implementation MSProtocolExtension

#pragma mark - MSSerializableObject

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict;
  if (self.ticketKeys) {
    dict = [NSMutableDictionary new];
    dict[kMSTicketKeys] = self.ticketKeys;
  }
  if (self.devMake) {
    if (!dict) {
      dict = [NSMutableDictionary new];
    }
    dict[kMSDevMake] = self.devMake;
  }
  if (self.devModel) {
    if (!dict) {
      dict = [NSMutableDictionary new];
    }
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
  return ((!self.ticketKeys && !protocolExt.ticketKeys) || [self.ticketKeys isEqualToArray:protocolExt.ticketKeys]) &&
         ((!self.devMake && !protocolExt.devMake) || [self.devMake isEqualToString:protocolExt.devMake]) &&
         ((!self.devModel && !protocolExt.devModel) || [self.devModel isEqualToString:protocolExt.devModel]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  if ((self = [super init])) {
    _ticketKeys = [coder decodeObjectForKey:kMSTicketKeys];
    _devMake = [coder decodeObjectForKey:kMSDevMake];
    _devModel = [coder decodeObjectForKey:kMSDevModel];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.ticketKeys forKey:kMSTicketKeys];
  [coder encodeObject:self.devMake forKey:kMSDevMake];
  [coder encodeObject:self.devModel forKey:kMSDevModel];
}

@end
