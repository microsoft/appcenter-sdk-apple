#import "MSAbstractLogInternal.h"
#import "MSAbstractLogPrivate.h"
#import "MSCSModelConstants.h"
#import "MSDeviceInternal.h"
#import "MSEventLogPrivate.h"
#import "MSLogWithProperties.h"
#import "MSTestFrameworks.h"
#import "MSUtility+Date.h"

@interface MSEventLogTests : XCTestCase

@property(nonatomic) MSEventLog *sut;

@end

@implementation MSEventLogTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
  self.sut = [MSEventLog new];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - Tests

- (void)testSerializingEventToDictionaryWorks {

  // If
  NSString *typeName = @"event";
  NSString *eventId = MS_UUID_STRING;
  NSString *eventName = @"eventName";
  MSDevice *device = [MSDevice new];
  NSString *sessionId = @"1234567890";
  NSDictionary *properties = @{ @"Key" : @"Value" };
  NSDate *timestamp = [NSDate date];

  self.sut.eventId = eventId;
  self.sut.name = eventName;
  self.sut.device = device;
  self.sut.timestamp = timestamp;
  self.sut.sid = sessionId;
  self.sut.properties = properties;

  // When
  NSMutableDictionary *actual = [self.sut serializeToDictionary];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"id"], equalTo(eventId));
  assertThat(actual[@"name"], equalTo(eventName));
  assertThat(actual[@"device"], notNilValue());
  assertThat(actual[@"sid"], equalTo(sessionId));
  assertThat(actual[@"type"], equalTo(typeName));
  assertThat(actual[@"properties"], equalTo(properties));
  assertThat(actual[@"device"], notNilValue());
  assertThat(actual[@"timestamp"],
             equalTo([MSUtility dateToISO8601:timestamp]));
}

- (void)testNSCodingSerializationAndDeserializationWorks {

  // If
  NSString *typeName = @"event";
  NSString *eventId = MS_UUID_STRING;
  NSString *eventName = @"eventName";
  MSDevice *device = [MSDevice new];
  NSString *sessionId = @"1234567890";
  NSDate *timestamp = [NSDate date];
  NSDictionary *properties = @{ @"Key" : @"Value" };

  self.sut.eventId = eventId;
  self.sut.name = eventName;
  self.sut.device = device;
  self.sut.timestamp = timestamp;
  self.sut.sid = sessionId;
  self.sut.properties = properties;

  // When
  NSData *serializedEvent =
      [NSKeyedArchiver archivedDataWithRootObject:self.sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([MSEventLog class]));
  MSEventLog *actualEvent = actual;
  assertThat(actualEvent.name, equalTo(eventName));
  assertThat(actualEvent.eventId, equalTo(eventId));
  assertThat(actualEvent.device, notNilValue());
  assertThat(actualEvent.timestamp, equalTo(timestamp));
  assertThat(actualEvent.type, equalTo(typeName));
  assertThat(actualEvent.sid, equalTo(sessionId));
  assertThat(actualEvent.properties, equalTo(properties));
  XCTAssertTrue([self.sut isEqual:actualEvent]);
}

- (void)testIsValid {

  // If
  self.sut.device = OCMClassMock([MSDevice class]);
  OCMStub([self.sut.device isValid]).andReturn(YES);
  self.sut.timestamp = [NSDate date];
  self.sut.sid = @"1234567890";

  // Then
  XCTAssertFalse([self.sut isValid]);

  // When
  self.sut.eventId = MS_UUID_STRING;

  // Then
  XCTAssertFalse([self.sut isValid]);

  // When
  self.sut.name = @"eventName";

  // Then
  XCTAssertTrue([self.sut isValid]);
}

- (void)testIsNotEqualToNil {

  // Then
  XCTAssertFalse([self.sut isEqual:nil]);
}

