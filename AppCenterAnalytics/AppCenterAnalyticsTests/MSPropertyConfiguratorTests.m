#import "MSAnalyticsTransmissionTargetInternal.h"
#import "MSChannelGroupProtocol.h"
#import "MSCommonSchemaLog.h"
#import "MSCSExtensions.h"
#import "MSDeviceExtension.h"
#import "MSPropertyConfiguratorInternal.h"
#import "MSPropertyConfiguratorPrivate.h"
#import "MSTestFrameworks.h"

@interface MSPropertyConfiguratorTests : XCTestCase

@property(nonatomic) MSPropertyConfigurator *sut;
@property(nonatomic) MSAnalyticsTransmissionTarget *transmissionTarget;
@property(nonatomic) MSAnalyticsTransmissionTarget *parentTarget;
@property(nonatomic) id configuratorClassMock;

@end

@implementation MSPropertyConfiguratorTests

- (void)setUp {
  [super setUp];
  self.sut = [MSPropertyConfigurator new];

  // Mock the init so that self.sut can be injected into the target.
  self.configuratorClassMock = OCMClassMock([MSPropertyConfigurator class]);
  OCMStub([self.configuratorClassMock alloc]).andReturn(self.configuratorClassMock);
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));

  /*
   * Need to stub this twice with OCMOCK_ANY, because passing self.parentTarget won't work until the targets have been initialized, but the
   * stub must be invoked inside the "init" method.
   */
  OCMStub([self.configuratorClassMock initWithTransmissionTarget:OCMOCK_ANY]).andReturn([MSPropertyConfigurator new]);
  self.parentTarget = OCMPartialMock(
      [[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:@"456" parentTarget:nil channelGroup:channelGroupMock]);

  // Need to reset the class mock.
  [self.configuratorClassMock stopMocking];
  self.configuratorClassMock = OCMClassMock([MSPropertyConfigurator class]);
  OCMStub([self.configuratorClassMock alloc]).andReturn(self.configuratorClassMock);
  OCMStub([self.configuratorClassMock initWithTransmissionTarget:OCMOCK_ANY]).andReturn(self.sut);
  self.transmissionTarget = OCMPartialMock([[MSAnalyticsTransmissionTarget alloc] initWithTransmissionTargetToken:@"123"
                                                                                                     parentTarget:self.parentTarget
                                                                                                     channelGroup:channelGroupMock]);
  OCMStub([self.transmissionTarget isEnabled]).andReturn(YES);
  self.sut.transmissionTarget = self.transmissionTarget;
}

- (void)tearDown {
  [super tearDown];
  self.sut = nil;
  [self.configuratorClassMock stopMocking];
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

@end
