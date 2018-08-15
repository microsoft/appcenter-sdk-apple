#import "MSModelTestsUtililty.h"
#import "MSACModelConstants.h"
#import "MSCSModelConstants.h"
#import "MSDeviceInternal.h"
#import "MSWrapperSdkInternal.h"
#import "MSUtility.h"

@implementation MSModelTestsUtililty

#pragma mark - MSDevice

+ (NSDictionary *)deviceDummies {
  return @{
    kMSSDKVersion : @"3.0.1",
    kMSSDKName : @"appcenter-ios",
    kMSModel : @"iPhone 7.2",
    kMSOEMName : @"Apple",
    kMSACOSName : @"iOS",
    kMSOSVersion : @"9.3.20",
    kMSOSBuild : @"320",
    kMSLocale : @"US-EN",
    kMSTimeZoneOffset : @(9),
    kMSScreenSize : @"750x1334",
    kMSAppVersion : @"3.4.5",
    kMSAppBuild : @"178",
    kMSAppNamespace : @"com.contoso.apple.app",
    kMSCarrierName : @"Some-Telecom",
    kMSCarrierCountry : @"US",
    kMSWrapperSDKName : @"wrapper-sdk",
    kMSWrapperSDKVersion : @"6.7.8",
    kMSWrapperRuntimeVersion : @"9.10",
    kMSLiveUpdatePackageHash : @"b10a8db164e0754105b7a99be72e3fe5",
    kMSLiveUpdateReleaseLabel : @"live-update-release",
    kMSLiveUpdateDeploymentKey : @"deployment-key"
  };
}

+ (NSMutableDictionary *)extensionDummies {
  // Set up all extensions with dummy values.
  NSDictionary *userExtDummyValues =
      [MSModelTestsUtililty userExtensionDummies];
  MSUserExtension *userExt =
      [MSModelTestsUtililty userExtensionWithDummyValues:userExtDummyValues];
  NSDictionary *locExtDummyValues = [MSModelTestsUtililty locExtensionDummies];
  MSLocExtension *locExt =
      [MSModelTestsUtililty locExtensionWithDummyValues:locExtDummyValues];
  NSDictionary *osExtDummyValues = [MSModelTestsUtililty osExtensionDummies];
  MSOSExtension *osExt =
      [MSModelTestsUtililty osExtensionWithDummyValues:osExtDummyValues];
  NSDictionary *appExtDummyValues = [MSModelTestsUtililty appExtensionDummies];
  MSAppExtension *appExt =
      [MSModelTestsUtililty appExtensionWithDummyValues:appExtDummyValues];
  NSDictionary *protocolExtDummyValues =
      [MSModelTestsUtililty protocolExtensionDummies];
  MSProtocolExtension *protocolExt = [MSModelTestsUtililty
      protocolExtensionWithDummyValues:protocolExtDummyValues];
  NSDictionary *netExtDummyValues = [MSModelTestsUtililty netExtensionDummies];
  MSNetExtension *netExt =
      [MSModelTestsUtililty netExtensionWithDummyValues:netExtDummyValues];
  NSDictionary *sdkExtDummyValues = [MSModelTestsUtililty sdkExtensionDummies];
  MSSDKExtension *sdkExt =
      [MSModelTestsUtililty sdkExtensionWithDummyValues:sdkExtDummyValues];
  return [@{
    kMSCSUserExt : userExt,
    kMSCSLocExt : locExt,
    kMSCSOSExt : osExt,
    kMSCSAppExt : appExt,
    kMSCSProtocolExt : protocolExt,
    kMSCSNetExt : netExt,
    kMSCSSDKExt : sdkExt
  } mutableCopy];
}

+ (NSDictionary *)userExtensionDummies {
  return @{ kMSUserLocale : @"en-us" };
}

+ (NSDictionary *)locExtensionDummies {
  return @{ kMSTimezone : @"-03:00" };
}

+ (NSDictionary *)osExtensionDummies {
  return @{ kMSOSName : @"iOS", kMSOSVer : @"9.0" };
}

+ (NSDictionary *)appExtensionDummies {
  return @{
    kMSAppId : @"com.some.bundle.id",
    kMSAppVer : @"3.4.1",
    kMSAppLocale : @"en-us"
  };
}

+ (NSDictionary *)protocolExtensionDummies {
  return @{
    kMSTicketKeys : @[ @"ticketKey1", @"ticketKey2" ],
    kMSDevMake : @"Apple",
    kMSDevModel : @"iPhone X"
  };
}

+ (NSDictionary *)netExtensionDummies {
  return @{ kMSNetProvider : @"Verizon" };
}

+ (NSMutableDictionary *)sdkExtensionDummies {
  return [@{
    kMSSDKLibVer : @"1.2.0",
    kMSSDKEpoch : MS_UUID_STRING,
    kMSSDKSeq : @1,
    kMSSDKInstallId : [NSUUID new]
  } mutableCopy];
}

+ (NSDictionary *)dataDummies {
  return @{
    @"akey" : @"avalue",
    @"anested.key" : @"anothervalue",
    @"anotherkey" : @"yetanothervalue"
  };
}

