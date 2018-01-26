#import <Foundation/Foundation.h>

#import "MSAbstractLogInternal.h"
#import "MSAppCenterErrors.h"
#import "MSChannelUnitConfiguration.h"
#import "MSChannelUnitDefault.h"
#import "MSChannelDelegate.h"
#import "MSDevice.h"
#import "MSHttpSender.h"
#import "MSLogContainer.h"
#import "MSSender.h"
#import "MSStorage.h"
#import "MSTestFrameworks.h"
#import "MSUtility.h"
#import "MSExpectantChannelDelegate.h"

static NSString *const kMSTestGroupId = @"GroupId";

@interface MSChannelUnitDefaultTests : XCTestCase

@property(nonatomic) MSChannelUnitDefault *sut;

@property(nonatomic) dispatch_queue_t logsDispatchQueue;

@property(nonatomic) MSChannelUnitConfiguration *configMock;

@property(nonatomic) id<MSStorage> storageMock;

@property(nonatomic) id<MSSender> senderMock;

/**
 * Most of the channel APIs are asynchronous, this expectation is meant to be enqueued to the data dispatch queue
 * at the end of the test before any asserts. Then it will be triggered on the next queue loop right after the channel
 * finished its job. Wrap asserts within the handler of a waitForExpectationsWithTimeout method.
 */
@property(nonatomic) XCTestExpectation *channelEndJobExpectation;

- (void)enqueueChannelEndJobExpectation;

@end

@implementation MSChannelUnitDefaultTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];

  self.logsDispatchQueue = dispatch_get_main_queue();
  self.configMock = OCMClassMock([MSChannelUnitConfiguration class]);
  self.storageMock = OCMProtocolMock(@protocol(MSStorage));
  self.senderMock = OCMProtocolMock(@protocol(MSSender));
  self.sut = [[MSChannelUnitDefault alloc] initWithSender:self.senderMock
                                              storage:self.storageMock
                                        configuration:self.configMock
                                    logsDispatchQueue:self.logsDispatchQueue];
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each
  // test method in the class.
  [super tearDown];
}

#pragma mark - Tests

- (void)testNewInstanceWasInitialisedCorrectly {
  assertThat(self.sut, notNilValue());
  assertThat(self.sut.configuration, equalTo(self.configMock));
  assertThat(self.sut.sender, equalTo(self.senderMock));
  assertThat(self.sut.storage, equalTo(self.storageMock));
  assertThatUnsignedLong(self.sut.itemsCount, equalToInt(0));
}

