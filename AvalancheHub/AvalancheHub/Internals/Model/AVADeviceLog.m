/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVADeviceLog.h"

static NSString *const kAVATypeDevice = @"device";

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

@implementation AVADeviceLog

- (instancetype)init {
  if (self = [super init]) {
    self.type = kAVATypeDevice;
  }
  return self;
}

- (void)write:(NSMutableDictionary *)dic {
  [super write:dic];

  if (self.sdkVersion)
    dic[kAVASdkVersion] = self.sdkVersion;
  if (self.wrapperSdkVersion)
    dic[kAVAWrapperSdkVersion] = self.wrapperSdkVersion;
  if (self.wrapperSdkName)
    dic[kAVAWrapperSdkName] = self.wrapperSdkName;
  if (self.model)
    dic[kAVAModel] = self.model;
  if (self.oemName)
    dic[kAVAOemName] = self.oemName;
  if (self.osName)
    dic[kAVAOsName] = self.osName;
  if (self.osVersion)
    dic[kAVAOsVersion] = self.osVersion;
  if (self.osApiLevel)
    dic[kAVAOsApiLevel] = self.osApiLevel;
  if (self.locale)
    dic[kAVALocale] = self.locale;
  if (self.timeZoneOffset)
    dic[kAVATimeZoneOffset] = self.timeZoneOffset;
  if (self.screenSize)
    dic[kAVAScreenSize] = self.screenSize;
  if (self.appVersion)
    dic[kAVAAppVersion] = self.appVersion;
  if (self.carrierName)
    dic[kAVACarrierName] = self.carrierName;
  if (self.carrierCountry)
    dic[kAVACarrierCountry] = self.carrierCountry;
  if (self.appBuild)
    dic[kAVAAppBuild] = self.appBuild;
  if (self.appNamespace)
    dic[kAVAAppNamespace] = self.appNamespace;
}

- (void)read:(NSDictionary *)obj {
  [super read:obj];

  // Set properties
  self.sdkVersion = obj[kAVASdkVersion];
  self.wrapperSdkVersion = obj[kAVAWrapperSdkVersion];
  self.wrapperSdkName = obj[kAVAWrapperSdkName];
  self.model = obj[kAVAModel];
  self.oemName = obj[kAVAOemName];
  self.osName = obj[kAVAOsName];
  self.osVersion = obj[kAVAOsVersion];
  self.osApiLevel = obj[kAVAOsApiLevel];
  self.locale = obj[kAVALocale];
  self.timeZoneOffset = obj[kAVATimeZoneOffset];
  self.screenSize = obj[kAVAScreenSize];
  self.appVersion = obj[kAVAAppVersion];
  self.carrierName = obj[kAVACarrierName];
  self.carrierCountry = obj[kAVACarrierCountry];
  self.appBuild = obj[kAVAAppBuild];
  self.appNamespace = obj[kAVAAppNamespace];
}

- (BOOL)isValid {
  BOOL isValid = YES;

  // Is valid
  isValid =
      (!self.sdkVersion || !self.wrapperSdkVersion || !self.wrapperSdkName ||
       !self.model || !self.oemName || !self.osName || !self.osVersion ||
       !self.osApiLevel || !self.locale || !self.timeZoneOffset ||
       !self.screenSize || !self.appVersion || !self.carrierName ||
       !self.carrierCountry || !self.appBuild || !self.appNamespace);
  return isValid;
}

@end
