#import "MSAppExtension.h"

static NSString *const kMSAppId = @"id";
static NSString *const kMSAppVer = @"ver";
static NSString *const kMSAppLocale = @"locale";

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
  if (self.locale) {
    dict[kMSAppLocale] = self.locale;
  }
  return dict;
}

#pragma mark - MSModel

- (BOOL)isValid {
  return self.appId && self.ver && self.locale;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[MSAppExtension class]]) {
    return NO;
  }
  MSAppExtension *appExt = (MSAppExtension *)object;
  return ((!self.appId && !appExt.appId) || [self.appId isEqualToString:appExt.appId]) &&
         ((!self.ver && !appExt.ver) || [self.ver isEqualToString:appExt.ver]) &&
         ((!self.locale && !appExt.locale) || [self.locale isEqualToString:appExt.locale]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  if ((self = [super init])) {
    _appId = [coder decodeObjectForKey:kMSAppId];
    _ver = [coder decodeObjectForKey:kMSAppVer];
    _locale = [coder decodeObjectForKey:kMSAppLocale];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.appId forKey:kMSAppId];
  [coder encodeObject:self.ver forKey:kMSAppVer];
  [coder encodeObject:self.locale forKey:kMSAppLocale];
}

@end
