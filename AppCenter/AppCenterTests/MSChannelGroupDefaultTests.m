// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAbstractLogInternal.h"
#import "MSAppCenterIngestion.h"
#import "MSAuthTokenContext.h"
#import "MSChannelDelegate.h"
#import "MSChannelGroupDefault.h"
#import "MSChannelGroupDefaultPrivate.h"
#import "MSChannelUnitConfiguration.h"
#import "MSChannelUnitDefault.h"
#import "MSChannelUnitDefaultPrivate.h"
#import "MSDispatchTestUtil.h"
#import "MSIngestionProtocol.h"
#import "MSMockLog.h"
#import "MSStorage.h"
#import "MSTestFrameworks.h"

@interface MSChannelGroupDefaultTests : XCTestCase

@property(nonatomic) id ingestionMock;

@property(nonatomic) MSChannelUnitConfiguration *validConfiguration;

@property(nonatomic) MSChannelGroupDefault *sut;

@end

@implementation MSChannelGroupDefaultTests

- (void)setUp {
  NSString *groupId = @"AppCenter";
  MSPriority priority = MSPriorityDefault;
  NSUInteger flushInterval = 3;
  NSUInteger batchSizeLimit = 10;
  NSUInteger pendingBatchesLimit = 3;
  self.ingestionMock = OCMClassMock([MSAppCenterIngestion class]);
  self.validConfiguration = [[MSChannelUnitConfiguration alloc] initWithGroupId:groupId
                                                                       priority:priority
                                                                  flushInterval:flushInterval
                                                                 batchSizeLimit:batchSizeLimit
                                                            pendingBatchesLimit:pendingBatchesLimit];
  self.sut = [[MSChannelGroupDefault alloc] initWithIngestion:self.ingestionMock];

  /*
   * dispatch_get_main_queue isn't good option for logsDispatchQueue because
   * we can't clear pending actions from it after the test. It can cause usages of stopped mocks.
   *
   * Keep the serial queue that created during the initialization.
   */
}

- (void)tearDown {
  [MSDispatchTestUtil awaitAndSuspendDispatchQueue:self.sut.logsDispatchQueue];

  // Stop mocks.
  [self.ingestionMock stopMocking];
  [super tearDown];
}

#pragma mark - Tests

- (void)testNewInstanceWasInitialisedCorrectly {

  // Then
  assertThat(self.sut, notNilValue());
  assertThat(self.sut.logsDispatchQueue, notNilValue());
  assertThat(self.sut.channels, isEmpty());
  assertThat(self.sut.ingestion, equalTo(self.ingestionMock));
  assertThat(self.sut.storage, notNilValue());
}

- (void)testAddNewChannel {

  // Then
  assertThat(self.sut.channels, isEmpty());

  // When
  id<MSChannelUnitProtocol> addedChannel = [self.sut addChannelUnitWithConfiguration:self.validConfiguration];

  // Then
  XCTAssertTrue([self.sut.channels containsObject:addedChannel]);
  assertThat(addedChannel, notNilValue());
  XCTAssertTrue(addedChannel.configuration.priority == self.validConfiguration.priority);
  assertThatFloat(addedChannel.configuration.flushInterval, equalToFloat(self.validConfiguration.flushInterval));
  assertThatUnsignedLong(addedChannel.configuration.batchSizeLimit, equalToUnsignedLong(self.validConfiguration.batchSizeLimit));
  assertThatUnsignedLong(addedChannel.configuration.pendingBatchesLimit, equalToUnsignedLong(self.validConfiguration.pendingBatchesLimit));
}

- (void)testAddNewChannelWithDefaultIngestion {

  // When
  MSChannelUnitDefault *channelUnit = (MSChannelUnitDefault *)[self.sut addChannelUnitWithConfiguration:self.validConfiguration];

  // Then
  XCTAssertEqual(self.ingestionMock, channelUnit.ingestion);
}

- (void)testAddChannelWithCustomIngestion {

  // If
  id ingestionMockCustom = OCMClassMock([MSAppCenterIngestion class]);

  // When
  MSChannelUnitDefault *channelUnit = (MSChannelUnitDefault *)[self.sut addChannelUnitWithConfiguration:[MSChannelUnitConfiguration new]
                                                                                          withIngestion:ingestionMockCustom];

  // Then
  XCTAssertNotEqual(self.ingestionMock, channelUnit.ingestion);
  XCTAssertEqual(ingestionMockCustom, channelUnit.ingestion);
  [ingestionMockCustom stopMocking];
}

