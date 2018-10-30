#import "MSAbstractLogInternal.h"
#import "MSAppCenterIngestion.h"
#import "MSChannelDelegate.h"
#import "MSChannelGroupDefault.h"
#import "MSChannelGroupDefaultPrivate.h"
#import "MSChannelUnitConfiguration.h"
#import "MSChannelUnitDefault.h"
#import "MSIngestionProtocol.h"
#import "MSMockLog.h"
#import "MSStorage.h"
#import "MSTestFrameworks.h"

@interface MSChannelGroupDefaultTests : XCTestCase

@property MSChannelUnitConfiguration *validConfiguration;

@end

@implementation MSChannelGroupDefaultTests

- (void)setUp {
  NSString *groupId = @"AppCenter";
  MSPriority priority = MSPriorityDefault;
  float flushInterval = 1.0;
  NSUInteger batchSizeLimit = 10;
  NSUInteger pendingBatchesLimit = 3;
  _validConfiguration = [[MSChannelUnitConfiguration alloc] initWithGroupId:groupId
                                                                   priority:priority
                                                              flushInterval:flushInterval
                                                             batchSizeLimit:batchSizeLimit
                                                        pendingBatchesLimit:pendingBatchesLimit];
}

#pragma mark - Tests

- (void)testNewInstanceWasInitialisedCorrectly {

  // If
  id ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));

  // When
  MSChannelGroupDefault *sut = [[MSChannelGroupDefault alloc] initWithIngestion:ingestionMock];

  // Then
  assertThat(sut, notNilValue());
  assertThat(sut.logsDispatchQueue, notNilValue());
  assertThat(sut.channels, isEmpty());
  assertThat(sut.ingestion, equalTo(ingestionMock));
  assertThat(sut.storage, notNilValue());
}

- (void)testAddNewChannel {

  // If
  id<MSIngestionProtocol> ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));
  MSChannelGroupDefault *sut = [[MSChannelGroupDefault alloc] initWithIngestion:ingestionMock];

  // Then
  assertThat(sut.channels, isEmpty());

  // When
  id<MSChannelUnitProtocol> addedChannel = [sut addChannelUnitWithConfiguration:self.validConfiguration];

  // Then
  XCTAssertTrue([sut.channels containsObject:addedChannel]);
  assertThat(addedChannel, notNilValue());
  XCTAssertTrue(addedChannel.configuration.priority == self.validConfiguration.priority);
  assertThatFloat(addedChannel.configuration.flushInterval, equalToFloat(self.validConfiguration.flushInterval));
  assertThatUnsignedLong(addedChannel.configuration.batchSizeLimit, equalToUnsignedLong(self.validConfiguration.batchSizeLimit));
  assertThatUnsignedLong(addedChannel.configuration.pendingBatchesLimit, equalToUnsignedLong(self.validConfiguration.pendingBatchesLimit));
}

- (void)testAddNewChannelWithDefaultIngestion {

  // If
  id<MSIngestionProtocol> ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));
  MSChannelGroupDefault *sut = [[MSChannelGroupDefault alloc] initWithIngestion:ingestionMock];

  // When
  MSChannelUnitDefault *channelUnit = (MSChannelUnitDefault *)[sut addChannelUnitWithConfiguration:self.validConfiguration];

  // Then
  XCTAssertEqual(ingestionMock, channelUnit.ingestion);
}

- (void)testAddChannelWithCustomIngestion {

  // If
  id<MSIngestionProtocol> ingestionMockDefault = OCMProtocolMock(@protocol(MSIngestionProtocol));
  id<MSIngestionProtocol> ingestionMockCustom = OCMProtocolMock(@protocol(MSIngestionProtocol));
  MSChannelGroupDefault *sut = [[MSChannelGroupDefault alloc] initWithIngestion:ingestionMockDefault];

  // When
  MSChannelUnitDefault *channelUnit = (MSChannelUnitDefault *)[sut addChannelUnitWithConfiguration:[MSChannelUnitConfiguration new]
                                                                                     withIngestion:ingestionMockCustom];

  // Then
  XCTAssertNotEqual(ingestionMockDefault, channelUnit.ingestion);
  XCTAssertEqual(ingestionMockCustom, channelUnit.ingestion);
}

