#import "MSUserExtension.h"
#import "MSCSModelConstants.h"

@implementation MSUserExtension

#pragma mark - MSSerializableObject

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];
  if (self.localId) {
    dict[kMSUserLocalId] = self.localId;
  }
  if (self.locale) {
    dict[kMSUserLocale] = self.locale;
  }
  return dict.count == 0 ? nil : dict;
}

#pragma mark - MSModel

- (BOOL)isValid {

  // All attributes are optional.
  return YES;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (![(NSObject *)object isKindOfClass:[MSUserExtension class]]) {
    return NO;
  }
  MSUserExtension *userExt = (MSUserExtension *)object;
  return ((!self.localId && !userExt.localId) || [self.localId isEqualToString:userExt.localId]) &&
         ((!self.locale && !userExt.locale) || [self.locale isEqualToString:userExt.locale]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  if ((self = [super init])) {
    _localId = [coder decodeObjectForKey:kMSUserLocalId];
    _locale = [coder decodeObjectForKey:kMSUserLocale];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.localId forKey:kMSUserLocalId];
  [coder encodeObject:self.locale forKey:kMSUserLocale];
}

@end