- (void)testDelegatesConcurrentAccess {

  // If
  MSAbstractLog *log = [MSAbstractLog new];
  for (int j = 0; j < 10; j++) {
    id mockDelegate = OCMProtocolMock(@protocol(MSChannelDelegate));
    [self.sut addDelegate:mockDelegate];
  }
  id<MSChannelUnitProtocol> addedChannel = [self.sut addChannelUnitWithConfiguration:self.validConfiguration];

  // When
  void (^block)(void) = ^{
    for (int i = 0; i < 10; i++) {
      [addedChannel enqueueItem:log flags:MSFlagsDefault];
    }
    for (int i = 0; i < 100; i++) {
      [self.sut addDelegate:OCMProtocolMock(@protocol(MSChannelDelegate))];
    }
  };

  // Then
  XCTAssertNoThrow(block());
}

- (void)testSetEnabled {

  // If
  id<MSChannelUnitProtocol> channelMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id<MSChannelDelegate> delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [self.sut addDelegate:delegateMock];
  [self.sut.channels addObject:channelMock];

  // When
  [self.sut setEnabled:NO andDeleteDataOnDisabled:YES];

  // Then
  OCMVerify([self.ingestionMock setEnabled:NO andDeleteDataOnDisabled:YES]);
  OCMVerify([channelMock setEnabled:NO andDeleteDataOnDisabled:YES]);
  OCMVerify([delegateMock channel:self.sut didSetEnabled:NO andDeleteDataOnDisabled:YES]);
}

- (void)testResume {

  // If
  id<MSChannelUnitProtocol> channelMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  [self.sut.channels addObject:channelMock];
  NSObject *token = [NSObject new];

  // When
  [self.sut resumeWithIdentifyingObject:token];

  // Then
  OCMVerify([self.ingestionMock setEnabled:YES andDeleteDataOnDisabled:NO]);
  OCMVerify([channelMock resumeWithIdentifyingObject:token]);
}

- (void)testPause {

  // If
  id<MSChannelUnitProtocol> channelMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  [self.sut.channels addObject:channelMock];
  NSObject *identifyingObject = [NSObject new];

  // When
  [self.sut pauseWithIdentifyingObject:identifyingObject];

  // Then
  OCMVerify([self.ingestionMock setEnabled:NO andDeleteDataOnDisabled:NO]);
  OCMVerify([channelMock pauseWithIdentifyingObject:identifyingObject]);
}

- (void)testChannelUnitIsCorrectlyInitialized {

  // If
  id channelUnitMock = OCMClassMock([MSChannelUnitDefault class]);
  OCMStub([channelUnitMock alloc]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock initWithIngestion:OCMOCK_ANY storage:OCMOCK_ANY configuration:OCMOCK_ANY logsDispatchQueue:OCMOCK_ANY])
      .andReturn(channelUnitMock);

  // When
  [self.sut addChannelUnitWithConfiguration:self.validConfiguration];

  // Then
  OCMVerify([channelUnitMock addDelegate:(id<MSChannelDelegate>)self.sut]);
  [self waitForLogsDispatchQueue];
  OCMVerify([channelUnitMock checkPendingLogs]);

  // Clear
  [channelUnitMock stopMocking];
}

