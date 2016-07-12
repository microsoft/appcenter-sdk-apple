/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVADeviceLog.h"

static NSString *const kAVATypeDevice = @"device";

static NSString *const kAVASdkVersion = @"sdkVersion";
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

@implementation AVADeviceLog

@synthesize type = _type;

@synthesize sdkVersion = _sdkVersion;
@synthesize model = _model;
@synthesize oemName = _oemName;
@synthesize osName = _osName;
@synthesize osVersion = _osVersion;
@synthesize osApiLevel = _osApiLevel;
@synthesize locale = _locale;
@synthesize timeZoneOffset = _timeZoneOffset;
@synthesize screenSize = _screenSize;
@synthesize appVersion = _appVersion;
@synthesize carrierName = _carrierName;
@synthesize carrierCountry = _carrierCountry;

- (instancetype)init {
  if (self = [super init]) {
    _type = kAVATypeDevice;
  }
  return self;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];

  if (self.sdkVersion) {
    dict[kAVASdkVersion] = self.sdkVersion;
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
  return dict;
}

- (BOOL)isValid {
  BOOL isValid =
      (!self.sdkVersion || !self.model || !self.oemName || !self.osName ||
       !self.osVersion || !self.osApiLevel || !self.locale ||
       !self.timeZoneOffset || !self.screenSize || !self.appVersion ||
       !self.carrierName || !self.carrierCountry);

  return isValid;
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {

  NSArray *optionalProperties = @[];
  return [optionalProperties containsObject:propertyName];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _sdkVersion = [coder decodeObjectForKey:kAVASdkVersion];
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
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.sdkVersion forKey:kAVASdkVersion];
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
}

@end
