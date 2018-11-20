#import "MSAppExtension.h"
#import "MSCSModelConstants.h"

@implementation MSAppExtension

#pragma mark - MSSerializableObject

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];
  if (self.appId) {
    dict[kMSAppId] = self.appId;
  }
  if (self.ver) {
    dict[kMSAppVer] = self.ver;
  }
  if (self.name) {
    dict[kMSAppName] = self.name;
  }
  if (self.locale) {
    dict[kMSAppLocale] = self.locale;
  }
  if (self.userId) {
    dict[kMSAppUserId] = self.userId;
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
  if (![(NSObject *)object isKindOfClass:[MSAppExtension class]]) {
    return NO;
  }
  MSAppExtension *appExt = (MSAppExtension *)object;
  return ((!self.appId && !appExt.appId) || [self.appId isEqualToString:appExt.appId]) &&
         ((!self.ver && !appExt.ver) || [self.ver isEqualToString:appExt.ver]) &&
         ((!self.name && !appExt.name) || [self.name isEqualToString:appExt.name]) &&
         ((!self.locale && !appExt.locale) || [self.locale isEqualToString:appExt.locale]) &&
         ((!self.userId && !appExt.userId) || [self.userId isEqualToString:appExt.userId]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  if ((self = [super init])) {
    _appId = [coder decodeObjectForKey:kMSAppId];
    _ver = [coder decodeObjectForKey:kMSAppVer];
    _name = [coder decodeObjectForKey:kMSAppName];
    _locale = [coder decodeObjectForKey:kMSAppLocale];
    _userId = [coder decodeObjectForKey:kMSAppUserId];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.appId forKey:kMSAppId];
  [coder encodeObject:self.ver forKey:kMSAppVer];
  [coder encodeObject:self.name forKey:kMSAppName];
  [coder encodeObject:self.locale forKey:kMSAppLocale];
  [coder encodeObject:self.userId forKey:kMSAppUserId];
}

@end