- (void)testDelegateCalledWhenAddingNewChannelUnit {

  // Test that delegates are called whenever a new channel unit is added to the
  // channel group.

  // If
  id channelUnitMock = OCMClassMock([MSChannelUnitDefault class]);
  OCMStub([channelUnitMock alloc]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock initWithIngestion:OCMOCK_ANY storage:OCMOCK_ANY configuration:OCMOCK_ANY logsDispatchQueue:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  id delegateMock1 = OCMProtocolMock(@protocol(MSChannelDelegate));
  OCMExpect([delegateMock1 channelGroup:self.sut didAddChannelUnit:channelUnitMock]);
  id delegateMock2 = OCMProtocolMock(@protocol(MSChannelDelegate));
  OCMExpect([delegateMock2 channelGroup:self.sut didAddChannelUnit:channelUnitMock]);
  [self.sut addDelegate:delegateMock1];
  [self.sut addDelegate:delegateMock2];

  // When
  [self.sut addChannelUnitWithConfiguration:self.validConfiguration];

  // Then
  OCMVerifyAll(delegateMock1);
  OCMVerifyAll(delegateMock2);

  // Clear
  [channelUnitMock stopMocking];
}

- (void)testDelegateCalledWhenChannelUnitPaused {

  // If
  NSObject *identifyingObject = [NSObject new];
  id channelUnitMock = OCMClassMock([MSChannelUnitDefault class]);
  OCMStub([channelUnitMock alloc]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock initWithIngestion:OCMOCK_ANY storage:OCMOCK_ANY configuration:OCMOCK_ANY logsDispatchQueue:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  [self.sut addChannelUnitWithConfiguration:self.validConfiguration];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut channel:channelUnitMock didPauseWithIdentifyingObject:identifyingObject];

  // Then
  OCMVerify([delegateMock channel:channelUnitMock didPauseWithIdentifyingObject:identifyingObject]);

  // Clear
  [channelUnitMock stopMocking];
}

- (void)testDelegateCalledWhenChannelUnitResumed {

  // If
  NSObject *identifyingObject = [NSObject new];
  id channelUnitMock = OCMClassMock([MSChannelUnitDefault class]);
  OCMStub([channelUnitMock alloc]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock initWithIngestion:OCMOCK_ANY storage:OCMOCK_ANY configuration:OCMOCK_ANY logsDispatchQueue:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  [self.sut addChannelUnitWithConfiguration:self.validConfiguration];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut channel:channelUnitMock didResumeWithIdentifyingObject:identifyingObject];

  // Then
  OCMVerify([delegateMock channel:channelUnitMock didResumeWithIdentifyingObject:identifyingObject]);

  // Clear
  [channelUnitMock stopMocking];
}

- (void)testDelegateCalledWhenChannelUnitPreparesLog {

  // If
  id<MSLog> mockLog = [MSMockLog new];
  id channelUnitMock = OCMClassMock([MSChannelUnitDefault class]);
  OCMStub([channelUnitMock alloc]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock initWithIngestion:OCMOCK_ANY storage:OCMOCK_ANY configuration:OCMOCK_ANY logsDispatchQueue:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  [self.sut addChannelUnitWithConfiguration:self.validConfiguration];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut channel:channelUnitMock prepareLog:mockLog];

  // Then
  OCMVerify([delegateMock channel:channelUnitMock prepareLog:mockLog]);

  // Clear
  [channelUnitMock stopMocking];
}

- (void)testDelegateCalledWhenChannelUnitDidPrepareLog {

  // If
  id<MSLog> mockLog = [MSMockLog new];
  NSString *internalId = @"mockId";
  id channelUnitMock = OCMClassMock([MSChannelUnitDefault class]);
  OCMStub([channelUnitMock alloc]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock initWithIngestion:OCMOCK_ANY storage:OCMOCK_ANY configuration:OCMOCK_ANY logsDispatchQueue:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  [self.sut addChannelUnitWithConfiguration:self.validConfiguration];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut channel:channelUnitMock didPrepareLog:mockLog internalId:internalId flags:MSFlagsDefault];

  // Then
  OCMVerify([delegateMock channel:channelUnitMock didPrepareLog:mockLog internalId:internalId flags:MSFlagsDefault]);

  // Clear
  [channelUnitMock stopMocking];
}

//TODO pause/resume tests based on http client state

- (void)testDelegateCalledWhenChannelUnitDidCompleteEnqueueingLog {

  // If
  id<MSLog> mockLog = [MSMockLog new];
  NSString *internalId = @"mockId";
  id channelUnitMock = OCMClassMock([MSChannelUnitDefault class]);
  OCMStub([channelUnitMock alloc]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock initWithIngestion:OCMOCK_ANY storage:OCMOCK_ANY configuration:OCMOCK_ANY logsDispatchQueue:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  [self.sut addChannelUnitWithConfiguration:self.validConfiguration];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut channel:channelUnitMock didCompleteEnqueueingLog:mockLog internalId:internalId];

  // Then
  OCMVerify([delegateMock channel:channelUnitMock didCompleteEnqueueingLog:mockLog internalId:internalId]);

  // Clear
  [channelUnitMock stopMocking];
}

- (void)testDelegateCalledWhenChannelUnitWillSendLog {

  // If
  id<MSLog> mockLog = [MSMockLog new];
  id channelUnitMock = OCMClassMock([MSChannelUnitDefault class]);
  OCMStub([channelUnitMock alloc]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock initWithIngestion:OCMOCK_ANY storage:OCMOCK_ANY configuration:OCMOCK_ANY logsDispatchQueue:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  [self.sut addChannelUnitWithConfiguration:self.validConfiguration];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut channel:channelUnitMock willSendLog:mockLog];

  // Then
  OCMVerify([delegateMock channel:channelUnitMock willSendLog:mockLog]);

  // Clear
  [channelUnitMock stopMocking];
}

- (void)testDelegateCalledWhenChannelUnitDidSucceedSendingLog {

  // If
  id<MSLog> mockLog = [MSMockLog new];
  id channelUnitMock = OCMClassMock([MSChannelUnitDefault class]);
  OCMStub([channelUnitMock alloc]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock initWithIngestion:OCMOCK_ANY storage:OCMOCK_ANY configuration:OCMOCK_ANY logsDispatchQueue:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  [self.sut addChannelUnitWithConfiguration:self.validConfiguration];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut channel:channelUnitMock didSucceedSendingLog:mockLog];

  // Then
  OCMVerify([delegateMock channel:channelUnitMock didSucceedSendingLog:mockLog]);

  // Clear
  [channelUnitMock stopMocking];
}

- (void)testDelegateCalledWhenChannelUnitDidSetEnabled {

  // If
  id channelUnitMock = OCMClassMock([MSChannelUnitDefault class]);
  OCMStub([channelUnitMock alloc]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock initWithIngestion:OCMOCK_ANY storage:OCMOCK_ANY configuration:OCMOCK_ANY logsDispatchQueue:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  [self.sut addChannelUnitWithConfiguration:self.validConfiguration];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut channel:channelUnitMock didSetEnabled:YES andDeleteDataOnDisabled:YES];

  // Then
  OCMVerify([delegateMock channel:channelUnitMock didSetEnabled:YES andDeleteDataOnDisabled:YES]);

  // Clear
  [channelUnitMock stopMocking];
}

- (void)testDelegateCalledWhenChannelUnitDidFailSendingLog {

  // If
  id<MSLog> mockLog = [MSMockLog new];
  NSError *error = [NSError new];
  id channelUnitMock = OCMClassMock([MSChannelUnitDefault class]);
  OCMStub([channelUnitMock alloc]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock initWithIngestion:OCMOCK_ANY storage:OCMOCK_ANY configuration:OCMOCK_ANY logsDispatchQueue:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  [self.sut addChannelUnitWithConfiguration:self.validConfiguration];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut channel:channelUnitMock didFailSendingLog:mockLog withError:error];

  // Then
  OCMVerify([delegateMock channel:channelUnitMock didFailSendingLog:mockLog withError:error]);

  // Clear
  [channelUnitMock stopMocking];
}

- (void)testDelegateCalledWhenChannelUnitShouldFilterLog {

  // If
  id<MSLog> mockLog = [MSMockLog new];
  id channelUnitMock = OCMClassMock([MSChannelUnitDefault class]);
  OCMStub([channelUnitMock alloc]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock initWithIngestion:OCMOCK_ANY storage:OCMOCK_ANY configuration:OCMOCK_ANY logsDispatchQueue:OCMOCK_ANY])
      .andReturn(channelUnitMock);
  [self.sut addChannelUnitWithConfiguration:self.validConfiguration];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut channelUnit:channelUnitMock shouldFilterLog:mockLog];

  // Then
  OCMVerify([delegateMock channelUnit:channelUnitMock shouldFilterLog:mockLog]);

  // Clear
  [channelUnitMock stopMocking];
}

#pragma mark - Helper

- (void)waitForLogsDispatchQueue {
  XCTestExpectation *expectation = [self expectationWithDescription:@"Logs dispatch queue"];
  dispatch_async(self.sut.logsDispatchQueue, ^{
    [expectation fulfill];
  });
  [self waitForExpectations:@[ expectation ] timeout:1];
}

@end
