#import "MSAnalyticsTransmissionTargetInternal.h"
#import "MSChannelGroupProtocol.h"
#import "MSCommonSchemaLog.h"
#import "MSCSExtensions.h"
#import "MSDeviceExtension.h"
#import "MSPropertyConfiguratorInternal.h"
#import "MSPropertyConfiguratorPrivate.h"
#import "MSTestFrameworks.h"
#import "MSStringTypedProperty.h"

@interface MSPropertyConfiguratorTests : XCTestCase

@property(nonatomic) MSPropertyConfigurator *sut;
@property(nonatomic) MSAnalyticsTransmissionTarget *transmissionTarget;
@property(nonatomic) MSAnalyticsTransmissionTarget *parentTarget;

@end

@implementation MSPropertyConfiguratorTests

- (void)setUp {
  [super setUp];
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  self.parentTarget = OCMPartialMock(
      [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:@"456" parentTarget:nil channelGroup:channelGroupMock]);
  self.transmissionTarget = OCMPartialMock([[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:@"123"
                                                                                                     parentTarget:self.parentTarget
                                                                                                     channelGroup:channelGroupMock]);
  OCMStub([self.transmissionTarget isEnabled]).andReturn(YES);
  self.sut = [[MSPropertyConfigurator alloc] initWithTransmissionTarget:self.transmissionTarget];
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

- (void)testSetAndRemoveEventProperty {

  // If
  NSString *prop1Key = @"prop1";
  NSString *prop1Value = @"val1";

  // When
  [self.sut removeEventPropertyForKey:prop1Key];

  // Then
  XCTAssertTrue([self.sut.eventProperties isEmpty]);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
  // When
  [self.sut removeEventPropertyForKey:nil];

  // Then
  XCTAssertTrue([self.sut.eventProperties isEmpty]);

  // When
  [self.sut setEventPropertyString:nil forKey:prop1Key];

  // Then
  XCTAssertTrue([self.sut.eventProperties isEmpty]);

  // When
  [self.sut setEventPropertyString:prop1Value forKey:nil];

  // Then
  XCTAssertTrue([self.sut.eventProperties isEmpty]);
#pragma clang diagnostic pop

  // When
  [self.sut setEventPropertyString:prop1Value forKey:prop1Key];

  // Then
  XCTAssertEqual([self.sut.eventProperties.properties count], 1);
  XCTAssertEqual(((MSStringTypedProperty *)(self.sut.eventProperties.properties[prop1Key])).value, prop1Value);

  // If
  NSString *prop2Key = @"prop2";
  NSString *prop2Value = @"val2";

  // When
  [self.sut setEventPropertyString:prop2Value forKey:prop2Key];

  // Then
  XCTAssertEqual([self.sut.eventProperties.properties count], 2);
  XCTAssertEqual(((MSStringTypedProperty *)(self.sut.eventProperties.properties[prop1Key])).value, prop1Value);
  XCTAssertEqual(((MSStringTypedProperty *)(self.sut.eventProperties.properties[prop2Key])).value, prop2Value);

  // When
  [self.sut removeEventPropertyForKey:prop1Key];

  // Then
  XCTAssertEqual([self.sut.eventProperties.properties count], 1);
  XCTAssertEqual(((MSStringTypedProperty *)(self.sut.eventProperties.properties[prop2Key])).value, prop2Value);
}

@end