- (void)testDelegatesConcurrentAccess {

  // If
  MSChannelGroupDefault *sut = [[MSChannelGroupDefault alloc] initWithIngestion:OCMProtocolMock(@protocol(MSIngestionProtocol))];
  MSAbstractLog *log = [MSAbstractLog new];
  for (int j = 0; j < 10; j++) {
    id mockDelegate = OCMProtocolMock(@protocol(MSChannelDelegate));
    [sut addDelegate:mockDelegate];
  }
  id<MSChannelUnitProtocol> addedChannel = [sut addChannelUnitWithConfiguration:self.validConfiguration];

  // When
  void (^block)(void) = ^{
    for (int i = 0; i < 10; i++) {
      [addedChannel enqueueItem:log flags:MSFlagsDefault];
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
  MSAppCenterIngestion *ingestionMock = OCMClassMock(MSAppCenterIngestion.class);
  id<MSChannelUnitProtocol> channelMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id<MSChannelDelegate> delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  MSChannelGroupDefault *sut = [[MSChannelGroupDefault alloc] initWithIngestion:ingestionMock];
  [sut addDelegate:delegateMock];
  [sut.channels addObject:channelMock];

  // When
  [sut setEnabled:NO andDeleteDataOnDisabled:YES];

  // Then
  OCMVerify([ingestionMock setEnabled:NO andDeleteDataOnDisabled:YES]);
  OCMVerify([channelMock setEnabled:NO andDeleteDataOnDisabled:YES]);
  OCMVerify([delegateMock channel:sut didSetEnabled:NO andDeleteDataOnDisabled:YES]);
}

- (void)testResume {

  // If
  MSAppCenterIngestion *ingestionMock = OCMClassMock(MSAppCenterIngestion.class);
  id<MSChannelUnitProtocol> channelMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  MSChannelGroupDefault *sut = [[MSChannelGroupDefault alloc] initWithIngestion:ingestionMock];
  [sut.channels addObject:channelMock];
  NSObject *token = [NSObject new];

  // When
  [sut resumeWithIdentifyingObject:token];

  // Then
  OCMVerify([ingestionMock setEnabled:YES andDeleteDataOnDisabled:NO]);
  dispatch_sync(sut.logsDispatchQueue, ^{
                });
  OCMVerify([channelMock resumeWithIdentifyingObject:token]);
}

- (void)testPause {

  // If
  MSAppCenterIngestion *ingestionMock = OCMClassMock(MSAppCenterIngestion.class);
  id<MSChannelUnitProtocol> channelMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  MSChannelGroupDefault *sut = [[MSChannelGroupDefault alloc] initWithIngestion:ingestionMock];
  [sut.channels addObject:channelMock];
  NSObject *identifyingObject = [NSObject new];

  // When
  [sut pauseWithIdentifyingObject:identifyingObject];

  // Then
  OCMVerify([ingestionMock setEnabled:NO andDeleteDataOnDisabled:NO]);
  dispatch_sync(sut.logsDispatchQueue, ^{
                });
  OCMVerify([channelMock pauseWithIdentifyingObject:identifyingObject]);
}

- (void)testChannelUnitIsCorrectlyInitialized {

  // If
  id ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));
  MSChannelGroupDefault *sut = [[MSChannelGroupDefault alloc] initWithIngestion:ingestionMock];
  id channelUnitMock = OCMClassMock([MSChannelUnitDefault class]);
  OCMStub([channelUnitMock alloc]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock initWithIngestion:OCMOCK_ANY storage:OCMOCK_ANY configuration:OCMOCK_ANY logsDispatchQueue:OCMOCK_ANY])
      .andReturn(channelUnitMock);

  // When
  [sut addChannelUnitWithConfiguration:self.validConfiguration];
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
  id ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));
  MSChannelGroupDefault *sut = [[MSChannelGroupDefault alloc] initWithIngestion:ingestionMock];
  id channelUnitMock = OCMClassMock([MSChannelUnitDefault class]);
  OCMStub([channelUnitMock alloc]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock initWithIngestion:OCMOCK_ANY storage:OCMOCK_ANY configuration:OCMOCK_ANY logsDispatchQueue:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  id delegateMock1 = OCMProtocolMock(@protocol(MSChannelDelegate));
  OCMExpect([delegateMock1 channelGroup:sut didAddChannelUnit:channelUnitMock]);
  id delegateMock2 = OCMProtocolMock(@protocol(MSChannelDelegate));
  OCMExpect([delegateMock2 channelGroup:sut didAddChannelUnit:channelUnitMock]);
  [sut addDelegate:delegateMock1];
  [sut addDelegate:delegateMock2];

  // When
  [sut addChannelUnitWithConfiguration:self.validConfiguration];

  // Then
  OCMVerifyAll(delegateMock1);
  OCMVerifyAll(delegateMock2);

  // Clear
  [channelUnitMock stopMocking];
}

