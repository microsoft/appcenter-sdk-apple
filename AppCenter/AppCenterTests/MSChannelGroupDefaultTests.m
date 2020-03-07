// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAbstractLogInternal.h"
#import "MSAppCenterIngestion.h"
#import "MSChannelDelegate.h"
#import "MSChannelGroupDefault.h"
#import "MSChannelGroupDefaultPrivate.h"
#import "MSChannelUnitConfiguration.h"
#import "MSChannelUnitDefault.h"
#import "MSChannelUnitDefaultPrivate.h"
#import "MSHttpClient.h"
#import "MSHttpTestUtil.h"
#import "MSHttpUtil.h"
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
  __weak dispatch_object_t dispatchQueue = self.sut.logsDispatchQueue;
  self.sut = nil;
  XCTAssertNil(dispatchQueue);

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

  // This test will use a real channel unit object which runs `checkPendingLogs` in the log dispatch queue.
  // We should make sure the test method is not finished before `checkPendingLogs` method call is finished to avoid object retain issue.
  [self waitForLogsDispatchQueue];

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

  // This test will use a real channel unit object which runs `checkPendingLogs` in the log dispatch queue.
  // We should make sure the test method is not finished before `checkPendingLogs` method call is finished to avoid object retain issue.
  [self waitForLogsDispatchQueue];

  // Then
  XCTAssertEqual(self.ingestionMock, channelUnit.ingestion);
}

- (void)testAddChannelWithCustomIngestion {

  // If, We can't use class mock of MSAppCenterIngestion because it is already class-mocked in setUp.
  // Using more than one class mock is not supported.
  MSAppCenterIngestion *newIngestion = [MSAppCenterIngestion new];

  // When
  MSChannelUnitDefault *channelUnit = (MSChannelUnitDefault *)[self.sut addChannelUnitWithConfiguration:[MSChannelUnitConfiguration new]
                                                                                          withIngestion:newIngestion];

  // This test will use a real channel unit object which runs `checkPendingLogs` in the log dispatch queue.
  // We should make sure the test method is not finished before `checkPendingLogs` method call is finished to avoid object retain issue.
  [self waitForLogsDispatchQueue];

  // Then
  XCTAssertNotEqual(self.ingestionMock, channelUnit.ingestion);
  XCTAssertEqual(newIngestion, channelUnit.ingestion);
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

  // This test will use a real channel unit object which runs `checkPendingLogs` in the log dispatch queue.
  // We should make sure the test method is not finished before `checkPendingLogs` method call is finished to avoid object retain issue.
  [self waitForLogsDispatchQueue];

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

  // This test will use a real channel unit object which runs `checkPendingLogs` in the log dispatch queue.
  // We should make sure the test method is not finished before `checkPendingLogs` method call is finished to avoid object retain issue.
  [self waitForLogsDispatchQueue];

  // Then
  OCMVerify([channelUnitMock addDelegate:(id<MSChannelDelegate>)self.sut]);
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

  // This test will use a real channel unit object which runs `checkPendingLogs` in the log dispatch queue.
  // We should make sure the test method is not finished before `checkPendingLogs` method call is finished to avoid object retain issue.
  [self waitForLogsDispatchQueue];

  // Then
  OCMVerifyAll(delegateMock1);
  OCMVerifyAll(delegateMock2);

  // Clear
  [channelUnitMock stopMocking];
}

- (void)testDelegateCalledWhenChannelUnitPaused {

  // If
  NSObject *identifyingObject = [NSObject new];
  [self.sut addChannelUnitWithConfiguration:self.validConfiguration];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut channel:self.sut didPauseWithIdentifyingObject:identifyingObject];

  // This test will use a real channel unit object which runs `checkPendingLogs` in the log dispatch queue.
  // We should make sure the test method is not finished before `checkPendingLogs` method call is finished to avoid object retain issue.
  [self waitForLogsDispatchQueue];

  // Then
  OCMVerify([delegateMock channel:self.sut didPauseWithIdentifyingObject:identifyingObject]);
}

- (void)testDelegateCalledWhenChannelUnitResumed {

  // If
  NSObject *identifyingObject = [NSObject new];
  [self.sut addChannelUnitWithConfiguration:self.validConfiguration];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut channel:self.sut didResumeWithIdentifyingObject:identifyingObject];

  // This test will use a real channel unit object which runs `checkPendingLogs` in the log dispatch queue.
  // We should make sure the test method is not finished before `checkPendingLogs` method call is finished to avoid object retain issue.
  [self waitForLogsDispatchQueue];

  // Then
  OCMVerify([delegateMock channel:self.sut didResumeWithIdentifyingObject:identifyingObject]);
}

