/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVADevice.h"

static NSString *const kAVASdkVersion = @"sdkVersion";
static NSString *const kAVAWrapperSdkVersion = @"wrapperSdkVersion";
static NSString *const kAVAWrapperSdkName = @"wrapperSdkName";
static NSString *const kAVAModel = @"model";
static NSString *const kAVAOemName = @"oemName";
static NSString *const kAVAOsName = @"osName";
static NSString *const kAVAOsVersion = @"osVersion";
static NSString *const kAVAOsApiLevel = @"osApiLevel";
static NSString *const kAVALocale = @"locale";
static NSString *const kAVATimeZoneOffset = @"timeZoneOffset";
static NSString *const kAVAScreenSize = @"screenSize";
static NSString *const kAVAAppVersion = @"appVersion";
static NSString *const kAVACarrierName = @"carrierName";
static NSString *const kAVACarrierCountry = @"carrierCountry";
static NSString *const kAVAAppBuild = @"appBuild";
static NSString *const kAVAAppNamespace = @"appNamespace";

@implementation AVADevice

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];

  if (self.sdkVersion) {
    dict[kAVASdkVersion] = self.sdkVersion;
  }
  if (self.wrapperSdkVersion) {
    dict[kAVAWrapperSdkVersion] = self.wrapperSdkVersion;
  }
  if (self.wrapperSdkName) {
    dict[kAVAWrapperSdkName] = self.wrapperSdkName;
  }
  if (self.model) {
    dict[kAVAModel] = self.model;
  }
  if (self.oemName) {
    dict[kAVAOemName] = self.oemName;
  }
  if (self.osName) {
    dict[kAVAOsName] = self.osName;
  }
  if (self.osVersion) {
    dict[kAVAOsVersion] = self.osVersion;
  }
  if (self.osApiLevel) {
    dict[kAVAOsApiLevel] = self.osApiLevel;
  }
  if (self.locale) {
    dict[kAVALocale] = self.locale;
  }
  if (self.timeZoneOffset) {
    dict[kAVATimeZoneOffset] = self.timeZoneOffset;
  }
  if (self.screenSize) {
    dict[kAVAScreenSize] = self.screenSize;
  }
  if (self.appVersion) {
    dict[kAVAAppVersion] = self.appVersion;
  }
  if (self.carrierName) {
    dict[kAVACarrierName] = self.carrierName;
  }
  if (self.carrierCountry) {
    dict[kAVACarrierCountry] = self.carrierCountry;
  }
  if (self.appBuild) {
    dict[kAVAAppBuild] = self.appBuild;
  }
  if (self.appNamespace) {
    dict[kAVAAppNamespace] = self.appNamespace;
  }
  return dict;
}

- (BOOL)isValid {
  BOOL isValid = (!self.sdkVersion || !self.wrapperSdkVersion || !self.wrapperSdkName || !self.model || !self.oemName ||
                  !self.osName || !self.osVersion || !self.osApiLevel || !self.locale || !self.timeZoneOffset ||
                  !self.screenSize || !self.appVersion || !self.carrierName || !self.carrierCountry || !self.appBuild ||
                  !self.appNamespace);

  return isValid;
}

