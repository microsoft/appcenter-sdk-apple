#import "MSDevice.h"
#import "MSDeviceInternal.h"
#import "MSWrapperSdkInternal.h"

static NSString *const kMSSdkName = @"sdkName";
static NSString *const kMSSdkVersion = @"sdkVersion";
static NSString *const kMSModel = @"model";
static NSString *const kMSOemName = @"oemName";
static NSString *const kMSOsName = @"osName";
static NSString *const kMSOsVersion = @"osVersion";
static NSString *const kMSOsBuild = @"osBuild";
static NSString *const kMSOsApiLevel = @"osApiLevel";
static NSString *const kMSLocale = @"locale";
static NSString *const kMSTimeZoneOffset = @"timeZoneOffset";
static NSString *const kMSScreenSize = @"screenSize";
static NSString *const kMSAppVersion = @"appVersion";
static NSString *const kMSCarrierName = @"carrierName";
static NSString *const kMSCarrierCountry = @"carrierCountry";
static NSString *const kMSAppBuild = @"appBuild";
static NSString *const kMSAppNamespace = @"appNamespace";

@implementation MSDevice

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];

  if (self.sdkName) {
    dict[kMSSdkName] = self.sdkName;
  }
  if (self.sdkVersion) {
    dict[kMSSdkVersion] = self.sdkVersion;
  }
  if (self.model) {
    dict[kMSModel] = self.model;
  }
  if (self.oemName) {
    dict[kMSOemName] = self.oemName;
  }
  if (self.osName) {
    dict[kMSOsName] = self.osName;
  }
  if (self.osVersion) {
    dict[kMSOsVersion] = self.osVersion;
  }
  if (self.osBuild) {
    dict[kMSOsBuild] = self.osBuild;
  }
  if (self.osApiLevel) {
    dict[kMSOsApiLevel] = self.osApiLevel;
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
  return [super isValid] && self.sdkName && self.sdkVersion && self.osName && self.osVersion && self.locale &&
         self.timeZoneOffset && self.appVersion && self.appBuild;
}

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[MSDevice class]] || ![super isEqual:object]) {
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
         ((!self.timeZoneOffset && !device.timeZoneOffset) ||
          [self.timeZoneOffset isEqualToNumber:device.timeZoneOffset]) &&
         ((!self.screenSize && !device.screenSize) || [self.screenSize isEqualToString:device.screenSize]) &&
         ((!self.appVersion && !device.appVersion) || [self.appVersion isEqualToString:device.appVersion]) &&
         ((!self.carrierName && !device.carrierName) || [self.carrierName isEqualToString:device.carrierName]) &&
         ((!self.carrierCountry && !device.carrierCountry) ||
          [self.carrierCountry isEqualToString:device.carrierCountry]) &&
         ((!self.appBuild && !device.appBuild) || [self.appBuild isEqualToString:device.appBuild]) &&
         ((!self.appNamespace && !device.appNamespace) || [self.appNamespace isEqualToString:device.appNamespace]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _sdkName = [coder decodeObjectForKey:kMSSdkName];
    _sdkVersion = [coder decodeObjectForKey:kMSSdkVersion];
    _model = [coder decodeObjectForKey:kMSModel];
    _oemName = [coder decodeObjectForKey:kMSOemName];
    _osName = [coder decodeObjectForKey:kMSOsName];
    _osVersion = [coder decodeObjectForKey:kMSOsVersion];
    _osBuild = [coder decodeObjectForKey:kMSOsBuild];
    _osApiLevel = [coder decodeObjectForKey:kMSOsApiLevel];
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
  [coder encodeObject:self.sdkName forKey:kMSSdkName];
  [coder encodeObject:self.sdkVersion forKey:kMSSdkVersion];
  [coder encodeObject:self.model forKey:kMSModel];
  [coder encodeObject:self.oemName forKey:kMSOemName];
  [coder encodeObject:self.osName forKey:kMSOsName];
  [coder encodeObject:self.osVersion forKey:kMSOsVersion];
  [coder encodeObject:self.osBuild forKey:kMSOsBuild];
  [coder encodeObject:self.osApiLevel forKey:kMSOsApiLevel];
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
