#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "SNMDevice.h"

@interface SNMDeviceTests : XCTestCase

@property(nonatomic, strong) SNMDevice *sut;

@end

@implementation SNMDeviceTests

@synthesize sut = _sut;

#pragma mark - Housekeeping

- (void)setUp {
  [super setUp];
  _sut = [SNMDevice new];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - Tests

- (void)testSerializingDeviceToDictionaryWorks {

  // If
  NSString *sdkVersion = @"3.0.1";
  NSString *model = @"iPhone 7.2";
  NSString *oemName = @"Apple";
  NSString *osName = @"iOS";
  NSString *osVersion = @"9.3.20";
  NSNumber *osApiLevel = @(320);
  NSString *locale = @"US-EN";
  NSNumber *timeZoneOffset = @(9);
  NSString *screenSize = @"750x1334";
  NSString *appVersion = @"3.4.5 (34)";
  NSString *carrierName = @"T-Mobile";
  NSString *carrierCountry = @"United States";
  NSString *wrapperSdkVersion = @"6.7.8";
  NSString *wrapperSdkName = @"wrapper-sdk";
  NSString *liveUpdateReleaseLabel = @"live-update-release";
  NSString *liveUpdateDeploymentKey = @"deployment-key";
  NSString *liveUpdatePackageHash = @"b10a8db164e0754105b7a99be72e3fe5";

  self.sut.sdkVersion = sdkVersion;
  self.sut.model = model;
  self.sut.oemName = oemName;
  self.sut.osName = osName;
  self.sut.osVersion = osVersion;
  self.sut.osApiLevel = osApiLevel;
  self.sut.locale = locale;
  self.sut.timeZoneOffset = timeZoneOffset;
  self.sut.screenSize = screenSize;
  self.sut.appVersion = appVersion;
  self.sut.carrierName = carrierName;
  self.sut.carrierCountry = carrierCountry;
  self.sut.wrapperSdkVersion = wrapperSdkVersion;
  self.sut.wrapperSdkName = wrapperSdkName;
  self.sut.liveUpdateReleaseLabel = liveUpdateReleaseLabel;
  self.sut.liveUpdateDeploymentKey = liveUpdateDeploymentKey;
  self.sut.liveUpdatePackageHash = liveUpdatePackageHash;

  // When
  NSMutableDictionary *actual = [self.sut serializeToDictionary];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"sdk_version"], equalTo(sdkVersion));
  assertThat(actual[@"model"], equalTo(model));
  assertThat(actual[@"oem_name"], equalTo(oemName));
  assertThat(actual[@"os_name"], equalTo(osName));
  assertThat(actual[@"os_version"], equalTo(osVersion));
  assertThat(actual[@"os_api_level"], equalTo(osApiLevel));
  assertThat(actual[@"locale"], equalTo(locale));
  assertThat(actual[@"time_zone_offset"], equalTo(timeZoneOffset));
  assertThat(actual[@"screen_size"], equalTo(screenSize));
  assertThat(actual[@"app_version"], equalTo(appVersion));
  assertThat(actual[@"carrier_name"], equalTo(carrierName));
  assertThat(actual[@"carrier_country"], equalTo(carrierCountry));
  assertThat(actual[@"wrapper_sdk_version"], equalTo(wrapperSdkVersion));
  assertThat(actual[@"wrapper_sdk_name"], equalTo(wrapperSdkName));
  assertThat(actual[@"live_update_release_label"], equalTo(liveUpdateReleaseLabel));
  assertThat(actual[@"live_update_deployment_key"], equalTo(liveUpdateDeploymentKey));
  assertThat(actual[@"live_update_package_hash"], equalTo(liveUpdatePackageHash));
}

