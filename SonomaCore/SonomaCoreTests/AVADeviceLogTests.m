#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "AVADevice.h"

@interface AVADeviceTests : XCTestCase

@property(nonatomic, strong) AVADevice *sut;

@end

@implementation AVADeviceTests

@synthesize sut = _sut;

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
  _sut = [AVADevice new];
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

  // When
  NSMutableDictionary *actual = [self.sut serializeToDictionary];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"sdkVersion"], equalTo(sdkVersion));
  assertThat(actual[@"model"], equalTo(model));
  assertThat(actual[@"oemName"], equalTo(oemName));
  assertThat(actual[@"osName"], equalTo(osName));
  assertThat(actual[@"osVersion"], equalTo(osVersion));
  assertThat(actual[@"osApiLevel"], equalTo(osApiLevel));
  assertThat(actual[@"locale"], equalTo(locale));
  assertThat(actual[@"timeZoneOffset"], equalTo(timeZoneOffset));
  assertThat(actual[@"screenSize"], equalTo(screenSize));
  assertThat(actual[@"appVersion"], equalTo(appVersion));
  assertThat(actual[@"carrierName"], equalTo(carrierName));
  assertThat(actual[@"carrierCountry"], equalTo(carrierCountry));
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

  // When
  NSData *serializedEvent = [NSKeyedArchiver archivedDataWithRootObject:self.sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([AVADevice class]));

  AVADevice *actualDevice = actual;
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

  // When
  NSData *serializedEvent = [NSKeyedArchiver archivedDataWithRootObject:self.sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];
  AVADevice *actualDevice = actual;

  // then
  XCTAssertTrue([self.sut isEqual:actualDevice]);

  self.sut.carrierCountry = @"newCarrierCountry";
  XCTAssertFalse([self.sut isEqual:actualDevice]);
}

@end
