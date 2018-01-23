#import "MSAbstractLogInternal.h"
#import "MSChannelUnitConfiguration.h"
#import "MSChannelUnitDefault.h"
#import "MSHttpSenderPrivate.h"
#import "MSChannelGroupDefault.h"
#import "MSTestFrameworks.h"

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

//- (void)testDisableAndDeleteDataOnSenderFatalError {
//
//  // If
//  [self initChannelEndJobExpectation];
//  id senderMock = OCMProtocolMock(@protocol(MSSender));
//  id storageMock = OCMProtocolMock(@protocol(MSStorage));
//  id mockLog = [self getValidMockLog];
//  OCMStub([storageMock
//      loadLogsWithGroupId:kMSTestGroupId
//                    limit:2
//           withCompletion:([OCMArg invokeBlockWithArgs:((NSArray<id<MSLog>> *)@[ mockLog ]), @"1", nil])]);
//  MSChannelUnitConfiguration *config = [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
//                                                                          priority:MSPriorityDefault
//                                                                     flushInterval:0.0
//                                                                    batchSizeLimit:1
//                                                               pendingBatchesLimit:10];
//  self.sut.configuration = config;
//  MSChannelUnitDefault *sut = [[MSChannelUnitDefault alloc] initWithSender:senderMock
//                                                           storage:storageMock
//                                                     configuration:config
//                                                 logsDispatchQueue:dispatch_get_main_queue()];
//  // When
//  [sut enqueueItem:mockLog];
//  //TODO - [sut senderDidReceiveFatalError:senderMock];?
//  [self enqueueChannelEndJobExpectation];
//
//  // Then
//  [self waitForExpectationsWithTimeout:1
//                               handler:^(NSError *error) {
//
//                                 // Check that logs as been requested for deletion and that there is no batch left.
//                                 OCMVerify([storageMock deleteLogsWithGroupId:kMSTestGroupId]);
//                                 assertThatBool(sut.enabled, isFalse());
//                                 if (error) {
//                                   XCTFail(@"Expectation Failed with error: %@", error);
//                                 }
//                               }];
//}
//
//- (void)testSuspendOnSenderSuspended {
//
//  // If
//  __block BOOL result1, result2;
//  [self initChannelEndJobExpectation];
//  [self.sut setEnabled:NO andDeleteDataOnDisabled:NO];
//
//  // When
//  [self.sut senderDidSuspend:self.senderMock];
//  dispatch_async(self.logsDispatchQueue, ^{
//    result1 = self.sut.suspended;
//  });
//
//  // If
//  [self.sut setEnabled:YES andDeleteDataOnDisabled:NO];
//
//  // When
//  [self.sut senderDidSuspend:self.senderMock];
//  dispatch_async(self.logsDispatchQueue, ^{
//    result2 = self.sut.suspended;
//  });
//  [self enqueueChannelEndJobExpectation];
//  [self waitForExpectationsWithTimeout:1
//                               handler:^(NSError *error) {
//                                 assertThatBool(result1, isTrue());
//                                 assertThatBool(result2, isTrue());
//                                 if (error) {
//                                   XCTFail(@"Expectation Failed with error: %@", error);
//                                 }
//                               }];
//}
//
//- (void)testSuspendOnSenderResumed {
//
//  // If
//  __block BOOL result1, result2;
//  [self initChannelEndJobExpectation];
//  [self.sut setEnabled:NO andDeleteDataOnDisabled:NO];
//
//  // When
//  [self.sut senderDidResume:self.senderMock];
//  dispatch_async(self.logsDispatchQueue, ^{
//    result1 = self.sut.suspended;
//  });
//
//  // If
//  [self.sut setEnabled:YES andDeleteDataOnDisabled:NO];
//  [self.sut senderDidSuspend:self.senderMock];
//
//  // When
//  [self.sut senderDidResume:self.senderMock];
//  dispatch_async(self.logsDispatchQueue, ^{
//    result2 = self.sut.suspended;
//  });
//
//  // Then
//  [self enqueueChannelEndJobExpectation];
//  [self waitForExpectationsWithTimeout:1
//                               handler:^(NSError *error) {
//                                 assertThatBool(result1, isTrue());
//                                 assertThatBool(result2, isFalse());
//                                 if (error) {
//                                   XCTFail(@"Expectation Failed with error: %@", error);
//                                 }
//                               }];
//}

@end