- (void)testDelegateCalledWhenChannelUnitPaused {

  // If
  NSObject *identifyingObject = [NSObject new];
  id ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));
  MSChannelGroupDefault *sut = [[MSChannelGroupDefault alloc] initWithIngestion:ingestionMock];
  id channelUnitMock = OCMClassMock([MSChannelUnitDefault class]);
  OCMStub([channelUnitMock alloc]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock initWithIngestion:OCMOCK_ANY storage:OCMOCK_ANY configuration:OCMOCK_ANY logsDispatchQueue:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  [sut addChannelUnitWithConfiguration:self.validConfiguration];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [sut addDelegate:delegateMock];

  // When
  [sut channel:channelUnitMock didPauseWithIdentifyingObject:identifyingObject];

  // Then
  OCMVerify([delegateMock channel:channelUnitMock didPauseWithIdentifyingObject:identifyingObject]);

  // Clear
  [channelUnitMock stopMocking];
}

- (void)testDelegateCalledWhenChannelUnitResumed {

  // If
  NSObject *identifyingObject = [NSObject new];
  id ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));
  MSChannelGroupDefault *sut = [[MSChannelGroupDefault alloc] initWithIngestion:ingestionMock];
  id channelUnitMock = OCMClassMock([MSChannelUnitDefault class]);
  OCMStub([channelUnitMock alloc]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock initWithIngestion:OCMOCK_ANY storage:OCMOCK_ANY configuration:OCMOCK_ANY logsDispatchQueue:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  [sut addChannelUnitWithConfiguration:self.validConfiguration];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [sut addDelegate:delegateMock];

  // When
  [sut channel:channelUnitMock didResumeWithIdentifyingObject:identifyingObject];

  // Then
  OCMVerify([delegateMock channel:channelUnitMock didResumeWithIdentifyingObject:identifyingObject]);

  // Clear
  [channelUnitMock stopMocking];
}

- (void)testDelegateCalledWhenChannelUnitPreparesLog {

  // If
  id<MSLog> mockLog = [MSMockLog new];
  id ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));
  MSChannelGroupDefault *sut = [[MSChannelGroupDefault alloc] initWithIngestion:ingestionMock];
  id channelUnitMock = OCMClassMock([MSChannelUnitDefault class]);
  OCMStub([channelUnitMock alloc]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock initWithIngestion:OCMOCK_ANY storage:OCMOCK_ANY configuration:OCMOCK_ANY logsDispatchQueue:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  [sut addChannelUnitWithConfiguration:self.validConfiguration];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [sut addDelegate:delegateMock];

  // When
  [sut channel:channelUnitMock prepareLog:mockLog];

  // Then
  OCMVerify([delegateMock channel:channelUnitMock prepareLog:mockLog]);

  // Clear
  [channelUnitMock stopMocking];
}

- (void)testDelegateCalledWhenChannelUnitDidPrepareLog {

  // If
  id<MSLog> mockLog = [MSMockLog new];
  NSString *internalId = @"mockId";
  id ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));
  MSChannelGroupDefault *sut = [[MSChannelGroupDefault alloc] initWithIngestion:ingestionMock];
  id channelUnitMock = OCMClassMock([MSChannelUnitDefault class]);
  OCMStub([channelUnitMock alloc]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock initWithIngestion:OCMOCK_ANY storage:OCMOCK_ANY configuration:OCMOCK_ANY logsDispatchQueue:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  [sut addChannelUnitWithConfiguration:self.validConfiguration];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [sut addDelegate:delegateMock];

  // When
  [sut channel:channelUnitMock didPrepareLog:mockLog internalId:internalId flags:MSFlagsDefault];

  // Then
  OCMVerify([delegateMock channel:channelUnitMock didPrepareLog:mockLog internalId:internalId flags:MSFlagsDefault]);

  // Clear
  [channelUnitMock stopMocking];
}

- (void)testDelegateCalledWhenChannelUnitDidCompleteEnqueueingLog {

  // If
  id<MSLog> mockLog = [MSMockLog new];
  NSString *internalId = @"mockId";
  id ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));
  MSChannelGroupDefault *sut = [[MSChannelGroupDefault alloc] initWithIngestion:ingestionMock];
  id channelUnitMock = OCMClassMock([MSChannelUnitDefault class]);
  OCMStub([channelUnitMock alloc]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock initWithIngestion:OCMOCK_ANY storage:OCMOCK_ANY configuration:OCMOCK_ANY logsDispatchQueue:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  [sut addChannelUnitWithConfiguration:self.validConfiguration];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [sut addDelegate:delegateMock];

  // When
  [sut channel:channelUnitMock didCompleteEnqueueingLog:mockLog internalId:internalId];

  // Then
  OCMVerify([delegateMock channel:channelUnitMock didCompleteEnqueueingLog:mockLog internalId:internalId]);

  // Clear
  [channelUnitMock stopMocking];
}

