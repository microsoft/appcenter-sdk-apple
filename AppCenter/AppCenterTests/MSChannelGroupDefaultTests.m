#import "MSAbstractLogInternal.h"
#import "MSChannelUnitConfiguration.h"
#import "MSChannelUnitDefault.h"
#import "MSHttpSenderPrivate.h"
#import "MSChannelGroupDefault.h"
#import "MSTestFrameworks.h"
#import "MSMockLog.h"
#import "MSStorage.h"
#import "MSSender.h"

@interface MSChannelGroupDefaultTests : XCTestCase

@end

@implementation MSChannelGroupDefaultTests

#pragma mark - Tests

- (void)testNewInstanceWasInitialisedCorrectly {

  // If
  id senderMock = OCMProtocolMock(@protocol(MSSender));
  id storageMock = OCMProtocolMock(@protocol(MSStorage));

  // When
  MSChannelGroupDefault *sut = [[MSChannelGroupDefault alloc] initWithSender:senderMock storage:storageMock];

  // Then
  assertThat(sut, notNilValue());
  assertThat(sut.logsDispatchQueue, notNilValue());
  assertThat(sut.channels, isEmpty());
  assertThat(sut.sender, equalTo(senderMock));
  assertThat(sut.storage, equalTo(storageMock));
}

- (void)testAddNewChannel {

  // If
  NSString *groupId = @"AppCenter";
  MSPriority priority = MSPriorityDefault;
  float flushInterval = 1.0;
  NSUInteger batchSizeLimit = 10;
  NSUInteger pendingBatchesLimit = 3;
  MSChannelGroupDefault *sut = [[MSChannelGroupDefault alloc] initWithSender:OCMProtocolMock(@protocol(MSSender))
                                                                 storage:OCMProtocolMock(@protocol(MSStorage))];

  // Then
  assertThat(sut.channels, isEmpty());

  // When
  id<MSChannelUnitProtocol> addedChannel = [sut addChannelUnitWithConfiguration:
                                            [[MSChannelUnitConfiguration alloc] initWithGroupId:groupId
                                                                                       priority:priority
                                                                                  flushInterval:flushInterval
                                                                                 batchSizeLimit:batchSizeLimit
                                                                            pendingBatchesLimit:pendingBatchesLimit]];

  // Then
  XCTAssertTrue([sut.channels containsObject:addedChannel]);
  assertThat(addedChannel, notNilValue());
  XCTAssertTrue(addedChannel.configuration.priority == priority);
  assertThatFloat(addedChannel.configuration.flushInterval, equalToFloat(flushInterval));
  assertThatUnsignedLong(addedChannel.configuration.batchSizeLimit, equalToUnsignedLong(batchSizeLimit));
  assertThatUnsignedLong(addedChannel.configuration.pendingBatchesLimit, equalToUnsignedLong(pendingBatchesLimit));
}

