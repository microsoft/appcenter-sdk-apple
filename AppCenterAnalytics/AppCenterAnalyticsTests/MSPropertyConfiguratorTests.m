#import "MSAnalyticsTransmissionTargetInternal.h"
#import "MSAppExtension.h"
#import "MSBooleanTypedProperty.h"
#import "MSCSExtensions.h"
#import "MSChannelGroupProtocol.h"
#import "MSCommonSchemaLog.h"
#import "MSDateTimeTypedProperty.h"
#import "MSDeviceExtension.h"
#import "MSDoubleTypedProperty.h"
#import "MSLongTypedProperty.h"
#import "MSPropertyConfiguratorInternal.h"
#import "MSPropertyConfiguratorPrivate.h"
#import "MSStringTypedProperty.h"
#import "MSTestFrameworks.h"
#import "MSUserExtension.h"

@interface MSPropertyConfiguratorTests : XCTestCase

@property(nonatomic) MSPropertyConfigurator *sut;
@property(nonatomic) MSAnalyticsTransmissionTarget *transmissionTarget;
@property(nonatomic) MSAnalyticsTransmissionTarget *parentTarget;
@property(nonatomic) NSString *targetToken;

@end

@implementation MSPropertyConfiguratorTests

- (void)setUp {
  [super setUp];
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  self.targetToken = @"123";
  self.parentTarget = OCMPartialMock([[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:@"456"
                                                                                               parentTarget:nil
                                                                                               channelGroup:channelGroupMock]);
  self.transmissionTarget = OCMPartialMock([[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:self.targetToken
                                                                                                     parentTarget:self.parentTarget
                                                                                                     channelGroup:channelGroupMock]);
  OCMStub([self.transmissionTarget isEnabled]).andReturn(YES);
  self.sut = [[MSPropertyConfigurator alloc] initWithTransmissionTarget:self.transmissionTarget];
  OCMStub(self.transmissionTarget.propertyConfigurator).andReturn(self.sut);
}

- (void)tearDown {
  [super tearDown];
  self.sut = nil;
}

- (void)testInitializationWorks {

  // Then
  XCTAssertNotNil(self.sut);
  XCTAssertNil(self.sut.deviceId);
}

- (void)testCollectsDeviceIdWhenShouldCollectDeviceIdIsTrue {
#if !TARGET_OS_OSX

  // If
  NSUUID *fakeIdentifier = [[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"];
  NSString *expectedLocalId = [NSString stringWithFormat:@"i:%@", [fakeIdentifier UUIDString]];
  id deviceMock = OCMClassMock([UIDevice class]);
  OCMStub([deviceMock identifierForVendor]).andReturn(fakeIdentifier);
  OCMStub([deviceMock currentDevice]).andReturn(deviceMock);
  MSCSExtensions *extensions = [MSCSExtensions new];
  extensions.deviceExt = OCMPartialMock([MSDeviceExtension new]);
  MSCommonSchemaLog *mockLog = OCMPartialMock([MSCommonSchemaLog new]);
  mockLog.ext = extensions;
  mockLog.tag = self.transmissionTarget;
  [mockLog addTransmissionTargetToken:self.transmissionTarget.transmissionTargetToken];

  // When
  [self.sut collectDeviceId];
  [self.sut channel:OCMOCK_ANY prepareLog:mockLog];

  // Then
  OCMVerify([extensions.deviceExt setLocalId:expectedLocalId]);

  // Clean up.
  [deviceMock stopMocking];
#endif
}

- (void)testDeviceIdDoesNotPropagate {

  // If
  MSCommonSchemaLog *mockLog = OCMPartialMock([MSCommonSchemaLog new]);
  mockLog.ext = [MSCSExtensions new];
  mockLog.ext.deviceExt = OCMPartialMock([MSDeviceExtension new]);
  [mockLog addTransmissionTargetToken:self.transmissionTarget.transmissionTargetToken];
  [self.parentTarget.propertyConfigurator collectDeviceId];

  // When
  [self.sut channel:OCMOCK_ANY prepareLog:mockLog];

  // Then
  XCTAssertNil(self.sut.deviceId);
}

- (void)testRemoveNonExistingEventProperty {

  // When
  [self.sut removeEventPropertyForKey:@"APropKey"];

  // Then
  XCTAssertTrue([self.sut.eventProperties isEmpty]);
}

- (void)testSetAndRemoveEventPropertiesWithNilKeys {

// When
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
  [self.sut removeEventPropertyForKey:nil];

  // Then
  XCTAssertTrue([self.sut.eventProperties isEmpty]);

  // When
  [self.sut setEventPropertyString:@"val1" forKey:nil];
  [self.sut setEventPropertyDouble:234 forKey:nil];
  [self.sut setEventPropertyInt64:23 forKey:nil];
  [self.sut setEventPropertyBool:YES forKey:nil];
  [self.sut setEventPropertyDate:[NSDate new] forKey:nil];
#pragma clang diagnostic pop

  // Then
  XCTAssertTrue([self.sut.eventProperties isEmpty]);
}

- (void)testSetEventPropertiesWithInvalidValues {

  // If
  NSString *propStringKey = @"propString";
  NSString *propDateKey = @"propDate";
  NSString *propNanKey = @"propNan";
  NSString *propInfinityKey = @"propInfinity";

// When
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
  [self.sut removeEventPropertyForKey:nil];

  // Then
  XCTAssertTrue([self.sut.eventProperties isEmpty]);

  // When
  [self.sut setEventPropertyString:nil forKey:propStringKey];
  [self.sut setEventPropertyDate:nil forKey:propDateKey];
#pragma clang diagnostic pop
  [self.sut setEventPropertyDouble:INFINITY forKey:propInfinityKey];
  [self.sut setEventPropertyDouble:-INFINITY forKey:propInfinityKey];
  [self.sut setEventPropertyDouble:NAN forKey:propNanKey];

  // Then
  XCTAssertTrue([self.sut.eventProperties isEmpty]);
}

- (void)testSetAndRemoveEventProperty {

  // If
  NSString *propStringKey = @"propString";
  NSString *propStringValue = @"val1";
  NSString *propDateKey = @"propDate";
  NSDate *propDateValue = [NSDate date];
  NSString *propDoubleKey = @"propDouble";
  double propDoubleValue = 927398.82939;
  NSString *propInt64Key = @"propInt64";
  int64_t propInt64Value = 5000000000;
  NSString *propBoolKey = @"propBool";
  BOOL propBoolValue = YES;

  // When
  // Set properties of all types.
  [self.sut setEventPropertyString:propStringValue forKey:propStringKey];
  [self.sut setEventPropertyDate:propDateValue forKey:propDateKey];
  [self.sut setEventPropertyDouble:propDoubleValue forKey:propDoubleKey];
  [self.sut setEventPropertyInt64:propInt64Value forKey:propInt64Key];
  [self.sut setEventPropertyBool:propBoolValue forKey:propBoolKey];

  // Then
  XCTAssertEqual([self.sut.eventProperties.properties count], 5);
  XCTAssertEqualObjects(((MSStringTypedProperty *)(self.sut.eventProperties.properties[propStringKey])).value, propStringValue);
  XCTAssertEqualObjects(((MSDateTimeTypedProperty *)(self.sut.eventProperties.properties[propDateKey])).value, propDateValue);
  XCTAssertEqual(((MSDoubleTypedProperty *)(self.sut.eventProperties.properties[propDoubleKey])).value, propDoubleValue);
  XCTAssertEqual(((MSLongTypedProperty *)(self.sut.eventProperties.properties[propInt64Key])).value, propInt64Value);
  XCTAssertEqual(((MSBooleanTypedProperty *)(self.sut.eventProperties.properties[propBoolKey])).value, propBoolValue);

  // When
  [self.sut removeEventPropertyForKey:propStringKey];

  // Then
  XCTAssertEqual([self.sut.eventProperties.properties count], 4);
  XCTAssertEqualObjects(((MSDateTimeTypedProperty *)(self.sut.eventProperties.properties[propDateKey])).value, propDateValue);
  XCTAssertEqual(((MSDoubleTypedProperty *)(self.sut.eventProperties.properties[propDoubleKey])).value, propDoubleValue);
  XCTAssertEqual(((MSLongTypedProperty *)(self.sut.eventProperties.properties[propInt64Key])).value, propInt64Value);
  XCTAssertEqual(((MSBooleanTypedProperty *)(self.sut.eventProperties.properties[propBoolKey])).value, propBoolValue);
}

- (void)testPropertiesAreNotAppliedToLogsOfDifferentTagWithSameToken {

  // If
  id<MSChannelProtocol> channelMock = OCMProtocolMock(@protocol(MSChannelProtocol));
  MSCommonSchemaLog *csLog = [MSCommonSchemaLog new];
  csLog.ext = [MSCSExtensions new];
  csLog.ext.appExt = [MSAppExtension new];
  csLog.ext.userExt = [MSUserExtension new];
  [csLog addTransmissionTargetToken:self.targetToken];
  [self.sut setAppLocale:@"en-US"];
  [self.sut setAppVersion:@"1.0.0"];
  [self.sut setAppName:@"tim"];
  [self.sut setUserId:@"c:alice"];

  // When
  [self.sut channel:channelMock prepareLog:csLog];

  // Then
  XCTAssertNil(csLog.ext.appExt.ver);
  XCTAssertNil(csLog.ext.appExt.locale);
  XCTAssertNil(csLog.ext.appExt.name);
  XCTAssertNil(csLog.ext.userExt.localId);
}

- (void)testSetUserId {

  // When
  [self.sut setUserId:@"alice"];

  // Then
  XCTAssertEqualObjects(self.sut.userId, @"c:alice");

  // When
  [self.sut setUserId:@"c:bob"];

  // Then
  XCTAssertEqualObjects(self.sut.userId, @"c:bob");
}

@end
