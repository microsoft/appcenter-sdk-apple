#import "MSModelTestsUtililty.h"
#import "MSACModelConstants.h"
#import "MSDeviceInternal.h"
#import "MSWrapperSdkInternal.h"

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

@end