- (void)testLogsSentWithSuccess {

  // If
  [self initChannelEndJobExpectation];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  __block MSSendAsyncCompletionHandler senderBlock;
  __block MSLogContainer *logContainer;
  __block NSString *expectedBatchId = @"1";
  int batchSizeLimit = 1;
  id<MSLog> expectedLog = [MSAbstractLog new];
  expectedLog.sid = MS_UUID_STRING;

  // Init mocks.
  id<MSLog> enqueuedLog = [self getValidMockLog];
  id senderMock = OCMProtocolMock(@protocol(MSSender));
  OCMStub([senderMock sendAsync:OCMOCK_ANY completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {

    // Get sender bloc for later call.
    [invocation retainArguments];
    [invocation getArgument:&senderBlock atIndex:3];
    [invocation getArgument:&logContainer atIndex:2];
  });

  // Stub the storage load for that log.
  id storageMock = OCMProtocolMock(@protocol(MSStorage));
  OCMStub([storageMock loadLogsWithGroupId:kMSTestGroupId limit:batchSizeLimit withCompletion:(OCMOCK_ANY)])
      .andDo(^(NSInvocation *invocation) {
        MSLoadDataCompletionBlock loadCallback;

        // Get sender bloc for later call.
        [invocation getArgument:&loadCallback atIndex:4];

        // Mock load.
        loadCallback(((NSArray<id<MSLog>> *)@[ expectedLog ]), expectedBatchId);
      });

  // Configure channel.
  MSChannelUnitConfiguration *config = [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                          priority:MSPriorityDefault
                                                                     flushInterval:0.0
                                                                    batchSizeLimit:batchSizeLimit
                                                               pendingBatchesLimit:1];
  self.sut.configuration = config;
  MSChannelUnitDefault *sut = [[MSChannelUnitDefault alloc] initWithSender:senderMock
                                                           storage:storageMock
                                                     configuration:config
                                                 logsDispatchQueue:dispatch_get_main_queue()];
  [sut addDelegate:delegateMock];
  OCMReject([delegateMock channel:sut didFailSendingLog:OCMOCK_ANY withError:OCMOCK_ANY]);
  OCMExpect([delegateMock channel:sut didSucceedSendingLog:expectedLog]);
  OCMExpect([delegateMock onEnqueuingLog:enqueuedLog withInternalId:OCMOCK_ANY]);
  OCMExpect([storageMock deleteLogsWithBatchId:expectedBatchId groupId:kMSTestGroupId]);

  // When
  [sut enqueueItem:enqueuedLog];

  // Try to release one batch.
  dispatch_async(self.logsDispatchQueue, ^{
    XCTAssertNotNil(senderBlock);
    if (senderBlock) {
      senderBlock([@(1) stringValue], 200, nil, nil);
    }

    // Then
    dispatch_async(self.logsDispatchQueue, ^{
      [self enqueueChannelEndJobExpectation];
    });
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {

                                 // Get sure it has been sent.
                                 assertThat(logContainer.batchId, is(expectedBatchId));
                                 assertThat(logContainer.logs, is(@[ expectedLog ]));
                                 assertThatBool(sut.pendingBatchQueueFull, isFalse());
                                 assertThatUnsignedLong(sut.pendingBatchIds.count, equalToUnsignedLong(0));
                                 OCMVerifyAll(delegateMock);
                                 OCMVerifyAll(storageMock);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testLogsSentWithFailure {

  // If
  [self initChannelEndJobExpectation];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  __block MSSendAsyncCompletionHandler senderBlock;
  __block MSLogContainer *logContainer;
  __block NSString *expectedBatchId = @"1";
  int batchSizeLimit = 1;
  id<MSLog> expectedLog = [MSAbstractLog new];
  expectedLog.sid = MS_UUID_STRING;

  // Init mocks.
  id<MSLog> enqueuedLog = [self getValidMockLog];
  id senderMock = OCMProtocolMock(@protocol(MSSender));
  OCMStub([senderMock sendAsync:OCMOCK_ANY completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {

    // Get sender bloc for later call.
    [invocation retainArguments];
    [invocation getArgument:&senderBlock atIndex:3];
    [invocation getArgument:&logContainer atIndex:2];
  });

  // Stub the storage load for that log.
  id storageMock = OCMProtocolMock(@protocol(MSStorage));
  OCMStub([storageMock loadLogsWithGroupId:kMSTestGroupId limit:batchSizeLimit withCompletion:(OCMOCK_ANY)])
      .andDo(^(NSInvocation *invocation) {
        MSLoadDataCompletionBlock loadCallback;

        // Get sender bloc for later call.
        [invocation getArgument:&loadCallback atIndex:4];

        // Mock load.
        loadCallback(((NSArray<id<MSLog>> *)@[ expectedLog ]), expectedBatchId);
      });

  // Configure channel.
  MSChannelUnitConfiguration *config = [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                          priority:MSPriorityDefault
                                                                     flushInterval:0.0
                                                                    batchSizeLimit:batchSizeLimit
                                                               pendingBatchesLimit:1];
  self.sut.configuration = config;
  MSChannelUnitDefault *sut = [[MSChannelUnitDefault alloc] initWithSender:senderMock
                                                           storage:storageMock
                                                     configuration:config
                                                 logsDispatchQueue:dispatch_get_main_queue()];
  [sut addDelegate:delegateMock];
  OCMExpect([delegateMock onEnqueuingLog:enqueuedLog withInternalId:OCMOCK_ANY]);
  OCMExpect([delegateMock channel:sut didFailSendingLog:expectedLog withError:OCMOCK_ANY]);
  OCMReject([delegateMock channel:sut didSucceedSendingLog:OCMOCK_ANY]);
  OCMExpect([storageMock deleteLogsWithBatchId:expectedBatchId groupId:kMSTestGroupId]);

  // When
  [sut enqueueItem:enqueuedLog];

  // Try to release one batch.
  dispatch_async(self.logsDispatchQueue, ^{
    XCTAssertNotNil(senderBlock);
    if (senderBlock) {
      senderBlock([@(1) stringValue], 300, nil, nil);
    }

    // Then
    dispatch_async(self.logsDispatchQueue, ^{
      [self enqueueChannelEndJobExpectation];
    });
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {

                                 // Get sure it has been sent.
                                 assertThat(logContainer.batchId, is(expectedBatchId));
                                 assertThat(logContainer.logs, is(@[ expectedLog ]));
                                 assertThatBool(sut.pendingBatchQueueFull, isFalse());
                                 assertThatUnsignedLong(sut.pendingBatchIds.count, equalToUnsignedLong(0));
                                 OCMVerifyAll(delegateMock);
                                 OCMVerifyAll(storageMock);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testEnqueuingItemsWillIncreaseCounter {

  // If
  [self initChannelEndJobExpectation];
  MSChannelUnitConfiguration *config = [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                          priority:MSPriorityDefault
                                                                     flushInterval:5
                                                                    batchSizeLimit:10
                                                               pendingBatchesLimit:3];
  self.sut.configuration = config;
  int itemsToAdd = 3;

  // When
  for (int i = 1; i <= itemsToAdd; i++) {
    [self.sut enqueueItem:[self getValidMockLog]];
  }
  [self enqueueChannelEndJobExpectation];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 assertThatUnsignedLong(self.sut.itemsCount, equalToInt(itemsToAdd));
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testQueueFlushedAfterBatchSizeReached {

  // If
  [self initChannelEndJobExpectation];
  MSChannelUnitConfiguration *config = [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                          priority:MSPriorityDefault
                                                                     flushInterval:0.0
                                                                    batchSizeLimit:3
                                                               pendingBatchesLimit:3];
  self.sut.configuration = config;
  MSChannelUnitDefault *sut = [[MSChannelUnitDefault alloc] initWithSender:self.senderMock
                                                                   storage:self.storageMock
                                                             configuration:config
                                                         logsDispatchQueue:self.logsDispatchQueue];
  int itemsToAdd = 3;
  XCTestExpectation *expectation = [self expectationWithDescription:@"All items enqueued"];
  id<MSLog> mockLog = [self getValidMockLog];
  MSExpectantChannelDelegate *del = [MSExpectantChannelDelegate new];
  del.persistedHandler = ^(id<MSLog> log,
                           __attribute__((unused)) NSString *internalId,
                           __attribute__((unused)) BOOL success) {
    static int count = 0;
    if (log == mockLog) {
      count++;
      if (count == itemsToAdd) {
        [expectation fulfill];
      }
    }
  };
  [sut addDelegate:del];

  // When
  for (int i = 0; i < itemsToAdd; ++i) {
    [sut enqueueItem:mockLog];
  }
  [self enqueueChannelEndJobExpectation];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 assertThatUnsignedLong(sut.itemsCount, equalToInt(0));
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testBatchQueueLimit {

  // If
  [self initChannelEndJobExpectation];
  int batchSizeLimit = 1;
  __block int currentBatchId = 1;
  __block NSMutableArray<NSString *> *sentBatchIds = [NSMutableArray new];
  NSUInteger expectedMaxPendingBatched = 2;

  // Set up mock and stubs.
  id senderMock = OCMProtocolMock(@protocol(MSSender));
  OCMStub([senderMock sendAsync:OCMOCK_ANY completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    MSLogContainer *container;
    [invocation getArgument:&container atIndex:2];
    if (container) {
      [sentBatchIds addObject:container.batchId];
    }
  });
  id storageMock = OCMProtocolMock(@protocol(MSStorage));
  OCMStub([storageMock loadLogsWithGroupId:kMSTestGroupId limit:batchSizeLimit withCompletion:(OCMOCK_ANY)])
      .andDo(^(NSInvocation *invocation) {
        MSLoadDataCompletionBlock loadCallback;

        // Mock load.
        [invocation getArgument:&loadCallback atIndex:4];
        loadCallback(((NSArray<id<MSLog>> *)@[ OCMProtocolMock(@protocol(MSLog)) ]), [@(currentBatchId++) stringValue]);
      });
  MSChannelUnitConfiguration *config = [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                          priority:MSPriorityDefault
                                                                     flushInterval:0.0
                                                                    batchSizeLimit:batchSizeLimit
                                                               pendingBatchesLimit:expectedMaxPendingBatched];
  self.sut.configuration = config;
  MSChannelUnitDefault *sut = [[MSChannelUnitDefault alloc] initWithSender:senderMock
                                                           storage:storageMock
                                                     configuration:config
                                                 logsDispatchQueue:self.logsDispatchQueue];

  // When
  for (NSUInteger i = 1; i <= expectedMaxPendingBatched + 1; i++) {
    [sut enqueueItem:[self getValidMockLog]];
  }
  [self enqueueChannelEndJobExpectation];

  // Then
  [self waitForExpectationsWithTimeout:100
                               handler:^(NSError *error) {
                                 assertThatUnsignedLong(sut.pendingBatchIds.count,
                                                        equalToUnsignedLong(expectedMaxPendingBatched));
                                 assertThatUnsignedLong(sentBatchIds.count,
                                                        equalToUnsignedLong(expectedMaxPendingBatched));
                                 assertThat(sentBatchIds[0], is(@"1"));
                                 assertThat(sentBatchIds[1], is(@"2"));
                                 assertThatBool(sut.pendingBatchQueueFull, isTrue());
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testNextBatchSentIfPendingQueueGotRoomAgain {

  // If
  [self initChannelEndJobExpectation];
  XCTestExpectation *oneLogSentExpectation = [self expectationWithDescription:@"One log sent"];
  __block MSSendAsyncCompletionHandler senderBlock;
  __block MSLogContainer *lastBatchLogContainer;
  __block int currentBatchId = 1;
  int batchSizeLimit = 1;

  // Init mocks.
  id senderMock = OCMProtocolMock(@protocol(MSSender));
  OCMStub([senderMock sendAsync:OCMOCK_ANY completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {

    // Get sender block for later call.
    [invocation retainArguments];
    [invocation getArgument:&senderBlock atIndex:3];
    [invocation getArgument:&lastBatchLogContainer atIndex:2];
  });

  // Stub the storage load for that log.
  id storageMock = OCMProtocolMock(@protocol(MSStorage));
  OCMStub([storageMock loadLogsWithGroupId:kMSTestGroupId limit:batchSizeLimit withCompletion:(OCMOCK_ANY)])
      .andDo(^(NSInvocation *invocation) {
        MSLoadDataCompletionBlock loadCallback;

        // Get sender bloc for later call.
        [invocation getArgument:&loadCallback atIndex:4];

        // Mock load.
        loadCallback(((NSArray<id<MSLog>> *)@[ OCMProtocolMock(@protocol(MSLog)) ]), [@(currentBatchId) stringValue]);
      });

  // Configure channel.
  MSChannelUnitConfiguration *config = [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                          priority:MSPriorityDefault
                                                                     flushInterval:0.0
                                                                    batchSizeLimit:batchSizeLimit
                                                               pendingBatchesLimit:1];
  self.sut.configuration = config;
  MSChannelUnitDefault *sut = [[MSChannelUnitDefault alloc] initWithSender:senderMock
                                                           storage:storageMock
                                                     configuration:config
                                                 logsDispatchQueue:dispatch_get_main_queue()];

  // When
  [sut enqueueItem:[self getValidMockLog]];

  // Try to release one batch.
  dispatch_async(self.logsDispatchQueue, ^{
    senderBlock([@(1) stringValue], 200, nil, nil);

    // Then
    dispatch_async(self.logsDispatchQueue, ^{

      // Batch queue should not be full;
      assertThatBool(sut.pendingBatchQueueFull, isFalse());
      [oneLogSentExpectation fulfill];

      // When
      // Send another batch.
      currentBatchId++;
      [sut enqueueItem:[self getValidMockLog]];
      [self enqueueChannelEndJobExpectation];
    });
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {

                                 // Get sure it has been sent.
                                 assertThat(lastBatchLogContainer.batchId, is([@(currentBatchId) stringValue]));
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testDontForwardLogsToSenderOnDisabled {

  // If
  [self initChannelEndJobExpectation];
  int batchSizeLimit = 1;
  id mockLog = [self getValidMockLog];
  id senderMock = OCMProtocolMock(@protocol(MSSender));
  OCMReject([senderMock sendAsync:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
  OCMStub([senderMock sendAsync:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
  id storageMock = OCMProtocolMock(@protocol(MSStorage));
  OCMStub([storageMock
      loadLogsWithGroupId:kMSTestGroupId
                    limit:batchSizeLimit
           withCompletion:([OCMArg invokeBlockWithArgs:((NSArray<id<MSLog>> *)@[ mockLog ]), @"1", nil])]);
  MSChannelUnitConfiguration *config = [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                          priority:MSPriorityDefault
                                                                     flushInterval:0.0
                                                                    batchSizeLimit:batchSizeLimit
                                                               pendingBatchesLimit:10];
  self.sut.configuration = config;
  MSChannelUnitDefault *sut = [[MSChannelUnitDefault alloc] initWithSender:senderMock
                                                           storage:storageMock
                                                     configuration:config
                                                 logsDispatchQueue:dispatch_get_main_queue()];
  // When
  [sut setEnabled:NO andDeleteDataOnDisabled:NO];
  [sut enqueueItem:mockLog];
  [self enqueueChannelEndJobExpectation];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 OCMVerifyAll(senderMock);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testDeleteDataOnDisabled {

  // If
  [self initChannelEndJobExpectation];
  int batchSizeLimit = 1;
  id senderMock = OCMProtocolMock(@protocol(MSSender));
  id storageMock = OCMProtocolMock(@protocol(MSStorage));
  id mockLog = [self getValidMockLog];
  OCMStub([storageMock
      loadLogsWithGroupId:kMSTestGroupId
                    limit:batchSizeLimit
           withCompletion:([OCMArg invokeBlockWithArgs:((NSArray<id<MSLog>> *)@[ mockLog ]), @"1", nil])]);
  MSChannelUnitConfiguration *config = [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                          priority:MSPriorityDefault
                                                                     flushInterval:0.0
                                                                    batchSizeLimit:batchSizeLimit
                                                               pendingBatchesLimit:10];
  MSChannelUnitDefault *sut = [[MSChannelUnitDefault alloc] initWithSender:senderMock
                                                           storage:storageMock
                                                     configuration:config
                                                 logsDispatchQueue:dispatch_get_main_queue()];
  self.sut.configuration = config;

  // When
  [sut enqueueItem:mockLog];
  [sut setEnabled:NO andDeleteDataOnDisabled:YES];
  [self enqueueChannelEndJobExpectation];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {

                                 // Check that logs as been requested for deletion and that there is no batch left.
                                 OCMVerify([storageMock deleteLogsWithGroupId:kMSTestGroupId]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testDontSaveLogsWhileDisabledWithDataDeletion {

  // If
  [self initChannelEndJobExpectation];
  id mockLog = [self getValidMockLog];
  OCMReject([self.storageMock saveLog:OCMOCK_ANY withGroupId:OCMOCK_ANY]);
  MSChannelUnitDefault *sut = [self createChannelUnit];
  MSExpectantChannelDelegate *del = [MSExpectantChannelDelegate new];
  del.persistedHandler = ^(id<MSLog> log,
                           __attribute__((unused)) NSString *internalId,
                           __attribute__((unused)) BOOL success) {
    if (log == mockLog) {
      [self enqueueChannelEndJobExpectation];
    }
  };
  [sut addDelegate:del];

  // When
  [sut setEnabled:NO andDeleteDataOnDisabled:YES];
  [sut enqueueItem:mockLog];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 assertThatBool(sut.discardLogs, isTrue());
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testSaveLogsAfterReEnabled {

  // If
  [self initChannelEndJobExpectation];
  MSChannelUnitDefault *sut = [self createChannelUnit];
  [sut setEnabled:NO andDeleteDataOnDisabled:YES];
  id<MSLog> mockLog = [self getValidMockLog];
  MSExpectantChannelDelegate *del = OCMPartialMock([MSExpectantChannelDelegate new]);

  del.persistedHandler = ^(id<MSLog> log,
                           __attribute__((unused)) NSString *internalId,
                           __attribute__((unused)) BOOL success) {
    if (log == mockLog) {
      [self enqueueChannelEndJobExpectation];
    }
  };
  [sut addDelegate:del];

  // When
  [sut setEnabled:YES andDeleteDataOnDisabled:NO];
  [sut enqueueItem:mockLog];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 assertThatBool(sut.discardLogs, isFalse());
                                 OCMVerify([self.storageMock saveLog:mockLog withGroupId:OCMOCK_ANY]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  // If
  [self initChannelEndJobExpectation];
  id<MSLog> otherMockLog = [self getValidMockLog];
  [sut setEnabled:NO andDeleteDataOnDisabled:NO];
  del.persistedHandler = ^(id<MSLog> log,
                           __attribute__((unused)) NSString *internalId,
                           __attribute__((unused)) BOOL success) {
    if (log == otherMockLog) {
      [self enqueueChannelEndJobExpectation];
    }
  };
  // When
  [sut setEnabled:YES andDeleteDataOnDisabled:NO];
  [sut enqueueItem:otherMockLog];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 assertThatBool(sut.discardLogs, isFalse());
                                 OCMVerify([self.storageMock saveLog:mockLog withGroupId:OCMOCK_ANY]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testSuspendOnDisabled {

  // If
  [self initChannelEndJobExpectation];
  [self.sut setEnabled:YES andDeleteDataOnDisabled:NO];

  // When
  [self.sut setEnabled:NO andDeleteDataOnDisabled:NO];

  // Then
  [self enqueueChannelEndJobExpectation];
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 assertThatBool(self.sut.enabled, isFalse());
                                 assertThatBool(self.sut.suspended, isTrue());
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testResumeOnEnabled {

  // If
  __block BOOL result1, result2;
  [self initChannelEndJobExpectation];
  MSHttpSender *sender = [MSHttpSender new];
  self.sut.sender = sender;
  [self.sut setEnabled:NO andDeleteDataOnDisabled:NO];
  dispatch_async(self.logsDispatchQueue, ^{
    sender.suspended = NO;
  });

  // When
  [self.sut setEnabled:YES andDeleteDataOnDisabled:NO];
  dispatch_async(self.logsDispatchQueue, ^{
    result1 = self.sut.suspended;
  });

  // If
  [self.sut setEnabled:NO andDeleteDataOnDisabled:NO];
  dispatch_async(self.logsDispatchQueue, ^{
    sender.suspended = YES;
  });

  // When
  [self.sut setEnabled:YES andDeleteDataOnDisabled:NO];
  dispatch_async(self.logsDispatchQueue, ^{
    result2 = self.sut.suspended;
  });

  // Then
  [self enqueueChannelEndJobExpectation];
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 assertThatBool(result1, isFalse());
                                 assertThatBool(result2, isTrue());
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testDelegateAfterChannelDisabled {

  // If
  [self initChannelEndJobExpectation];
  id<MSChannelDelegate> delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  id mockLog = [self getValidMockLog];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
  MSChannelUnitDefault *sut = [[MSChannelUnitDefault alloc] initWithSender:nil
                                                           storage:nil
                                                     configuration:nil
                                                 logsDispatchQueue:dispatch_get_main_queue()];
#pragma clang diagnostic pop

  // When
  [sut addDelegate:delegateMock];
  [sut setEnabled:NO andDeleteDataOnDisabled:YES];
  [sut enqueueItem:mockLog];
  [self enqueueChannelEndJobExpectation];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {

                                 // Check the callbacks were invoked for logs.
                                 OCMVerify([delegateMock onEnqueuingLog:mockLog withInternalId:OCMOCK_ANY]);
                                 OCMVerify([delegateMock channel:sut willSendLog:mockLog]);
                                 OCMVerify([delegateMock channel:sut didFailSendingLog:mockLog withError:anything()]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

-(void)testDeviceAndTimestampAreAddedOnEnqueuing {

  // If
  id<MSLog> mockLog = [self getValidMockLog];
  mockLog.device = nil;
  mockLog.timestamp = nil;
  MSChannelUnitDefault *sut = [self createChannelUnit];

  // When
  [sut enqueueItem:mockLog];

  // Then
  XCTAssertNotNil(mockLog.device);
  XCTAssertNotNil(mockLog.timestamp);
}

-(void)testDeviceAndTimestampAreNotOverwrittenOnEnqueuing{

  // If
  id<MSLog> mockLog = [self getValidMockLog];
  MSDevice *device = mockLog.device = [MSDevice new];
  NSDate *timestamp = mockLog.timestamp = [NSDate new];
  MSChannelUnitDefault *sut = [self createChannelUnit];

  // When
  [sut enqueueItem:mockLog];

  // Then
  XCTAssertEqual(mockLog.device, device);
  XCTAssertEqual(mockLog.timestamp, timestamp);
}

- (void)testEnqueuingLogDoesNotPersistFilteredLogs {

  // If
  [self initChannelEndJobExpectation];
  MSChannelUnitDefault *sut = [self createChannelUnit];
  id<MSLog> log = [self getValidMockLog];
  id mockDelegate = OCMPartialMock([MSExpectantChannelDelegate new]);
  OCMStub([mockDelegate shouldFilterLog:log]).andReturn(YES);
  [sut addDelegate:mockDelegate];
  OCMReject([mockDelegate onFinishedPersistingLog:log withInternalId:OCMOCK_ANY]);
  OCMReject([mockDelegate onFailedPersistingLog:log withInternalId:OCMOCK_ANY]);
  OCMExpect([mockDelegate onEnqueuingLog:log withInternalId:OCMOCK_ANY]);

  // When
  [sut enqueueItem:log];

  // Then
  dispatch_async(self.logsDispatchQueue, ^{
    [self enqueueChannelEndJobExpectation];
  });
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 (void)error;
                                 OCMVerifyAll(mockDelegate);
                               }];

  // If
  // Add another filter that returns NO. The log should still be filtered because of mockDelegate.
  [self initChannelEndJobExpectation];
  id mockDelegate2 = OCMPartialMock([MSExpectantChannelDelegate new]);
  OCMStub([mockDelegate2 shouldFilterLog:log]).andReturn(NO);
  [sut addDelegate:mockDelegate];
  OCMReject([mockDelegate2 onFinishedPersistingLog:log withInternalId:OCMOCK_ANY]);
  OCMReject([mockDelegate2 onFailedPersistingLog:log withInternalId:OCMOCK_ANY]);
  OCMExpect([mockDelegate2 onEnqueuingLog:log withInternalId:OCMOCK_ANY]);
  [sut addDelegate:mockDelegate2];

  // When
  [sut enqueueItem:log];

  // Then
  dispatch_async(self.logsDispatchQueue, ^{
    [self enqueueChannelEndJobExpectation];
  });
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 (void)error;
                                 OCMVerifyAll(mockDelegate2);
                               }];
}

- (void)testEnqueuingLogPersistsUnfilteredLogs {

  // If
  [self initChannelEndJobExpectation];
  MSChannelUnitDefault *sut = [self createChannelUnit];
  id<MSLog> log = [self getValidMockLog];
  OCMStub([sut.storage saveLog:log withGroupId:OCMOCK_ANY]).andReturn(YES);
  id mockDelegate = OCMPartialMock([MSExpectantChannelDelegate new]);
  OCMStub([mockDelegate shouldFilterLog:log]).andReturn(NO);
  [sut addDelegate:mockDelegate];
  OCMExpect([mockDelegate onEnqueuingLog:log withInternalId:OCMOCK_ANY]);
  OCMExpect([mockDelegate onFinishedPersistingLog:log withInternalId:OCMOCK_ANY]);

  // When
  [sut enqueueItem:log];

  // Then
  dispatch_async(self.logsDispatchQueue, ^{
    [self enqueueChannelEndJobExpectation];
  });
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 (void)error;
                                 OCMVerifyAll(mockDelegate);
                               }];

}

#pragma mark - Helper

- (void)initChannelEndJobExpectation {
  self.channelEndJobExpectation = [self expectationWithDescription:@"Channel job should be finished"];
}

- (void)enqueueChannelEndJobExpectation {

  // Enqueue end job expectation on channel's queue to detect when channel finished processing.
  dispatch_async(self.logsDispatchQueue, ^{
    [self.channelEndJobExpectation fulfill];
  });
}

- (id)getValidMockLog {
  id mockLog = OCMPartialMock([MSAbstractLog new]);
  OCMStub([mockLog isValid]).andReturn(YES);
  return mockLog;
}


- (MSChannelUnitDefault*)createChannelUnit {
  return [[MSChannelUnitDefault alloc] initWithSender:self.senderMock
                                              storage:self.storageMock
                                        configuration:self.configMock
                                    logsDispatchQueue:self.logsDispatchQueue];

}

@end

