#import "MSCSExtensions.h"

static NSString *const kMSCSProtocolExt = @"protocol";
static NSString *const kMSCSUserExt = @"user";
static NSString *const kMSCSOSExt = @"os";
static NSString *const kMSCSAppExt = @"app";
static NSString *const kMSCSNetExt = @"net";
static NSString *const kMSCSSDKExt = @"sdk";
static NSString *const kMSCSLocExt = @"loc";

@implementation MSCSExtensions

#pragma mark - MSSerializableObject

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];
  if (self.protocolExt) {
    dict[kMSCSProtocolExt] = self.protocolExt;
  }
  if (self.userExt) {
    dict[kMSCSUserExt] = self.userExt;
  }
  if (self.osExt) {
    dict[kMSCSOSExt] = self.osExt;
  }
  if (self.appExt) {
    dict[kMSCSAppExt] = self.appExt;
  }
  if (self.netExt) {
    dict[kMSCSNetExt] = self.netExt;
  }
  if (self.sdkExt) {
    dict[kMSCSSDKExt] = self.sdkExt;
  }
  if (self.locExt) {
    dict[kMSCSLocExt] = self.locExt;
  }
  return dict;
}

#pragma mark - MSModel

- (BOOL)isValid {
  return [self.protocolExt isValid] && [self.userExt isValid] && [self.osExt isValid] && [self.appExt isValid] &&
         [self.netExt isValid] && [self.sdkExt isValid] && [self.locExt isValid];
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[MSCSExtensions class]]) {
    return NO;
  }
  MSCSExtensions *csExt = (MSCSExtensions *)object;
  return ((!self.protocolExt && !csExt.protocolExt) || [self.protocolExt isEqual:csExt.protocolExt]) &&
         ((!self.userExt && !csExt.userExt) || [self.userExt isEqual:csExt.userExt]) &&
         ((!self.osExt && !csExt.osExt) || [self.osExt isEqual:csExt.osExt]) &&
         ((!self.appExt && !csExt.appExt) || [self.appExt isEqual:csExt.appExt]) &&
         ((!self.netExt && !csExt.netExt) || [self.netExt isEqual:csExt.netExt]) &&
         ((!self.sdkExt && !csExt.sdkExt) || [self.sdkExt isEqual:csExt.sdkExt]) &&
         ((!self.locExt && !csExt.locExt) || [self.locExt isEqual:csExt.locExt]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  if ((self = [super init])) {
    _protocolExt = [coder decodeObjectForKey:kMSCSProtocolExt];
    _userExt = [coder decodeObjectForKey:kMSCSUserExt];
    _osExt = [coder decodeObjectForKey:kMSCSOSExt];
    _appExt = [coder decodeObjectForKey:kMSCSAppExt];
    _netExt = [coder decodeObjectForKey:kMSCSNetExt];
    _sdkExt = [coder decodeObjectForKey:kMSCSSDKExt];
    _locExt = [coder decodeObjectForKey:kMSCSLocExt];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.protocolExt forKey:kMSCSProtocolExt];
  [coder encodeObject:self.userExt forKey:kMSCSUserExt];
  [coder encodeObject:self.osExt forKey:kMSCSOSExt];
  [coder encodeObject:self.appExt forKey:kMSCSAppExt];
  [coder encodeObject:self.netExt forKey:kMSCSNetExt];
  [coder encodeObject:self.sdkExt forKey:kMSCSSDKExt];
  [coder encodeObject:self.locExt forKey:kMSCSLocExt];
}

@end