- (BOOL)isEqual:(AVADevice *)device {

  if (!device)
    return NO;

  return ((!self.sdkVersion && !device.sdkVersion) ||
          [self.sdkVersion isEqualToString:device.sdkVersion]) &&
         ((!self.wrapperSdkVersion && !device.wrapperSdkVersion) ||
          [self.wrapperSdkVersion isEqualToString:device.wrapperSdkVersion]) &&
         ((!self.wrapperSdkName && !device.wrapperSdkName) ||
          [self.wrapperSdkName isEqualToString:device.wrapperSdkName]) &&
         ((!self.model && !device.model) ||
          [self.model isEqualToString:device.model]) &&
         ((!self.oemName && !device.oemName) ||
          [self.oemName isEqualToString:device.oemName]) &&
         ((!self.osName && !device.osName) ||
          [self.osName isEqualToString:device.osName]) &&
         ((!self.osVersion && !device.osVersion) ||
          [self.osVersion isEqualToString:device.osVersion]) &&
         ((!self.osApiLevel && !device.osApiLevel) ||
          [self.osApiLevel isEqualToNumber:device.osApiLevel]) &&
         ((!self.locale && !device.locale) ||
          [self.locale isEqualToString:device.locale]) &&
         ((!self.timeZoneOffset && !device.timeZoneOffset) ||
          [self.timeZoneOffset isEqualToNumber:device.timeZoneOffset]) &&
         ((!self.screenSize && !device.screenSize) ||
          [self.screenSize isEqualToString:device.screenSize]) &&
         ((!self.appVersion && !device.appVersion) ||
          [self.appVersion isEqualToString:device.appVersion]) &&
         ((!self.carrierName && !device.carrierName) ||
          [self.carrierName isEqualToString:device.carrierName]) &&
         ((!self.carrierCountry && !device.carrierCountry) ||
          [self.carrierCountry isEqualToString:device.carrierCountry]) &&
         ((!self.appBuild && !device.appBuild) ||
          [self.appBuild isEqualToString:device.appBuild]) &&
         ((!self.appNamespace && !device.appNamespace) ||
          [self.appNamespace isEqualToString:device.appNamespace]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _sdkVersion = [coder decodeObjectForKey:kAVASdkVersion];
    _wrapperSdkVersion = [coder decodeObjectForKey:kAVAWrapperSdkVersion];
    _wrapperSdkName = [coder decodeObjectForKey:kAVAWrapperSdkName];
    _model = [coder decodeObjectForKey:kAVAModel];
    _oemName = [coder decodeObjectForKey:kAVAOemName];
    _osName = [coder decodeObjectForKey:kAVAOsName];
    _osVersion = [coder decodeObjectForKey:kAVAOsVersion];
    _osApiLevel = [coder decodeObjectForKey:kAVAOsApiLevel];
    _locale = [coder decodeObjectForKey:kAVALocale];
    _timeZoneOffset = [coder decodeObjectForKey:kAVATimeZoneOffset];
    _screenSize = [coder decodeObjectForKey:kAVAScreenSize];
    _appVersion = [coder decodeObjectForKey:kAVAAppVersion];
    _carrierName = [coder decodeObjectForKey:kAVACarrierName];
    _carrierCountry = [coder decodeObjectForKey:kAVACarrierCountry];
    _appBuild = [coder decodeObjectForKey:kAVAAppBuild];
    _appNamespace = [coder decodeObjectForKey:kAVAAppNamespace];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.sdkVersion forKey:kAVASdkVersion];
  [coder encodeObject:self.wrapperSdkVersion forKey:kAVAWrapperSdkVersion];
  [coder encodeObject:self.wrapperSdkName forKey:kAVAWrapperSdkName];
  [coder encodeObject:self.model forKey:kAVAModel];
  [coder encodeObject:self.oemName forKey:kAVAOemName];
  [coder encodeObject:self.osName forKey:kAVAOsName];
  [coder encodeObject:self.osVersion forKey:kAVAOsVersion];
  [coder encodeObject:self.osApiLevel forKey:kAVAOsApiLevel];
  [coder encodeObject:self.locale forKey:kAVALocale];
  [coder encodeObject:self.timeZoneOffset forKey:kAVATimeZoneOffset];
  [coder encodeObject:self.screenSize forKey:kAVAScreenSize];
  [coder encodeObject:self.appVersion forKey:kAVAAppVersion];
  [coder encodeObject:self.carrierName forKey:kAVACarrierName];
  [coder encodeObject:self.carrierCountry forKey:kAVACarrierCountry];
  [coder encodeObject:self.appBuild forKey:kAVAAppBuild];
  [coder encodeObject:self.appNamespace forKey:kAVAAppNamespace];
}

@end
