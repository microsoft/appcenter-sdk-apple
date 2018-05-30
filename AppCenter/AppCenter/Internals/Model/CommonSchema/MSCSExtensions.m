#import "MSAppExtension.h"
#import "MSCSConstants.h"
#import "MSCSExtensions.h"
#import "MSLocExtension.h"
#import "MSNetExtension.h"
#import "MSOSExtension.h"
#import "MSProtocolExtension.h"
#import "MSSDKExtension.h"
#import "MSUserExtension.h"

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
  return (!self.protocolExt || [self.protocolExt isValid]) && (!self.userExt || [self.userExt isValid]) &&
         (!self.osExt || [self.osExt isValid]) && (!self.appExt || [self.appExt isValid]) &&
         (!self.netExt || [self.netExt isValid]) && (!self.sdkExt || [self.sdkExt isValid]) &&
         (!self.locExt || [self.locExt isValid]);
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