- (void)testNSCodingSerializationAndDeserializationWorks {

  // If
  NSString *sdkVersion = @"3.0.1";
  NSString *model = @"iPhone 7.2";
  NSString *oemName = @"Apple";
  NSString *osName = @"iOS";
  NSString *osVersion = @"9.3.20";
  NSNumber *osApiLevel = @(320);
  NSString *locale = @"US-EN";
  NSNumber *timeZoneOffset = @(9);
  NSString *screenSize = @"750x1334";
  NSString *appVersion = @"3.4.5 (34)";
  NSString *carrierName = @"T-Mobile";
  NSString *carrierCountry = @"United States";
  NSString *wrapperSdkVersion = @"6.7.8";
  NSString *wrapperSdkName = @"wrapper-sdk";
  NSString *liveUpdateReleaseLabel = @"live-update-release";
  NSString *liveUpdateDeploymentKey = @"deployment-key";
  NSString *liveUpdatePackageHash = @"b10a8db164e0754105b7a99be72e3fe5";

  self.sut.sdkVersion = sdkVersion;
  self.sut.model = model;
  self.sut.oemName = oemName;
  self.sut.osName = osName;
  self.sut.osVersion = osVersion;
  self.sut.osApiLevel = osApiLevel;
  self.sut.locale = locale;
  self.sut.timeZoneOffset = timeZoneOffset;
  self.sut.screenSize = screenSize;
  self.sut.appVersion = appVersion;
  self.sut.carrierName = carrierName;
  self.sut.carrierCountry = carrierCountry;
  self.sut.wrapperSdkVersion = wrapperSdkVersion;
  self.sut.wrapperSdkName = wrapperSdkName;
  self.sut.liveUpdateReleaseLabel = liveUpdateReleaseLabel;
  self.sut.liveUpdateDeploymentKey = liveUpdateDeploymentKey;
  self.sut.liveUpdatePackageHash = liveUpdatePackageHash;

  // When
  NSData *serializedEvent = [NSKeyedArchiver archivedDataWithRootObject:self.sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([SNMDevice class]));

  SNMDevice *actualDevice = actual;
  assertThat(actualDevice.sdkVersion, equalTo(sdkVersion));
  assertThat(actualDevice.model, equalTo(model));
  assertThat(actualDevice.oemName, equalTo(oemName));
  assertThat(actualDevice.osName, equalTo(osName));
  assertThat(actualDevice.osVersion, equalTo(osVersion));
  assertThat(actualDevice.osApiLevel, equalTo(osApiLevel));
  assertThat(actualDevice.locale, equalTo(locale));
  assertThat(actualDevice.timeZoneOffset, equalTo(timeZoneOffset));
  assertThat(actualDevice.screenSize, equalTo(screenSize));
  assertThat(actualDevice.appVersion, equalTo(appVersion));
  assertThat(actualDevice.carrierName, equalTo(carrierName));
  assertThat(actualDevice.carrierCountry, equalTo(carrierCountry));
  assertThat(actualDevice.wrapperSdkVersion, equalTo(wrapperSdkVersion));
  assertThat(actualDevice.wrapperSdkName, equalTo(wrapperSdkName));
  assertThat(actualDevice.liveUpdateReleaseLabel, equalTo(liveUpdateReleaseLabel));
  assertThat(actualDevice.liveUpdateDeploymentKey, equalTo(liveUpdateDeploymentKey));
  assertThat(actualDevice.liveUpdatePackageHash, equalTo(liveUpdatePackageHash));
}

- (void)testIsEqual {

  // If
  NSString *sdkVersion = @"3.0.1";
  NSString *model = @"iPhone 7.2";
  NSString *oemName = @"Apple";
  NSString *osName = @"iOS";
  NSString *osVersion = @"9.3.20";
  NSNumber *osApiLevel = @(320);
  NSString *locale = @"US-EN";
  NSNumber *timeZoneOffset = @(9);
  NSString *screenSize = @"750x1334";
  NSString *appVersion = @"3.4.5 (34)";
  NSString *carrierName = @"T-Mobile";
  NSString *carrierCountry = @"United States";
  NSString *wrapperSdkVersion = @"6.7.8";
  NSString *wrapperSdkName = @"wrapper-sdk";
  NSString *liveUpdateReleaseLabel = @"live-update-release";
  NSString *liveUpdateDeploymentKey = @"deployment-key";
  NSString *liveUpdatePackageHash = @"b10a8db164e0754105b7a99be72e3fe5";

  self.sut.sdkVersion = sdkVersion;
  self.sut.model = model;
  self.sut.oemName = oemName;
  self.sut.osName = osName;
  self.sut.osVersion = osVersion;
  self.sut.osApiLevel = osApiLevel;
  self.sut.locale = locale;
  self.sut.timeZoneOffset = timeZoneOffset;
  self.sut.screenSize = screenSize;
  self.sut.appVersion = appVersion;
  self.sut.carrierName = carrierName;
  self.sut.carrierCountry = carrierCountry;
  self.sut.wrapperSdkVersion = wrapperSdkVersion;
  self.sut.wrapperSdkName = wrapperSdkName;
  self.sut.liveUpdateReleaseLabel = liveUpdateReleaseLabel;
  self.sut.liveUpdateDeploymentKey = liveUpdateDeploymentKey;
  self.sut.liveUpdatePackageHash = liveUpdatePackageHash;

  // When
  NSData *serializedEvent = [NSKeyedArchiver archivedDataWithRootObject:self.sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];
  SNMDevice *actualDevice = actual;

  // then
  XCTAssertTrue([self.sut isEqual:actualDevice]);

  self.sut.carrierCountry = @"newCarrierCountry";
  XCTAssertFalse([self.sut isEqual:actualDevice]);
}

@end
