#import "MSAbstractLogInternal.h"
#import "MSChannelDelegate.h"
#import "MSChannelGroupDefault.h"
#import "MSChannelGroupDefaultPrivate.h"
#import "MSChannelUnitConfiguration.h"
#import "MSChannelUnitDefault.h"
#import "MSHttpIngestionPrivate.h"
#import "MSIngestionProtocol.h"
#import "MSMockLog.h"
#import "MSStorage.h"
#import "MSTestFrameworks.h"

@interface MSChannelGroupDefaultTests : XCTestCase
@end

@implementation MSChannelGroupDefaultTests

#pragma mark - Tests

- (void)testNewInstanceWasInitialisedCorrectly {

  // If
  id ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));

  // When
  MSChannelGroupDefault *sut =
      [[MSChannelGroupDefault alloc] initWithIngestion:ingestionMock];

  // Then
  assertThat(sut, notNilValue());
  assertThat(sut.logsDispatchQueue, notNilValue());
  assertThat(sut.channels, isEmpty());
  assertThat(sut.ingestion, equalTo(ingestionMock));
  assertThat(sut.storage, notNilValue());
}

- (void)testAddNewChannel {

  // If
  NSString *groupId = @"AppCenter";
  MSPriority priority = MSPriorityDefault;
  float flushInterval = 1.0;
  NSUInteger batchSizeLimit = 10;
  NSUInteger pendingBatchesLimit = 3;
  id<MSIngestionProtocol> ingestionMock =
      OCMProtocolMock(@protocol(MSIngestionProtocol));
  MSChannelGroupDefault *sut =
      [[MSChannelGroupDefault alloc] initWithIngestion:ingestionMock];

  // Then
  assertThat(sut.channels, isEmpty());

  // When
  id<MSChannelUnitProtocol> addedChannel =
      [sut addChannelUnitWithConfiguration:
               [[MSChannelUnitConfiguration alloc]
                       initWithGroupId:groupId
                              priority:priority
                         flushInterval:flushInterval
                        batchSizeLimit:batchSizeLimit
                   pendingBatchesLimit:pendingBatchesLimit]];

  // Then
  XCTAssertTrue([sut.channels containsObject:addedChannel]);
  assertThat(addedChannel, notNilValue());
  XCTAssertTrue(addedChannel.configuration.priority == priority);
  assertThatFloat(addedChannel.configuration.flushInterval,
                  equalToFloat(flushInterval));
  assertThatUnsignedLong(addedChannel.configuration.batchSizeLimit,
                         equalToUnsignedLong(batchSizeLimit));
  assertThatUnsignedLong(addedChannel.configuration.pendingBatchesLimit,
                         equalToUnsignedLong(pendingBatchesLimit));
}

- (void)testAddNewChannelWithDefaultIngestion {

  // If
  id<MSIngestionProtocol> ingestionMock =
      OCMProtocolMock(@protocol(MSIngestionProtocol));
  MSChannelGroupDefault *sut =
      [[MSChannelGroupDefault alloc] initWithIngestion:ingestionMock];

  // When
  MSChannelUnitDefault *channelUnit = (MSChannelUnitDefault *)[sut
      addChannelUnitWithConfiguration:[MSChannelUnitConfiguration new]];

  // Then
  XCTAssertEqual(ingestionMock, channelUnit.ingestion);
}

- (void)testAddChannelWithCustomIngestion {

  // If
  id<MSIngestionProtocol> ingestionMockDefault =
      OCMProtocolMock(@protocol(MSIngestionProtocol));
  id<MSIngestionProtocol> ingestionMockCustom =
      OCMProtocolMock(@protocol(MSIngestionProtocol));
  MSChannelGroupDefault *sut =
      [[MSChannelGroupDefault alloc] initWithIngestion:ingestionMockDefault];

  // When
  MSChannelUnitDefault *channelUnit = (MSChannelUnitDefault *)[sut
      addChannelUnitWithConfiguration:[MSChannelUnitConfiguration new]
                        withIngestion:ingestionMockCustom];

  // Then
  XCTAssertNotEqual(ingestionMockDefault, channelUnit.ingestion);
  XCTAssertEqual(ingestionMockCustom, channelUnit.ingestion);
}

- (void)testDelegatesConcurrentAccess {

  // If
  NSString *groupId = @"AppCenter";
  MSChannelGroupDefault *sut = [[MSChannelGroupDefault alloc]
      initWithIngestion:OCMProtocolMock(@protocol(MSIngestionProtocol))];
  MSAbstractLog *log = [MSAbstractLog new];
  for (int j = 0; j < 10; j++) {
    id mockDelegate = OCMProtocolMock(@protocol(MSChannelDelegate));
    [sut addDelegate:mockDelegate];
  }
  id<MSChannelUnitProtocol> addedChannel = [sut
      addChannelUnitWithConfiguration:[[MSChannelUnitConfiguration alloc]
                                              initWithGroupId:groupId
                                                     priority:MSPriorityDefault
                                                flushInterval:1.0
                                               batchSizeLimit:10
                                          pendingBatchesLimit:3]];

  // When
  void (^block)() = ^{
    for (int i = 0; i < 10; i++) {
      [addedChannel enqueueItem:log];
    }
    for (int i = 0; i < 100; i++) {
      [sut addDelegate:OCMProtocolMock(@protocol(MSChannelDelegate))];
    }
  };

  // Then
  XCTAssertNoThrow(block());
}

