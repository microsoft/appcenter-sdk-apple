#import <Foundation/Foundation.h>

#import "MSAbstractLogInternal.h"
#import "MSChannelConfiguration.h"
#import "MSChannelDefault.h"
#import "MSChannelDefaultPrivate.h"
#import "MSChannelDelegate.h"
#import "MSHttpSender.h"
#import "MSLogContainer.h"
#import "MSMobileCenterErrors.h"
#import "MSTestFrameworks.h"
#import "MSUtility.h"

static NSString *const kMSTestGroupId = @"GroupId";

@interface MSChannelDefaultTests : XCTestCase

@property(nonatomic) MSChannelDefault *sut;

@property(nonatomic) dispatch_queue_t logsDispatchQueue;

@property(nonatomic) MSChannelConfiguration *configMock;

@property(nonatomic) id<MSStorage> storageMock;

@property(nonatomic) id<MSSender> senderMock;

/**
 * Most of the channel APIs are asynchronous, this expectation is meant to be enqueued to the data dispatch queue
 * at the end of the test before any asserts. Then it will be triggered on the next queue loop right after the channel
 * finished its job. Wrap asserts within the handler of a waitForExpectationsWithTimeout method.
 */
@property(nonatomic) XCTestExpectation *channelEndJobExpectation;

@end

