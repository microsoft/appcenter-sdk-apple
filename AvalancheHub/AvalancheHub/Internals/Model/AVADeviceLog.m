/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVADeviceLog.h"

static NSString* const kAVATypeDevice = @"device";

static NSString* const kAVASdkVersion = @"sdkVersion";
static NSString* const kAVAWrapperSdkVersion = @"wrapperSdkVersion";
static NSString* const kAVAWrapperSdkName = @"wrapperSdkName";
static NSString* const kAVAModel = @"model";
static NSString* const kAVAOemName = @"oemName";
static NSString* const kAVAOsName = @"osName";
static NSString* const kAVAOsVersion = @"osVersion";
static NSString* const kAVAOsApiLevel = @"osApiLevel";
static NSString* const kAVALocale = @"locale";
static NSString* const kAVATimeZoneOffset = @"timeZoneOffset";
static NSString* const kAVAScreenSize = @"screenSize";
static NSString* const kAVAAppVersion = @"appVersion";
static NSString* const kAVACarrierName = @"carrierName";
static NSString* const kAVACarrierCountry = @"carrierCountry";
static NSString* const kAVAAppBuild = @"appBuild";
static NSString* const kAVAAppNamespace = @"appNamespace";

@implementation AVADeviceLog

- (instancetype)init {
  self = [super init];
  if (self) {
    self.type = kAVATypeDevice;
  }
  return self;
}

- (void)write:(NSMutableDictionary*)dic {
  dic[kAVASdkVersion] = self.sdkVersion;
  dic[kAVAWrapperSdkVersion] = self.wrapperSdkVersion;
  dic[kAVAWrapperSdkName] = self.wrapperSdkName;
  dic[kAVAModel] = self.model;
  dic[kAVAOemName] = self.oemName;
  dic[kAVAOsName] = self.osName;
  dic[kAVAOsVersion] = self.osVersion;
  dic[kAVAOsApiLevel] = self.osApiLevel;
  dic[kAVALocale] = self.locale;
  dic[kAVATimeZoneOffset] = self.timeZoneOffset;
  dic[kAVAScreenSize] = self.screenSize;
  dic[kAVAAppVersion] = self.appVersion;
  dic[kAVACarrierName] = self.carrierName;
  dic[kAVACarrierCountry] = self.carrierCountry;
  dic[kAVAAppBuild] = self.appBuild;
  dic[kAVAAppNamespace] = self.appNamespace;
}

- (void)read:(NSDictionary*)obj {
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
  isValid = (!self.sdkVersion ||
             !self.wrapperSdkVersion ||
             !self.wrapperSdkName ||
             !self.model ||
             !self.oemName ||
             !self.osName ||
             !self.osVersion ||
             !self.osApiLevel ||
             !self.locale ||
             !self.timeZoneOffset ||
             !self.screenSize ||
             !self.appVersion ||
             !self.carrierName ||
             !self.carrierCountry ||
             !self.appBuild ||
             !self.appNamespace);
  return isValid;
}

@end