- (void)testDelegatesConcurrentAccess {

  // If
  NSString *groupId = @"AppCenter";
  MSChannelGroupDefault *sut = [[MSChannelGroupDefault alloc] initWithSender:OCMProtocolMock(@protocol(MSSender))
                                                                 storage:OCMProtocolMock(@protocol(MSStorage))];
  MSAbstractLog *log = [MSAbstractLog new];
  for (int j = 0; j < 10; j++) {
    id mockDelegate = OCMProtocolMock(@protocol(MSChannelDelegate));
    [sut addDelegate:mockDelegate];
  }
  id<MSChannelUnitProtocol> addedChannel = [sut addChannelUnitWithConfiguration:
                                            [[MSChannelUnitConfiguration alloc] initWithGroupId:groupId
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

- (void)testResume {

  // If
  MSHttpSender *senderMock = OCMClassMock([MSHttpSender class]);
  id storageMock = OCMProtocolMock(@protocol(MSStorage));

  // When
  MSChannelGroupDefault *sut = [[MSChannelGroupDefault alloc] initWithSender:senderMock storage:storageMock];

  // When
  [sut resume];

  // Then
  OCMVerify([senderMock setEnabled:YES andDeleteDataOnDisabled:NO]);
}

- (void)testSuspend {

  // If
  MSHttpSender *senderMock = OCMClassMock([MSHttpSender class]);
  id storageMock = OCMProtocolMock(@protocol(MSStorage));

  // When
  MSChannelGroupDefault *sut = [[MSChannelGroupDefault alloc] initWithSender:senderMock storage:storageMock];

  // When
  [sut suspend];

  // Then
  OCMVerify([senderMock setEnabled:NO andDeleteDataOnDisabled:NO]);
}

- (void)testDisableAndDeleteDataOnSenderFatalError {

  // If
  id senderMock = OCMProtocolMock(@protocol(MSSender));
  id storageMock = OCMProtocolMock(@protocol(MSStorage));
  MSChannelGroupDefault *sut = [[MSChannelGroupDefault alloc] initWithSender:senderMock storage:storageMock];
  id<MSChannelUnitProtocol> addedChannel = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  [sut.channels addObject:addedChannel];

  // When
  [addedChannel enqueueItem:[MSMockLog new]];
  [sut senderDidReceiveFatalError:senderMock];

  // Then
  OCMVerify([senderMock setEnabled:NO andDeleteDataOnDisabled:YES]);
  OCMVerify([addedChannel setEnabled:NO andDeleteDataOnDisabled:YES]);
}

- (void)testSuspendOnSenderSuspended {

  // If
  id senderMock = OCMProtocolMock(@protocol(MSSender));
  id storageMock = OCMProtocolMock(@protocol(MSStorage));
  MSChannelGroupDefault *sut = [[MSChannelGroupDefault alloc] initWithSender:senderMock storage:storageMock];
  id<MSChannelUnitProtocol> addedChannel = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  [sut.channels addObject:addedChannel];

  // When
  [addedChannel enqueueItem:[MSMockLog new]];
  [sut senderDidSuspend:senderMock];

  // Then
  dispatch_semaphore_t sem = dispatch_semaphore_create(0);

  // Do the verifications in the log queue to ensure that they occur after the operations complete.
  dispatch_async(sut.logsDispatchQueue, ^{
    OCMVerify([senderMock setEnabled:NO andDeleteDataOnDisabled:NO]);
    OCMVerify([addedChannel suspend]);
    dispatch_semaphore_signal(sem);
  });
  dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC*1));
}

- (void)testResumeOnSenderResumed {

  // If
  id senderMock = OCMProtocolMock(@protocol(MSSender));
  id storageMock = OCMProtocolMock(@protocol(MSStorage));
  MSChannelGroupDefault *sut = [[MSChannelGroupDefault alloc] initWithSender:senderMock storage:storageMock];
  id<MSChannelUnitProtocol> addedChannel = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  [sut.channels addObject:addedChannel];

  // When
  [addedChannel enqueueItem:[MSMockLog new]];
  [sut senderDidResume:senderMock];

  // Then
  dispatch_semaphore_t sem = dispatch_semaphore_create(0);

  // Do the verifications in the log queue to ensure that they occur after
  // the operations complete.
  dispatch_async(sut.logsDispatchQueue, ^{
    OCMVerify([senderMock setEnabled:YES andDeleteDataOnDisabled:NO]);
    OCMVerify([addedChannel resume]);
    dispatch_semaphore_signal(sem);
  });
  dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC*1));
}

