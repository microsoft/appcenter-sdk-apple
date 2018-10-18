#import "MSCSExtensions.h"
#import "MSAppExtension.h"
#import "MSCSModelConstants.h"
#import "MSDeviceExtension.h"
#import "MSLocExtension.h"
#import "MSMetadataExtension.h"
#import "MSNetExtension.h"
#import "MSOSExtension.h"
#import "MSProtocolExtension.h"
#import "MSSDKExtension.h"
#import "MSUserExtension.h"

@implementation MSCSExtensions

#pragma mark - MSSerializableObject

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];
  if (self.metadataExt) {
    dict[kMSCSMetadataExt] = [self.metadataExt serializeToDictionary];
  }
  if (self.protocolExt) {
    dict[kMSCSProtocolExt] = [self.protocolExt serializeToDictionary];
  }
  if (self.userExt) {
    dict[kMSCSUserExt] = [self.userExt serializeToDictionary];
  }
  if (self.deviceExt) {
    dict[kMSCSDeviceExt] = [self.deviceExt serializeToDictionary];
  }
  if (self.osExt) {
    dict[kMSCSOSExt] = [self.osExt serializeToDictionary];
  }
  if (self.appExt) {
    dict[kMSCSAppExt] = [self.appExt serializeToDictionary];
  }
  if (self.netExt) {
    dict[kMSCSNetExt] = [self.netExt serializeToDictionary];
  }
  if (self.sdkExt) {
    dict[kMSCSSDKExt] = [self.sdkExt serializeToDictionary];
  }
  if (self.locExt) {
    dict[kMSCSLocExt] = [self.locExt serializeToDictionary];
  }
  return dict;
}

#pragma mark - MSModel

- (BOOL)isValid {
  return (!self.metadataExt || [self.metadataExt isValid]) && (!self.protocolExt || [self.protocolExt isValid]) &&
         (!self.userExt || [self.userExt isValid]) && (!self.deviceExt || [self.deviceExt isValid]) &&
         (!self.osExt || [self.osExt isValid]) && (!self.appExt || [self.appExt isValid]) && (!self.netExt || [self.netExt isValid]) &&
         (!self.sdkExt || [self.sdkExt isValid]) && (!self.locExt || [self.locExt isValid]);
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (![(NSObject *)object isKindOfClass:[MSCSExtensions class]]) {
    return NO;
  }
  MSCSExtensions *csExt = (MSCSExtensions *)object;
  return ((!self.protocolExt && !csExt.protocolExt) || [self.protocolExt isEqual:csExt.protocolExt]) &&
         ((!self.metadataExt && !csExt.metadataExt) || [self.metadataExt isEqual:csExt.metadataExt]) &&
         ((!self.userExt && !csExt.userExt) || [self.userExt isEqual:csExt.userExt]) &&
         ((!self.deviceExt && !csExt.deviceExt) || [self.deviceExt isEqual:csExt.deviceExt]) &&
         ((!self.osExt && !csExt.osExt) || [self.osExt isEqual:csExt.osExt]) &&
         ((!self.appExt && !csExt.appExt) || [self.appExt isEqual:csExt.appExt]) &&
         ((!self.netExt && !csExt.netExt) || [self.netExt isEqual:csExt.netExt]) &&
         ((!self.sdkExt && !csExt.sdkExt) || [self.sdkExt isEqual:csExt.sdkExt]) &&
         ((!self.locExt && !csExt.locExt) || [self.locExt isEqual:csExt.locExt]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  if ((self = [super init])) {
    _metadataExt = [coder decodeObjectForKey:kMSCSMetadataExt];
    _protocolExt = [coder decodeObjectForKey:kMSCSProtocolExt];
    _userExt = [coder decodeObjectForKey:kMSCSUserExt];
    _deviceExt = [coder decodeObjectForKey:kMSCSDeviceExt];
    _osExt = [coder decodeObjectForKey:kMSCSOSExt];
    _appExt = [coder decodeObjectForKey:kMSCSAppExt];
    _netExt = [coder decodeObjectForKey:kMSCSNetExt];
    _sdkExt = [coder decodeObjectForKey:kMSCSSDKExt];
    _locExt = [coder decodeObjectForKey:kMSCSLocExt];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.metadataExt forKey:kMSCSMetadataExt];
  [coder encodeObject:self.protocolExt forKey:kMSCSProtocolExt];
  [coder encodeObject:self.userExt forKey:kMSCSUserExt];
  [coder encodeObject:self.deviceExt forKey:kMSCSDeviceExt];
  [coder encodeObject:self.osExt forKey:kMSCSOSExt];
  [coder encodeObject:self.appExt forKey:kMSCSAppExt];
  [coder encodeObject:self.netExt forKey:kMSCSNetExt];
  [coder encodeObject:self.sdkExt forKey:kMSCSSDKExt];
  [coder encodeObject:self.locExt forKey:kMSCSLocExt];
}

@end