- (void)testSetEnabled {

  // If
  MSHttpIngestion *ingestionMock = OCMClassMock([MSHttpIngestion class]);
  id<MSChannelUnitProtocol> channelMock =
      OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id<MSChannelDelegate> delegateMock =
      OCMProtocolMock(@protocol(MSChannelDelegate));
  MSChannelGroupDefault *sut =
      [[MSChannelGroupDefault alloc] initWithIngestion:ingestionMock];
  [sut addDelegate:delegateMock];
  [sut.channels addObject:channelMock];

  // When
  [sut setEnabled:NO andDeleteDataOnDisabled:YES];

  // Then
  OCMVerify([ingestionMock setEnabled:NO andDeleteDataOnDisabled:YES]);
  OCMVerify([channelMock setEnabled:NO andDeleteDataOnDisabled:YES]);
  OCMVerify(
      [delegateMock channel:sut didSetEnabled:NO andDeleteDataOnDisabled:YES]);
}

- (void)testResume {

  // If
  MSHttpIngestion *ingestionMock = OCMClassMock([MSHttpIngestion class]);
  id<MSChannelUnitProtocol> channelMock =
      OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  MSChannelGroupDefault *sut =
      [[MSChannelGroupDefault alloc] initWithIngestion:ingestionMock];
  [sut.channels addObject:channelMock];

  // When
  [sut resume];

  // Then
  OCMVerify([ingestionMock setEnabled:YES andDeleteDataOnDisabled:NO]);
  dispatch_sync(sut.logsDispatchQueue, ^{
                });
  OCMVerify([channelMock resume]);
}

- (void)testSuspend {

  // If
  MSHttpIngestion *ingestionMock = OCMClassMock([MSHttpIngestion class]);
  id<MSChannelUnitProtocol> channelMock =
      OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  MSChannelGroupDefault *sut =
      [[MSChannelGroupDefault alloc] initWithIngestion:ingestionMock];
  [sut.channels addObject:channelMock];

  // When
  [sut suspend];

  // Then
  OCMVerify([ingestionMock setEnabled:NO andDeleteDataOnDisabled:NO]);
  dispatch_sync(sut.logsDispatchQueue, ^{
                });
  OCMVerify([channelMock suspend]);
}

- (void)testChannelUnitIsCorrectlyInitialized {

  // If
  NSString *groupId = @"AppCenter";
  MSPriority priority = MSPriorityDefault;
  float flushInterval = 1.0;
  NSUInteger batchSizeLimit = 10;
  NSUInteger pendingBatchesLimit = 3;
  id ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));
  MSChannelGroupDefault *sut =
      [[MSChannelGroupDefault alloc] initWithIngestion:ingestionMock];
  id channelUnitMock = OCMClassMock([MSChannelUnitDefault class]);
  OCMStub([channelUnitMock alloc]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock initWithIngestion:OCMOCK_ANY
                                     storage:OCMOCK_ANY
                               configuration:OCMOCK_ANY
                           logsDispatchQueue:OCMOCK_ANY])
      .andReturn(channelUnitMock);

  // When
  [sut addChannelUnitWithConfiguration:
           [[MSChannelUnitConfiguration alloc]
                   initWithGroupId:groupId
                          priority:priority
                     flushInterval:flushInterval
                    batchSizeLimit:batchSizeLimit
               pendingBatchesLimit:pendingBatchesLimit]];
  dispatch_sync(sut.logsDispatchQueue, ^{
                });

  // Then
  OCMVerify([channelUnitMock addDelegate:(id<MSChannelDelegate>)sut]);
  OCMVerify([channelUnitMock flushQueue]);

  // Clear
  [channelUnitMock stopMocking];
}

- (void)testDelegateCalledWhenAddingNewChannelUnit {

  // Test that delegates are called whenever a new channel unit is added to the
  // channel group.

  // If
  NSString *groupId = @"AnyGroupId";
  MSPriority priority = MSPriorityDefault;
  float flushInterval = 1.0;
  NSUInteger batchSizeLimit = 10;
  NSUInteger pendingBatchesLimit = 3;
  id ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));
  MSChannelGroupDefault *sut =
      [[MSChannelGroupDefault alloc] initWithIngestion:ingestionMock];
  id channelUnitMock = OCMClassMock([MSChannelUnitDefault class]);
  OCMStub([channelUnitMock alloc]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock initWithIngestion:OCMOCK_ANY
                                     storage:OCMOCK_ANY
                               configuration:OCMOCK_ANY
                           logsDispatchQueue:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  id delegateMock1 = OCMProtocolMock(@protocol(MSChannelDelegate));
  OCMExpect([delegateMock1 channelGroup:sut didAddChannelUnit:channelUnitMock]);
  id delegateMock2 = OCMProtocolMock(@protocol(MSChannelDelegate));
  OCMExpect([delegateMock2 channelGroup:sut didAddChannelUnit:channelUnitMock]);
  [sut addDelegate:delegateMock1];
  [sut addDelegate:delegateMock2];

  // When
  [sut addChannelUnitWithConfiguration:
           [[MSChannelUnitConfiguration alloc]
                   initWithGroupId:groupId
                          priority:priority
                     flushInterval:flushInterval
                    batchSizeLimit:batchSizeLimit
               pendingBatchesLimit:pendingBatchesLimit]];

  // Then
  OCMVerifyAll(delegateMock1);
  OCMVerifyAll(delegateMock2);

  // Clear
  [channelUnitMock stopMocking];
}

@end