- (void)testConvertACPropertiesToCSproperties {

  // If
  NSDictionary *acProperties = nil;

  // When
  NSDictionary *csProperties =
      [self.sut convertACPropertiesToCSproperties:acProperties];

  // Then
  XCTAssertNil(csProperties);

  // If
  acProperties = @{ @"key" : @"value", @"key2" : @"value2" };

  // When
  csProperties = [self.sut convertACPropertiesToCSproperties:acProperties];

  // Then
  XCTAssertEqualObjects(csProperties, acProperties);

  // If
  acProperties = @{ @"nes.t.ed" : @"buriedValue" };

  // When
  csProperties = [self.sut convertACPropertiesToCSproperties:acProperties];

  // Then
  XCTAssertEqualObjects(csProperties,
                        @{ @"nes" : @{@"t" : @{@"ed" : @"buriedValue"}} });

  // If
  acProperties =
      @{ @"key" : @"value",
         @"nes.t.ed" : @"buriedValue",
         @"key2" : @"value2" };

  // When
  csProperties = [self.sut convertACPropertiesToCSproperties:acProperties];
  NSDictionary *test = @{
    @"key" : @"value",
    @"nes" : @{@"t" : @{@"ed" : @"buriedValue"}},
    @"key2" : @"value2"
  };

  // Then
  XCTAssertEqualObjects(csProperties, test);
}

- (void)testToCommonSchemaLogForTargetToken {

  // If
  NSString *targetToken = @"aTarget-Token";
  NSString *name = @"SolarEclipse";
  NSDictionary *properties =
      @{ @"StartedAt" : @"11:00",
         @"VisibleFrom" : @"Redmond" };
  NSDate *timestamp = [NSDate date];
  MSDevice *device = [MSDevice new];
  NSString *oemName = @"Peach";
  NSString *model = @"pPhone1,6";
  NSString *locale = @"en_US";
  NSString *osName = @"pOS";
  NSString *osVer = @"1.2.4";
  NSString *osBuild = @"2342EEWF";
  NSString *appNamespace = @"com.contoso.peach.app";
  NSString *appVersion = @"3.1.2";
  NSString *carrierName = @"P-Telecom";
  NSString *sdkVersion = @"1.0.0";
  device.oemName = oemName;
  device.model = model;
  device.locale = locale;
  device.osName = osName;
  device.osVersion = osVer;
  device.osBuild = osBuild;
  device.appNamespace = appNamespace;
  device.appVersion = appVersion;
  device.carrierName = carrierName;
  device.sdkName = @"appcenter.ios";
  device.sdkVersion = sdkVersion;
  device.timeZoneOffset = @(-420);
  self.sut.device = device;
  self.sut.timestamp = timestamp;
  self.sut.name = name;
  self.sut.properties = properties;

  // When
  MSCommonSchemaLog *csLog =
      [self.sut toCommonSchemaLogForTargetToken:targetToken];

  // Then
  XCTAssertEqualObjects(csLog.ver, kMSCSVerValue);
  XCTAssertEqualObjects(csLog.name, name);
  XCTAssertEqualObjects(csLog.timestamp, timestamp);
  XCTAssertEqualObjects(csLog.iKey, @"o:aTarget");
  XCTAssertEqualObjects(csLog.ext.protocolExt.devMake, oemName);
  XCTAssertEqualObjects(csLog.ext.protocolExt.devModel, model);
  XCTAssertEqualObjects(
      csLog.ext.appExt.locale,
      [[[NSBundle mainBundle] preferredLocalizations] firstObject]);
  XCTAssertEqualObjects(csLog.ext.osExt.name, osName);
  XCTAssertEqualObjects(csLog.ext.osExt.ver, @"Version 1.2.4 (Build 2342EEWF)");
  XCTAssertEqualObjects(csLog.ext.appExt.appId, @"I:com.contoso.peach.app");
  XCTAssertEqualObjects(csLog.ext.appExt.ver, device.appVersion);
  XCTAssertEqualObjects(csLog.ext.netExt.provider, carrierName);
  XCTAssertEqualObjects(csLog.ext.sdkExt.libVer, @"appcenter.ios-1.0.0");
  XCTAssertEqualObjects(csLog.ext.locExt.tz, @"-07:00");
  XCTAssertEqualObjects(csLog.data.properties, properties);
}

@end