+ (MSDevice *)dummyDevice {
  NSDictionary *dummyValues = [self deviceDummies];
  MSDevice *device = [MSDevice new];
  device.sdkVersion = dummyValues[kMSSDKVersion];
  device.sdkName = dummyValues[kMSSDKName];
  device.model = dummyValues[kMSModel];
  device.oemName = dummyValues[kMSOEMName];
  device.osName = dummyValues[kMSACOSName];
  device.osVersion = dummyValues[kMSOSVersion];
  device.osBuild = dummyValues[kMSOSBuild];
  device.locale = dummyValues[kMSLocale];
  device.timeZoneOffset = dummyValues[kMSTimeZoneOffset];
  device.screenSize = dummyValues[kMSScreenSize];
  device.appVersion = dummyValues[kMSAppVersion];
  device.appBuild = dummyValues[kMSAppBuild];
  device.appNamespace = dummyValues[kMSAppNamespace];
  device.carrierName = dummyValues[kMSCarrierName];
  device.carrierCountry = dummyValues[kMSCarrierCountry];
  device.wrapperSdkVersion = dummyValues[kMSWrapperSDKVersion];
  device.wrapperSdkName = dummyValues[kMSWrapperSDKName];
  device.wrapperRuntimeVersion = dummyValues[kMSWrapperRuntimeVersion];
  device.liveUpdateReleaseLabel = dummyValues[kMSLiveUpdateReleaseLabel];
  device.liveUpdateDeploymentKey = dummyValues[kMSLiveUpdateDeploymentKey];
  device.liveUpdatePackageHash = dummyValues[kMSLiveUpdatePackageHash];
  return device;
}

#pragma mark - MSAbstractLog

+ (NSDictionary *)abstractLogDummies {
  return @{
    kMSType : @"fakeLogType",
    kMSTimestamp : [NSDate dateWithTimeIntervalSince1970:42],
    kMSSId : @"FAKE-SESSION-ID",
    kMSDistributionGroupId : @"FAKE-GROUP-ID",
    kMSDevice : [self dummyDevice]
  };
}

+ (void)populateAbstractLogWithDummies:(MSAbstractLog *)log {
  NSDictionary *dummyValues = [self abstractLogDummies];
  log.type = dummyValues[kMSType];
  log.timestamp = dummyValues[kMSTimestamp];
  log.sid = dummyValues[kMSSId];
  log.distributionGroupId = dummyValues[kMSDistributionGroupId];
  log.device = dummyValues[kMSDevice];
}

#pragma mark - Extensions

+ (MSCSExtensions *)extensionsWithDummyValues:(NSDictionary *)dummyValues {
  MSCSExtensions *ext = [MSCSExtensions new];
  ext.userExt = dummyValues[kMSCSUserExt];
  ext.locExt = dummyValues[kMSCSLocExt];
  ext.osExt = dummyValues[kMSCSOSExt];
  ext.appExt = dummyValues[kMSCSAppExt];
  ext.protocolExt = dummyValues[kMSCSProtocolExt];
  ext.netExt = dummyValues[kMSCSNetExt];
  ext.sdkExt = dummyValues[kMSCSSDKExt];
  return ext;
}

+ (MSUserExtension *)userExtensionWithDummyValues:(NSDictionary *)dummyValues {
  MSUserExtension *userExt = [MSUserExtension new];
  userExt.locale = dummyValues[kMSUserLocale];
  return userExt;
}

+ (MSLocExtension *)locExtensionWithDummyValues:(NSDictionary *)dummyValues {
  MSLocExtension *locExt = [MSLocExtension new];
  locExt.tz = dummyValues[kMSTimezone];
  return locExt;
}

+ (MSOSExtension *)osExtensionWithDummyValues:(NSDictionary *)dummyValues {
  MSOSExtension *osExt = [MSOSExtension new];
  osExt.name = dummyValues[kMSOSName];
  osExt.ver = dummyValues[kMSOSVer];
  return osExt;
}

+ (MSAppExtension *)appExtensionWithDummyValues:(NSDictionary *)dummyValues {
  MSAppExtension *appExt = [MSAppExtension new];
  appExt.appId = dummyValues[kMSAppId];
  appExt.ver = dummyValues[kMSAppVer];
  appExt.locale = dummyValues[kMSAppLocale];
  return appExt;
}

+ (MSProtocolExtension *)protocolExtensionWithDummyValues:
    (NSDictionary *)dummyValues {
  MSProtocolExtension *protocolExt = [MSProtocolExtension new];
  protocolExt.ticketKeys = dummyValues[kMSTicketKeys];
  protocolExt.devMake = dummyValues[kMSDevMake];
  protocolExt.devModel = dummyValues[kMSDevModel];
  return protocolExt;
}

+ (MSNetExtension *)netExtensionWithDummyValues:(NSDictionary *)dummyValues {
  MSNetExtension *netExt = [MSNetExtension new];
  netExt.provider = dummyValues[kMSNetProvider];
  return netExt;
}

+ (MSSDKExtension *)sdkExtensionWithDummyValues:(NSDictionary *)dummyValues {
  MSSDKExtension *sdkExt = [MSSDKExtension new];
  sdkExt.libVer = dummyValues[kMSSDKLibVer];
  sdkExt.epoch = dummyValues[kMSSDKEpoch];
  sdkExt.seq = [dummyValues[kMSSDKSeq] longLongValue];
  sdkExt.installId = dummyValues[kMSSDKInstallId];
  return sdkExt;
}

+ (MSCSData *)dataWithDummyValues:(NSDictionary *)dummyValues {
  MSCSData *data = [MSCSData new];
  data.properties = dummyValues;
  return data;
}

@end