- (void)testDelegateCalledWhenChannelUnitPreparesLog {

  // If
  id<MSLog> mockLog = [MSMockLog new];
  [self.sut addChannelUnitWithConfiguration:self.validConfiguration];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut channel:self.sut prepareLog:mockLog];

  // This test will use a real channel unit object which runs `checkPendingLogs` in the log dispatch queue.
  // We should make sure the test method is not finished before `checkPendingLogs` method call is finished to avoid object retain issue.
  [self waitForLogsDispatchQueue];

  // Then
  OCMVerify([delegateMock channel:self.sut prepareLog:mockLog]);
}

- (void)testDelegateCalledWhenChannelUnitDidPrepareLog {

  // If
  id<MSLog> mockLog = [MSMockLog new];
  NSString *internalId = @"mockId";
  [self.sut addChannelUnitWithConfiguration:self.validConfiguration];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut channel:self.sut didPrepareLog:mockLog internalId:internalId flags:MSFlagsDefault];

  // This test will use a real channel unit object which runs `checkPendingLogs` in the log dispatch queue.
  // We should make sure the test method is not finished before `checkPendingLogs` method call is finished to avoid object retain issue.
  [self waitForLogsDispatchQueue];

  // Then
  OCMVerify([delegateMock channel:self.sut didPrepareLog:mockLog internalId:internalId flags:MSFlagsDefault]);
}

- (void)testDelegateCalledWhenChannelUnitDidCompleteEnqueueingLog {

  // If
  id<MSLog> mockLog = [MSMockLog new];
  NSString *internalId = @"mockId";
  [self.sut addChannelUnitWithConfiguration:self.validConfiguration];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut channel:self.sut didCompleteEnqueueingLog:mockLog internalId:internalId];

  // This test will use a real channel unit object which runs `checkPendingLogs` in the log dispatch queue.
  // We should make sure the test method is not finished before `checkPendingLogs` method call is finished to avoid object retain issue.
  [self waitForLogsDispatchQueue];

  // Then
  OCMVerify([delegateMock channel:self.sut didCompleteEnqueueingLog:mockLog internalId:internalId]);
}

- (void)testDelegateCalledWhenChannelUnitWillSendLog {

  // If
  id<MSLog> mockLog = [MSMockLog new];
  [self.sut addChannelUnitWithConfiguration:self.validConfiguration];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut channel:self.sut willSendLog:mockLog];

  // This test will use a real channel unit object which runs `checkPendingLogs` in the log dispatch queue.
  // We should make sure the test method is not finished before `checkPendingLogs` method call is finished to avoid object retain issue.
  [self waitForLogsDispatchQueue];

  // Then
  OCMVerify([delegateMock channel:self.sut willSendLog:mockLog]);
}

- (void)testDelegateCalledWhenChannelUnitDidSucceedSendingLog {

  // If
  id<MSLog> mockLog = [MSMockLog new];
  [self.sut addChannelUnitWithConfiguration:self.validConfiguration];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut channel:self.sut didSucceedSendingLog:mockLog];

  // This test will use a real channel unit object which runs `checkPendingLogs` in the log dispatch queue.
  // We should make sure the test method is not finished before `checkPendingLogs` method call is finished to avoid object retain issue.
  [self waitForLogsDispatchQueue];

  // Then
  OCMVerify([delegateMock channel:self.sut didSucceedSendingLog:mockLog]);
}

- (void)testDelegateCalledWhenChannelUnitDidSetEnabled {

  // If
  [self.sut addChannelUnitWithConfiguration:self.validConfiguration];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut channel:self.sut didSetEnabled:YES andDeleteDataOnDisabled:YES];

  // This test will use a real channel unit object which runs `checkPendingLogs` in the log dispatch queue.
  // We should make sure the test method is not finished before `checkPendingLogs` method call is finished to avoid object retain issue.
  [self waitForLogsDispatchQueue];

  // Then
  OCMVerify([delegateMock channel:self.sut didSetEnabled:YES andDeleteDataOnDisabled:YES]);
}

- (void)testDelegateCalledWhenChannelUnitDidFailSendingLog {

  // If
  id<MSLog> mockLog = [MSMockLog new];
  NSError *error = [NSError new];
  [self.sut addChannelUnitWithConfiguration:self.validConfiguration];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut channel:self.sut didFailSendingLog:mockLog withError:error];

  // This test will use a real channel unit object which runs `checkPendingLogs` in the log dispatch queue.
  // We should make sure the test method is not finished before `checkPendingLogs` method call is finished to avoid object retain issue.
  [self waitForLogsDispatchQueue];

  // Then
  OCMVerify([delegateMock channel:self.sut didFailSendingLog:mockLog withError:error]);
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

  // This test will use a real channel unit object which runs `checkPendingLogs` in the log dispatch queue.
  // We should make sure the test method is not finished before `checkPendingLogs` method call is finished to avoid object retain issue.
  [self waitForLogsDispatchQueue];

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