- (void)testDelegateIsAddedToAddedUnit {

  // If
  NSString *groupId = @"AppCenter";
  MSPriority priority = MSPriorityDefault;
  float flushInterval = 1.0;
  NSUInteger batchSizeLimit = 10;
  NSUInteger pendingBatchesLimit = 3;
  id senderMock = OCMProtocolMock(@protocol(MSSender));
  id storageMock = OCMProtocolMock(@protocol(MSStorage));
  MSChannelGroupDefault *sut = [[MSChannelGroupDefault alloc] initWithSender:senderMock storage:storageMock];
  id channelUnitMock = OCMClassMock([MSChannelUnitDefault class]);
  OCMStub([channelUnitMock alloc]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock initWithSender:OCMOCK_ANY
                                       storage:OCMOCK_ANY
                                 configuration:OCMOCK_ANY
                             logsDispatchQueue:OCMOCK_ANY]).andReturn(channelUnitMock);

  // When
  [sut addChannelUnitWithConfiguration:[[MSChannelUnitConfiguration alloc] initWithGroupId:groupId
                                                                                  priority:priority
                                                                             flushInterval:flushInterval
                                                                            batchSizeLimit:batchSizeLimit
                                                                       pendingBatchesLimit:pendingBatchesLimit]];

  // Then
  OCMVerify([channelUnitMock addDelegate:sut]);

  // Clear
  [channelUnitMock stopMocking];
}
//
//- (void)testProcessingLogDoesNotEnqueueFilteredLogs {
//
//  // If
//  NSString *groupId = @"AppCenter";
//  MSPriority priority = MSPriorityDefault;
//  MSLogManagerDefault *sut = [[MSLogManagerDefault alloc] initWithSender:OCMProtocolMock(@protocol(MSSender))
//                                                                 storage:OCMProtocolMock(@protocol(MSStorage))];
//  [sut initChannelWithConfiguration:[[MSChannelConfiguration alloc] initWithGroupId:groupId
//                                                                           priority:priority
//                                                                      flushInterval:1.0
//                                                                     batchSizeLimit:10
//                                                                pendingBatchesLimit:3]];
//  MSAbstractLog *log = [MSAbstractLog new];
//  id<MSLogManagerDelegate> mockDelegate = OCMProtocolMock(@protocol(MSLogManagerDelegate));
//  OCMStub([mockDelegate shouldFilterLog:log]).andReturn(YES);
//  [sut addDelegate:mockDelegate];
//  OCMReject([mockDelegate onEnqueuingLog:log withInternalId:OCMOCK_ANY]);
//
//  // When
//  [sut processLog:log forGroupId:groupId];
//
//  // Then
//  // onEnqueuingLog was not called, but onPreparedLog was called.
//  OCMVerify([mockDelegate onPreparedLog:log withInternalId:OCMOCK_ANY]);
//
//  // If
//  // Add another filter that returns NO. The log should still be filtered because of mockDelegate.
//  id<MSLogManagerDelegate> mockDelegate2 = OCMProtocolMock(@protocol(MSLogManagerDelegate));
//  OCMStub([mockDelegate2 shouldFilterLog:log]).andReturn(NO);
//  [sut addDelegate:mockDelegate2];
//  OCMReject([mockDelegate2 onEnqueuingLog:log withInternalId:OCMOCK_ANY]);
//
//  // When
//  [sut processLog:log forGroupId:groupId];
//
//  // Then
//  // onEnqueuingLog was not called, but onPreparedLog was called.
//  OCMVerify([mockDelegate2 onPreparedLog:log withInternalId:OCMOCK_ANY]);
//}
//
//- (void)testProcessingLogEnqueuesUnfilteredLogs {
//
//  // If
//  NSString *groupId = @"AppCenter";
//  MSPriority priority = MSPriorityDefault;
//  MSLogManagerDefault *sut = [[MSLogManagerDefault alloc] initWithSender:OCMProtocolMock(@protocol(MSSender))
//                                                                 storage:OCMProtocolMock(@protocol(MSStorage))];
//  [sut initChannelWithConfiguration:[[MSChannelConfiguration alloc] initWithGroupId:groupId
//                                                                           priority:priority
//                                                                      flushInterval:1.0
//                                                                     batchSizeLimit:10
//                                                                pendingBatchesLimit:3]];
//  MSAbstractLog *log = [MSAbstractLog new];
//  id<MSLogManagerDelegate> mockDelegate = OCMProtocolMock(@protocol(MSLogManagerDelegate));
//  OCMStub([mockDelegate shouldFilterLog:log]).andReturn(NO);
//  [sut addDelegate:mockDelegate];
//
//  // When
//  [sut processLog:log forGroupId:groupId];
//
//  // Then
//  OCMVerify([mockDelegate onPreparedLog:log withInternalId:OCMOCK_ANY]);
//  OCMVerify([mockDelegate onEnqueuingLog:log withInternalId:OCMOCK_ANY]);
//}


@end