@implementation MSChannelDefaultTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];

  self.logsDispatchQueue = dispatch_get_main_queue();
  self.configMock = OCMClassMock([MSChannelConfiguration class]);
  self.storageMock = OCMProtocolMock(@protocol(MSStorage));
  self.senderMock = OCMProtocolMock(@protocol(MSSender));
  self.sut = [[MSChannelDefault alloc] initWithSender:self.senderMock
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

  /*
   * If
   */
  [self initChannelEndJobExpectation];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  __block MSSendAsyncCompletionHandler senderBlock;
  __block MSLogContainer *logContainer;
  __block NSString *expectedBatchId = @"1";
  int batchSizeLimit = 1;
  id<MSLog> expectedLog = [MSAbstractLog new];
  expectedLog.sid = MS_UUID_STRING;

  // Init mocks.
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
  MSChannelConfiguration *config = [[MSChannelConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                          priority:MSPriorityDefault
                                                                     flushInterval:0.0
                                                                    batchSizeLimit:batchSizeLimit
                                                               pendingBatchesLimit:1];
  self.sut.configuration = config;
  MSChannelDefault *sut = [[MSChannelDefault alloc] initWithSender:senderMock
                                                           storage:storageMock
                                                     configuration:config
                                                 logsDispatchQueue:dispatch_get_main_queue()];
  [sut addDelegate:delegateMock];
  OCMReject([delegateMock channel:sut didFailSendingLog:OCMOCK_ANY withError:OCMOCK_ANY]);
  OCMExpect([delegateMock channel:sut didSucceedSendingLog:expectedLog]);
  OCMExpect([storageMock deleteLogsWithBatchId:expectedBatchId groupId:kMSTestGroupId]);

  /*
   * When
   */
  [sut enqueueItem:[self getValidMockLog] withCompletion:nil];

  // Try to release one batch.
  dispatch_async(self.logsDispatchQueue, ^{
    senderBlock([@(1) stringValue], 200, nil, nil);

    /*
     * Then
     */
    dispatch_async(self.logsDispatchQueue, ^{
      [self enqueueChannelEndJobExpectation];
    });
  });

  /*
   * Then
   */
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

  /*
   * If
   */
  [self initChannelEndJobExpectation];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  __block MSSendAsyncCompletionHandler senderBlock;
  __block MSLogContainer *logContainer;
  __block NSString *expectedBatchId = @"1";
  int batchSizeLimit = 1;
  id<MSLog> expectedLog = [MSAbstractLog new];
  expectedLog.sid = MS_UUID_STRING;

  // Init mocks.
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
  MSChannelConfiguration *config = [[MSChannelConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                          priority:MSPriorityDefault
                                                                     flushInterval:0.0
                                                                    batchSizeLimit:batchSizeLimit
                                                               pendingBatchesLimit:1];
  self.sut.configuration = config;
  MSChannelDefault *sut = [[MSChannelDefault alloc] initWithSender:senderMock
                                                           storage:storageMock
                                                     configuration:config
                                                 logsDispatchQueue:dispatch_get_main_queue()];
  [sut addDelegate:delegateMock];
  OCMExpect([delegateMock channel:sut didFailSendingLog:expectedLog withError:OCMOCK_ANY]);
  OCMReject([delegateMock channel:sut didSucceedSendingLog:OCMOCK_ANY]);
  OCMExpect([storageMock deleteLogsWithBatchId:expectedBatchId groupId:kMSTestGroupId]);

  /*
   * When
   */
  [sut enqueueItem:[self getValidMockLog] withCompletion:nil];

  // Try to release one batch.
  dispatch_async(self.logsDispatchQueue, ^{
    senderBlock([@(1) stringValue], 300, nil, nil);

    /*
     * Then
     */
    dispatch_async(self.logsDispatchQueue, ^{
      [self enqueueChannelEndJobExpectation];
    });
  });

  /*
   * Then
   */
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
  MSChannelConfiguration *config = [[MSChannelConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                          priority:MSPriorityDefault
                                                                     flushInterval:5
                                                                    batchSizeLimit:10
                                                               pendingBatchesLimit:3];
  self.sut.configuration = config;
  int itemsToAdd = 3;

  // When
  for (int i = 1; i <= itemsToAdd; i++) {
    [self.sut enqueueItem:[self getValidMockLog] withCompletion:nil];
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
  MSChannelConfiguration *config = [[MSChannelConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                          priority:MSPriorityDefault
                                                                     flushInterval:0.0
                                                                    batchSizeLimit:3
                                                               pendingBatchesLimit:3];
  self.sut.configuration = config;
  int itemsToAdd = 3;
  XCTestExpectation *expectation = [self expectationWithDescription:@"All items enqueued"];

  // When
  for (int i = 1; i <= itemsToAdd; i++) {

    [self.sut enqueueItem:[self getValidMockLog]
           withCompletion:^(__attribute__((unused)) BOOL success) {
             if (i == itemsToAdd) {
               [expectation fulfill];
             }
           }];
  }
  [self enqueueChannelEndJobExpectation];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 assertThatUnsignedLong(self.sut.itemsCount, equalToInt(0));
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
  MSChannelConfiguration *config = [[MSChannelConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                          priority:MSPriorityDefault
                                                                     flushInterval:0.0
                                                                    batchSizeLimit:batchSizeLimit
                                                               pendingBatchesLimit:expectedMaxPendingBatched];
  self.sut.configuration = config;
  MSChannelDefault *sut = [[MSChannelDefault alloc] initWithSender:senderMock
                                                           storage:storageMock
                                                     configuration:config
                                                 logsDispatchQueue:self.logsDispatchQueue];

  // When
  for (NSUInteger i = 1; i <= expectedMaxPendingBatched + 1; i++) {
    [sut enqueueItem:[self getValidMockLog] withCompletion:nil];
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

  /*
   * If
   */
  [self initChannelEndJobExpectation];
  XCTestExpectation *oneLogSentExpectation = [self expectationWithDescription:@"One log sent"];
  __block MSSendAsyncCompletionHandler senderBlock;
  __block MSLogContainer *lastBatchLogContainer;
  __block int currentBatchId = 1;
  int batchSizeLimit = 1;

  // Init mocks.
  id senderMock = OCMProtocolMock(@protocol(MSSender));
  OCMStub([senderMock sendAsync:OCMOCK_ANY completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {

    // Get sender bloc for later call.
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
  MSChannelConfiguration *config = [[MSChannelConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                          priority:MSPriorityDefault
                                                                     flushInterval:0.0
                                                                    batchSizeLimit:batchSizeLimit
                                                               pendingBatchesLimit:1];
  self.sut.configuration = config;
  MSChannelDefault *sut = [[MSChannelDefault alloc] initWithSender:senderMock
                                                           storage:storageMock
                                                     configuration:config
                                                 logsDispatchQueue:dispatch_get_main_queue()];

  /*
   * When
   */
  [sut enqueueItem:[self getValidMockLog] withCompletion:nil];

  // Try to release one batch.
  dispatch_async(self.logsDispatchQueue, ^{
    senderBlock([@(1) stringValue], 200, nil, nil);

    /*
     * Then
     */
    dispatch_async(self.logsDispatchQueue, ^{

      // Batch queue should not be full;
      assertThatBool(sut.pendingBatchQueueFull, isFalse());
      [oneLogSentExpectation fulfill];

      /*
       * When
       */

      // Send another batch.
      currentBatchId++;
      [sut enqueueItem:[self getValidMockLog] withCompletion:nil];
      [self enqueueChannelEndJobExpectation];
    });
  });

  /*
   * Then
   */
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
  MSChannelConfiguration *config = [[MSChannelConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                          priority:MSPriorityDefault
                                                                     flushInterval:0.0
                                                                    batchSizeLimit:batchSizeLimit
                                                               pendingBatchesLimit:10];
  self.sut.configuration = config;
  MSChannelDefault *sut = [[MSChannelDefault alloc] initWithSender:senderMock
                                                           storage:storageMock
                                                     configuration:config
                                                 logsDispatchQueue:dispatch_get_main_queue()];
  /*
   * When
   */
  [sut setEnabled:NO andDeleteDataOnDisabled:NO];
  [sut enqueueItem:mockLog withCompletion:nil];
  [self enqueueChannelEndJobExpectation];

  /*
   * Then
   */
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
  MSChannelConfiguration *config = [[MSChannelConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                          priority:MSPriorityDefault
                                                                     flushInterval:0.0
                                                                    batchSizeLimit:batchSizeLimit
                                                               pendingBatchesLimit:10];
  self.sut.configuration = config;
  MSChannelDefault *sut = [[MSChannelDefault alloc] initWithSender:senderMock
                                                           storage:storageMock
                                                     configuration:config
                                                 logsDispatchQueue:dispatch_get_main_queue()];
  // When
  [sut enqueueItem:mockLog withCompletion:nil];
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

  // When
  [self.sut setEnabled:NO andDeleteDataOnDisabled:YES];
  [self.sut enqueueItem:mockLog
         withCompletion:^(__attribute__((unused)) BOOL success) {
           [self enqueueChannelEndJobExpectation];
         }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 assertThatBool(self.sut.discardLogs, isTrue());
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testSaveLogsAfterReEnabled {

  // If
  [self initChannelEndJobExpectation];
  [self.sut setEnabled:NO andDeleteDataOnDisabled:YES];
  id mockLog = [self getValidMockLog];

  // When
  [self.sut setEnabled:YES andDeleteDataOnDisabled:NO];
  [self.sut enqueueItem:mockLog
         withCompletion:^(__attribute__((unused)) BOOL success) {
           [self enqueueChannelEndJobExpectation];
         }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 assertThatBool(self.sut.discardLogs, isFalse());
                                 OCMVerify([self.storageMock saveLog:mockLog withGroupId:OCMOCK_ANY]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  // If
  [self initChannelEndJobExpectation];
  [self.sut setEnabled:NO andDeleteDataOnDisabled:NO];

  // When
  [self.sut setEnabled:YES andDeleteDataOnDisabled:NO];
  [self.sut enqueueItem:mockLog
         withCompletion:^(__attribute__((unused)) BOOL success) {
           [self enqueueChannelEndJobExpectation];
         }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 assertThatBool(self.sut.discardLogs, isFalse());
                                 OCMVerify([self.storageMock saveLog:mockLog withGroupId:OCMOCK_ANY]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testDisableAndDeleteDataOnSenderFatalError {

  // If
  [self initChannelEndJobExpectation];
  id senderMock = OCMProtocolMock(@protocol(MSSender));
  id storageMock = OCMProtocolMock(@protocol(MSStorage));
  id mockLog = [self getValidMockLog];
  OCMStub([storageMock
      loadLogsWithGroupId:kMSTestGroupId
                    limit:2
           withCompletion:([OCMArg invokeBlockWithArgs:((NSArray<id<MSLog>> *)@[ mockLog ]), @"1", nil])]);
  MSChannelConfiguration *config = [[MSChannelConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                          priority:MSPriorityDefault
                                                                     flushInterval:0.0
                                                                    batchSizeLimit:1
                                                               pendingBatchesLimit:10];
  self.sut.configuration = config;
  MSChannelDefault *sut = [[MSChannelDefault alloc] initWithSender:senderMock
                                                           storage:storageMock
                                                     configuration:config
                                                 logsDispatchQueue:dispatch_get_main_queue()];
  // When
  [sut enqueueItem:mockLog withCompletion:nil];
  [sut senderDidReceiveFatalError:senderMock];
  [self enqueueChannelEndJobExpectation];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {

                                 // Check that logs as been requested for deletion and that there is no batch left.
                                 OCMVerify([storageMock deleteLogsWithGroupId:kMSTestGroupId]);
                                 assertThatBool(sut.enabled, isFalse());
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

- (void)testSuspendOnSenderSuspended {

  // If
  __block BOOL result1, result2;
  [self initChannelEndJobExpectation];
  [self.sut setEnabled:NO andDeleteDataOnDisabled:NO];

  // When
  [self.sut senderDidSuspend:self.senderMock];
  dispatch_async(self.logsDispatchQueue, ^{
    result1 = self.sut.suspended;
  });

  // If
  [self.sut setEnabled:YES andDeleteDataOnDisabled:NO];

  // When
  [self.sut senderDidSuspend:self.senderMock];
  dispatch_async(self.logsDispatchQueue, ^{
    result2 = self.sut.suspended;
  });
  [self enqueueChannelEndJobExpectation];
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 assertThatBool(result1, isTrue());
                                 assertThatBool(result2, isTrue());
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testSuspendOnSenderResumed {

  // If
  __block BOOL result1, result2;
  [self initChannelEndJobExpectation];
  [self.sut setEnabled:NO andDeleteDataOnDisabled:NO];

  // When
  [self.sut senderDidResume:self.senderMock];
  dispatch_async(self.logsDispatchQueue, ^{
    result1 = self.sut.suspended;
  });

  // If
  [self.sut setEnabled:YES andDeleteDataOnDisabled:NO];
  [self.sut senderDidSuspend:self.senderMock];

  // When
  [self.sut senderDidResume:self.senderMock];
  dispatch_async(self.logsDispatchQueue, ^{
    result2 = self.sut.suspended;
  });

  // Then
  [self enqueueChannelEndJobExpectation];
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 assertThatBool(result1, isTrue());
                                 assertThatBool(result2, isFalse());
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
  MSChannelDefault *sut = [[MSChannelDefault alloc] initWithSender:nil
                                                           storage:nil
                                                     configuration:nil
                                                 logsDispatchQueue:dispatch_get_main_queue()];
#pragma clang diagnostic pop

  // When
  [sut addDelegate:delegateMock];
  [sut setEnabled:NO andDeleteDataOnDisabled:YES];
  [sut enqueueItem:mockLog withCompletion:nil];
  [self enqueueChannelEndJobExpectation];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {

                                 // Check the callbacks were invoked for logs.
                                 OCMVerify([delegateMock channel:sut willSendLog:mockLog]);
                                 OCMVerify([delegateMock channel:sut didFailSendingLog:mockLog withError:anything()]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
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

@end