- (void)testDelegateCalledWhenChannelUnitWillSendLog {

  // If
  id<MSLog> mockLog = [MSMockLog new];
  id ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));
  MSChannelGroupDefault *sut = [[MSChannelGroupDefault alloc] initWithIngestion:ingestionMock];
  id channelUnitMock = OCMClassMock([MSChannelUnitDefault class]);
  OCMStub([channelUnitMock alloc]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock initWithIngestion:OCMOCK_ANY storage:OCMOCK_ANY configuration:OCMOCK_ANY logsDispatchQueue:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  [sut addChannelUnitWithConfiguration:self.validConfiguration];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [sut addDelegate:delegateMock];

  // When
  [sut channel:channelUnitMock willSendLog:mockLog];

  // Then
  OCMVerify([delegateMock channel:channelUnitMock willSendLog:mockLog]);

  // Clear
  [channelUnitMock stopMocking];
}

- (void)testDelegateCalledWhenChannelUnitDidSucceedSendingLog {

  // If
  id<MSLog> mockLog = [MSMockLog new];
  id ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));
  MSChannelGroupDefault *sut = [[MSChannelGroupDefault alloc] initWithIngestion:ingestionMock];
  id channelUnitMock = OCMClassMock([MSChannelUnitDefault class]);
  OCMStub([channelUnitMock alloc]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock initWithIngestion:OCMOCK_ANY storage:OCMOCK_ANY configuration:OCMOCK_ANY logsDispatchQueue:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  [sut addChannelUnitWithConfiguration:self.validConfiguration];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [sut addDelegate:delegateMock];

  // When
  [sut channel:channelUnitMock didSucceedSendingLog:mockLog];

  // Then
  OCMVerify([delegateMock channel:channelUnitMock didSucceedSendingLog:mockLog]);

  // Clear
  [channelUnitMock stopMocking];
}

- (void)testDelegateCalledWhenChannelUnitDidSetEnabled {

  // If
  id ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));
  MSChannelGroupDefault *sut = [[MSChannelGroupDefault alloc] initWithIngestion:ingestionMock];
  id channelUnitMock = OCMClassMock([MSChannelUnitDefault class]);
  OCMStub([channelUnitMock alloc]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock initWithIngestion:OCMOCK_ANY storage:OCMOCK_ANY configuration:OCMOCK_ANY logsDispatchQueue:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  [sut addChannelUnitWithConfiguration:self.validConfiguration];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [sut addDelegate:delegateMock];

  // When
  [sut channel:channelUnitMock didSetEnabled:YES andDeleteDataOnDisabled:YES];

  // Then
  OCMVerify([delegateMock channel:channelUnitMock didSetEnabled:YES andDeleteDataOnDisabled:YES]);

  // Clear
  [channelUnitMock stopMocking];
}

- (void)testDelegateCalledWhenChannelUnitDidFailSendingLog {

  // If
  id<MSLog> mockLog = [MSMockLog new];
  NSError *error = [NSError new];
  id ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));
  MSChannelGroupDefault *sut = [[MSChannelGroupDefault alloc] initWithIngestion:ingestionMock];
  id channelUnitMock = OCMClassMock([MSChannelUnitDefault class]);
  OCMStub([channelUnitMock alloc]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock initWithIngestion:OCMOCK_ANY storage:OCMOCK_ANY configuration:OCMOCK_ANY logsDispatchQueue:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  [sut addChannelUnitWithConfiguration:self.validConfiguration];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [sut addDelegate:delegateMock];

  // When
  [sut channel:channelUnitMock didFailSendingLog:mockLog withError:error];

  // Then
  OCMVerify([delegateMock channel:channelUnitMock didFailSendingLog:mockLog withError:error]);

  // Clear
  [channelUnitMock stopMocking];
}

- (void)testDelegateCalledWhenChannelUnitShouldFilterLog {

  // If
  id<MSLog> mockLog = [MSMockLog new];
  id ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));
  MSChannelGroupDefault *sut = [[MSChannelGroupDefault alloc] initWithIngestion:ingestionMock];
  id channelUnitMock = OCMClassMock([MSChannelUnitDefault class]);
  OCMStub([channelUnitMock alloc]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock initWithIngestion:OCMOCK_ANY storage:OCMOCK_ANY configuration:OCMOCK_ANY logsDispatchQueue:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  [sut addChannelUnitWithConfiguration:self.validConfiguration];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [sut addDelegate:delegateMock];

  // When
  [sut channelUnit:channelUnitMock shouldFilterLog:mockLog];

  // Then
  OCMVerify([delegateMock channelUnit:channelUnitMock shouldFilterLog:mockLog]);

  // Clear
  [channelUnitMock stopMocking];
}

@end
