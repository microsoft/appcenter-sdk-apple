#import "MSACModelConstants.h"
#import "MSDevice.h"
#import "MSDeviceInternal.h"
#import "MSWrapperSdkInternal.h"

@implementation MSDevice

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];

  if (self.sdkName) {
    dict[kMSSDKName] = self.sdkName;
  }
  if (self.sdkVersion) {
    dict[kMSSDKVersion] = self.sdkVersion;
  }
  if (self.model) {
    dict[kMSModel] = self.model;
  }
  if (self.oemName) {
    dict[kMSOEMName] = self.oemName;
  }
  if (self.osName) {
    dict[kMSACOSName] = self.osName;
  }
  if (self.osVersion) {
    dict[kMSOSVersion] = self.osVersion;
  }
  if (self.osBuild) {
    dict[kMSOSBuild] = self.osBuild;
  }
  if (self.osApiLevel) {
    dict[kMSOSAPILevel] = self.osApiLevel;
  }
  if (self.locale) {
    dict[kMSLocale] = self.locale;
  }
  if (self.timeZoneOffset) {
    dict[kMSTimeZoneOffset] = self.timeZoneOffset;
  }
  if (self.screenSize) {
    dict[kMSScreenSize] = self.screenSize;
  }
  if (self.appVersion) {
    dict[kMSAppVersion] = self.appVersion;
  }
  if (self.carrierName) {
    dict[kMSCarrierName] = self.carrierName;
  }
  if (self.carrierCountry) {
    dict[kMSCarrierCountry] = self.carrierCountry;
  }
  if (self.appBuild) {
    dict[kMSAppBuild] = self.appBuild;
  }
  if (self.appNamespace) {
    dict[kMSAppNamespace] = self.appNamespace;
  }
  return dict;
}

- (BOOL)isValid {
  return [super isValid] && self.sdkName && self.sdkVersion && self.osName && self.osVersion && self.locale && self.timeZoneOffset &&
         self.appVersion && self.appBuild;
}

- (BOOL)isEqual:(id)object {
  if (![(NSObject *)object isKindOfClass:[MSDevice class]] || ![super isEqual:object]) {
    return NO;
  }
  MSDevice *device = (MSDevice *)object;
  return ((!self.sdkName && !device.sdkName) || [self.sdkName isEqualToString:device.sdkName]) &&
         ((!self.sdkVersion && !device.sdkVersion) || [self.sdkVersion isEqualToString:device.sdkVersion]) &&
         ((!self.model && !device.model) || [self.model isEqualToString:device.model]) &&
         ((!self.oemName && !device.oemName) || [self.oemName isEqualToString:device.oemName]) &&
         ((!self.osName && !device.osName) || [self.osName isEqualToString:device.osName]) &&
         ((!self.osVersion && !device.osVersion) || [self.osVersion isEqualToString:device.osVersion]) &&
         ((!self.osBuild && !device.osBuild) || [self.osBuild isEqualToString:device.osBuild]) &&
         ((!self.osApiLevel && !device.osApiLevel) || [self.osApiLevel isEqualToNumber:device.osApiLevel]) &&
         ((!self.locale && !device.locale) || [self.locale isEqualToString:device.locale]) &&
         ((!self.timeZoneOffset && !device.timeZoneOffset) || [self.timeZoneOffset isEqualToNumber:device.timeZoneOffset]) &&
         ((!self.screenSize && !device.screenSize) || [self.screenSize isEqualToString:device.screenSize]) &&
         ((!self.appVersion && !device.appVersion) || [self.appVersion isEqualToString:device.appVersion]) &&
         ((!self.carrierName && !device.carrierName) || [self.carrierName isEqualToString:device.carrierName]) &&
         ((!self.carrierCountry && !device.carrierCountry) || [self.carrierCountry isEqualToString:device.carrierCountry]) &&
         ((!self.appBuild && !device.appBuild) || [self.appBuild isEqualToString:device.appBuild]) &&
         ((!self.appNamespace && !device.appNamespace) || [self.appNamespace isEqualToString:device.appNamespace]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _sdkName = [coder decodeObjectForKey:kMSSDKName];
    _sdkVersion = [coder decodeObjectForKey:kMSSDKVersion];
    _model = [coder decodeObjectForKey:kMSModel];
    _oemName = [coder decodeObjectForKey:kMSOEMName];
    _osName = [coder decodeObjectForKey:kMSACOSName];
    _osVersion = [coder decodeObjectForKey:kMSOSVersion];
    _osBuild = [coder decodeObjectForKey:kMSOSBuild];
    _osApiLevel = [coder decodeObjectForKey:kMSOSAPILevel];
    _locale = [coder decodeObjectForKey:kMSLocale];
    _timeZoneOffset = [coder decodeObjectForKey:kMSTimeZoneOffset];
    _screenSize = [coder decodeObjectForKey:kMSScreenSize];
    _appVersion = [coder decodeObjectForKey:kMSAppVersion];
    _carrierName = [coder decodeObjectForKey:kMSCarrierName];
    _carrierCountry = [coder decodeObjectForKey:kMSCarrierCountry];
    _appBuild = [coder decodeObjectForKey:kMSAppBuild];
    _appNamespace = [coder decodeObjectForKey:kMSAppNamespace];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.sdkName forKey:kMSSDKName];
  [coder encodeObject:self.sdkVersion forKey:kMSSDKVersion];
  [coder encodeObject:self.model forKey:kMSModel];
  [coder encodeObject:self.oemName forKey:kMSOEMName];
  [coder encodeObject:self.osName forKey:kMSACOSName];
  [coder encodeObject:self.osVersion forKey:kMSOSVersion];
  [coder encodeObject:self.osBuild forKey:kMSOSBuild];
  [coder encodeObject:self.osApiLevel forKey:kMSOSAPILevel];
  [coder encodeObject:self.locale forKey:kMSLocale];
  [coder encodeObject:self.timeZoneOffset forKey:kMSTimeZoneOffset];
  [coder encodeObject:self.screenSize forKey:kMSScreenSize];
  [coder encodeObject:self.appVersion forKey:kMSAppVersion];
  [coder encodeObject:self.carrierName forKey:kMSCarrierName];
  [coder encodeObject:self.carrierCountry forKey:kMSCarrierCountry];
  [coder encodeObject:self.appBuild forKey:kMSAppBuild];
  [coder encodeObject:self.appNamespace forKey:kMSAppNamespace];
}

@end
