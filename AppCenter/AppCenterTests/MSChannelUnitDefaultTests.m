#import <Foundation/Foundation.h>

#import "MSAbstractLogInternal.h"
#import "MSAppCenterErrors.h"
#import "MSChannelDelegate.h"
#import "MSChannelUnitConfiguration.h"
#import "MSChannelUnitDefault.h"
#import "MSDevice.h"
#import "MSHttpIngestion.h"
#import "MSIngestionProtocol.h"
#import "MSLogContainer.h"
#import "MSStorage.h"
#import "MSTestFrameworks.h"
#import "MSUtility.h"

static NSString *const kMSTestGroupId = @"GroupId";

@interface MSChannelUnitDefaultTests : XCTestCase

@property(nonatomic) MSChannelUnitDefault *sut;

@property(nonatomic) dispatch_queue_t logsDispatchQueue;

@property(nonatomic) MSChannelUnitConfiguration *configMock;

@property(nonatomic) id<MSStorage> storageMock;

@property(nonatomic) id<MSIngestionProtocol> ingestionMock;

/**
 * Most of the channel APIs are asynchronous, this expectation is meant to be
 * enqueued to the data dispatch queue at the end of the test before any
 * asserts. Then it will be triggered on the next queue loop right after the
 * channel finished its job. Wrap asserts within the handler of a
 * waitForExpectationsWithTimeout method.
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
  OCMStub([self.storageMock saveLog:OCMOCK_ANY withGroupId:OCMOCK_ANY])
      .andReturn(YES);
  self.ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));
  self.sut =
      [[MSChannelUnitDefault alloc] initWithIngestion:self.ingestionMock
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
  assertThat(self.sut.ingestion, equalTo(self.ingestionMock));
  assertThat(self.sut.storage, equalTo(self.storageMock));
  assertThat(self.sut.appSecret, nilValue());
  assertThatUnsignedLong(self.sut.itemsCount, equalToInt(0));
  OCMVerify([self.ingestionMock addDelegate:self.sut]);
}

- (void)testSetAppSecret {

  // When new MSChannelUnitDefault

  // Then
  assertThat(self.sut.appSecret, nilValue());

  // When
  self.sut.appSecret = @"TestAppSecret";

  // Then
  XCTAssertEqual(self.sut.appSecret, @"TestAppSecret");
}

- (void)testLogsSentWithSuccess {

  // If
  [self initChannelEndJobExpectation];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  __block MSSendAsyncCompletionHandler ingestionBlock;
  __block MSLogContainer *logContainer;
  __block NSString *expectedBatchId = @"1";
  int batchSizeLimit = 1;
  id<MSLog> expectedLog = [MSAbstractLog new];
  expectedLog.sid = MS_UUID_STRING;

  // Init mocks.
  id<MSLog> enqueuedLog = [self getValidMockLog];
  id ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));
  OCMStub([ingestionMock sendAsync:OCMOCK_ANY
                         appSecret:OCMOCK_ANY
                 completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {

        // Get ingestion block for later call.
        [invocation retainArguments];
        [invocation getArgument:&ingestionBlock atIndex:4];
        [invocation getArgument:&logContainer atIndex:2];
      });

  // Stub the storage load for that log.
  id storageMock = OCMProtocolMock(@protocol(MSStorage));
  OCMStub([storageMock saveLog:OCMOCK_ANY withGroupId:OCMOCK_ANY])
      .andReturn(YES);
  OCMStub([storageMock loadLogsWithGroupId:kMSTestGroupId
                                     limit:batchSizeLimit
                            withCompletion:(OCMOCK_ANY)])
      .andDo(^(NSInvocation *invocation) {
        MSLoadDataCompletionBlock loadCallback;

        // Get ingestion block for later call.
        [invocation getArgument:&loadCallback atIndex:4];

        // Mock load.
        loadCallback(((NSArray<id<MSLog>> *)@[ expectedLog ]), expectedBatchId);
      });

  // Configure channel.
  MSChannelUnitConfiguration *config =
      [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                 priority:MSPriorityDefault
                                            flushInterval:0.0
                                           batchSizeLimit:batchSizeLimit
                                      pendingBatchesLimit:1];
  self.sut.configuration = config;
  MSChannelUnitDefault *sut = [[MSChannelUnitDefault alloc]
      initWithIngestion:ingestionMock
                storage:storageMock
          configuration:config
      logsDispatchQueue:dispatch_get_main_queue()];
  [sut setAppSecret:MS_UUID_STRING];
  [sut addDelegate:delegateMock];
  OCMReject([delegateMock channel:sut
                didFailSendingLog:OCMOCK_ANY
                        withError:OCMOCK_ANY]);
  OCMExpect([delegateMock channel:sut didSucceedSendingLog:expectedLog]);
  OCMExpect([delegateMock channel:sut prepareLog:enqueuedLog]);
  OCMExpect([delegateMock channel:sut
                    didPrepareLog:enqueuedLog
                   withInternalId:OCMOCK_ANY]);
  OCMExpect([delegateMock channel:sut
         didCompleteEnqueueingLog:enqueuedLog
                   withInternalId:OCMOCK_ANY]);
  OCMExpect([storageMock deleteLogsWithBatchId:expectedBatchId
                                       groupId:kMSTestGroupId]);

  // When
  dispatch_async(self.logsDispatchQueue, ^{

    // Enqueue now that the delegate is set.
    [sut enqueueItem:enqueuedLog];

    // Try to release one batch.
    dispatch_async(self.logsDispatchQueue, ^{
      XCTAssertNotNil(ingestionBlock);
      if (ingestionBlock) {
        ingestionBlock([@(1) stringValue], 200, nil, nil);
      }

      // Then
      dispatch_async(self.logsDispatchQueue, ^{
        [self enqueueChannelEndJobExpectation];
      });
    });
  });

  // Then
  [self
      waitForExpectationsWithTimeout:1
                             handler:^(NSError *error) {

                               // Get sure it has been sent.
                               assertThat(logContainer.batchId,
                                          is(expectedBatchId));
                               assertThat(logContainer.logs,
                                          is(@[ expectedLog ]));
                               assertThatBool(sut.pendingBatchQueueFull,
                                              isFalse());
                               assertThatUnsignedLong(sut.pendingBatchIds.count,
                                                      equalToUnsignedLong(0));
                               OCMVerifyAll(delegateMock);
                               OCMVerifyAll(storageMock);
                               if (error) {
                                 XCTFail(@"Expectation Failed with error: %@",
                                         error);
                               }
                             }];
}

- (void)testLogsSentWithFailure {

  // If
  [self initChannelEndJobExpectation];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  __block MSSendAsyncCompletionHandler ingestionBlock;
  __block MSLogContainer *logContainer;
  __block NSString *expectedBatchId = @"1";
  int batchSizeLimit = 1;
  id<MSLog> expectedLog = [MSAbstractLog new];
  expectedLog.sid = MS_UUID_STRING;

  // Init mocks.
  id<MSLog> enqueuedLog = [self getValidMockLog];
  id ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));
  OCMStub([ingestionMock sendAsync:OCMOCK_ANY
                         appSecret:OCMOCK_ANY
                 completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {

        // Get ingestion block for later call.
        [invocation retainArguments];
        [invocation getArgument:&ingestionBlock atIndex:4];
        [invocation getArgument:&logContainer atIndex:2];
      });

  // Stub the storage load for that log.
  id storageMock = OCMProtocolMock(@protocol(MSStorage));
  OCMStub([storageMock loadLogsWithGroupId:kMSTestGroupId
                                     limit:batchSizeLimit
                            withCompletion:(OCMOCK_ANY)])
      .andDo(^(NSInvocation *invocation) {
        MSLoadDataCompletionBlock loadCallback;

        // Get ingestion block for later call.
        [invocation getArgument:&loadCallback atIndex:4];

        // Mock load.
        loadCallback(((NSArray<id<MSLog>> *)@[ expectedLog ]), expectedBatchId);
      });

  // Configure channel.
  MSChannelUnitConfiguration *config =
      [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                 priority:MSPriorityDefault
                                            flushInterval:0.0
                                           batchSizeLimit:batchSizeLimit
                                      pendingBatchesLimit:1];
  self.sut.configuration = config;
  MSChannelUnitDefault *sut = [[MSChannelUnitDefault alloc]
      initWithIngestion:ingestionMock
                storage:storageMock
          configuration:config
      logsDispatchQueue:dispatch_get_main_queue()];
  [sut setAppSecret:MS_UUID_STRING];
  [sut addDelegate:delegateMock];
  OCMExpect([delegateMock channel:sut
                didFailSendingLog:expectedLog
                        withError:OCMOCK_ANY]);
  OCMReject([delegateMock channel:sut didSucceedSendingLog:OCMOCK_ANY]);
  OCMExpect([delegateMock channel:sut
                    didPrepareLog:enqueuedLog
                   withInternalId:OCMOCK_ANY]);
  OCMExpect([delegateMock channel:sut
         didCompleteEnqueueingLog:enqueuedLog
                   withInternalId:OCMOCK_ANY]);
  OCMExpect([storageMock deleteLogsWithBatchId:expectedBatchId
                                       groupId:kMSTestGroupId]);

  // When
  dispatch_async(self.logsDispatchQueue, ^{

    // Enqueue now that the delegate is set.
    [sut enqueueItem:enqueuedLog];

    // Try to release one batch.
    dispatch_async(self.logsDispatchQueue, ^{
      XCTAssertNotNil(ingestionBlock);
      if (ingestionBlock) {
        ingestionBlock([@(1) stringValue], 300, nil, nil);
      }

      // Then
      [self enqueueChannelEndJobExpectation];
    });
  });

  // Then
  [self
      waitForExpectationsWithTimeout:1
                             handler:^(NSError *error) {

                               // Get sure it has been sent.
                               assertThat(logContainer.batchId,
                                          is(expectedBatchId));
                               assertThat(logContainer.logs,
                                          is(@[ expectedLog ]));
                               assertThatBool(sut.pendingBatchQueueFull,
                                              isFalse());
                               assertThatUnsignedLong(sut.pendingBatchIds.count,
                                                      equalToUnsignedLong(0));
                               OCMVerifyAll(delegateMock);
                               OCMVerifyAll(storageMock);
                               if (error) {
                                 XCTFail(@"Expectation Failed with error: %@",
                                         error);
                               }
                             }];
}

- (void)testEnqueuingItemsWillIncreaseCounter {

  // If
  [self initChannelEndJobExpectation];
  MSChannelUnitConfiguration *config =
      [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                 priority:MSPriorityDefault
                                            flushInterval:5
                                           batchSizeLimit:10
                                      pendingBatchesLimit:3];
  self.sut.configuration = config;
  [self.sut setAppSecret:MS_UUID_STRING];
  int itemsToAdd = 3;

  // When
  for (int i = 1; i <= itemsToAdd; i++) {
    [self.sut enqueueItem:[self getValidMockLog]];
  }
  [self enqueueChannelEndJobExpectation];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 assertThatUnsignedLong(self.sut.itemsCount,
                                                        equalToInt(itemsToAdd));
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@",
                                           error);
                                 }
                               }];
}

- (void)testQueueFlushedAfterBatchSizeReached {

  // If
  [self initChannelEndJobExpectation];
  MSChannelUnitConfiguration *config =
      [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                 priority:MSPriorityDefault
                                            flushInterval:0.0
                                           batchSizeLimit:3
                                      pendingBatchesLimit:3];
  self.sut.configuration = config;
  MSChannelUnitDefault *sut =
      [[MSChannelUnitDefault alloc] initWithIngestion:self.ingestionMock
                                              storage:self.storageMock
                                        configuration:config
                                    logsDispatchQueue:self.logsDispatchQueue];
  int itemsToAdd = 3;
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"All items enqueued"];
  id<MSLog> mockLog = [self getValidMockLog];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  OCMStub([delegateMock channel:sut
              didCompleteEnqueueingLog:mockLog
                        withInternalId:OCMOCK_ANY])
      .andDo(^(__unused NSInvocation *invocation) {
        static int count = 0;
        count++;
        if (count == itemsToAdd) {
          [expectation fulfill];
        }
      });
  [sut addDelegate:delegateMock];

  // When
  for (int i = 0; i < itemsToAdd; ++i) {
    [sut enqueueItem:mockLog];
  }
  [self enqueueChannelEndJobExpectation];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 assertThatUnsignedLong(sut.itemsCount,
                                                        equalToInt(0));
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@",
                                           error);
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
  id ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));
  OCMStub([ingestionMock sendAsync:OCMOCK_ANY
                         appSecret:OCMOCK_ANY
                 completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {

        MSLogContainer *container;
        [invocation getArgument:&container atIndex:2];
        if (container) {
          [sentBatchIds addObject:container.batchId];
        }
      });
  id storageMock = OCMProtocolMock(@protocol(MSStorage));
  OCMStub([storageMock loadLogsWithGroupId:kMSTestGroupId
                                     limit:batchSizeLimit
                            withCompletion:(OCMOCK_ANY)])
      .andDo(^(NSInvocation *invocation) {
        MSLoadDataCompletionBlock loadCallback;

        // Mock load.
        [invocation getArgument:&loadCallback atIndex:4];
        loadCallback(
            ((NSArray<id<MSLog>> *)@[ OCMProtocolMock(@protocol(MSLog)) ]),
            [@(currentBatchId++) stringValue]);
      });
  MSChannelUnitConfiguration *config = [[MSChannelUnitConfiguration alloc]
          initWithGroupId:kMSTestGroupId
                 priority:MSPriorityDefault
            flushInterval:0.0
           batchSizeLimit:batchSizeLimit
      pendingBatchesLimit:expectedMaxPendingBatched];
  self.sut.configuration = config;
  MSChannelUnitDefault *sut =
      [[MSChannelUnitDefault alloc] initWithIngestion:ingestionMock
                                              storage:storageMock
                                        configuration:config
                                    logsDispatchQueue:self.logsDispatchQueue];
  [sut setAppSecret:MS_UUID_STRING];
  [self.sut setAppSecret:MS_UUID_STRING];

  // When
  for (NSUInteger i = 1; i <= expectedMaxPendingBatched + 1; i++) {
    [sut enqueueItem:[self getValidMockLog]];
  }
  [self enqueueChannelEndJobExpectation];

  // Then
  [self waitForExpectationsWithTimeout:100
                               handler:^(NSError *error) {
                                 assertThatUnsignedLong(
                                     sut.pendingBatchIds.count,
                                     equalToUnsignedLong(
                                         expectedMaxPendingBatched));
                                 assertThatUnsignedLong(
                                     sentBatchIds.count,
                                     equalToUnsignedLong(
                                         expectedMaxPendingBatched));
                                 assertThat(sentBatchIds[0], is(@"1"));
                                 assertThat(sentBatchIds[1], is(@"2"));
                                 assertThatBool(sut.pendingBatchQueueFull,
                                                isTrue());
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@",
                                           error);
                                 }
                               }];
}

- (void)testNextBatchSentIfPendingQueueGotRoomAgain {

  // If
  [self initChannelEndJobExpectation];
  XCTestExpectation *oneLogSentExpectation =
      [self expectationWithDescription:@"One log sent"];
  __block MSSendAsyncCompletionHandler ingestionBlock;
  __block MSLogContainer *lastBatchLogContainer;
  __block int currentBatchId = 1;
  int batchSizeLimit = 1;

  // Init mocks.
  id ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));
  OCMStub([ingestionMock sendAsync:OCMOCK_ANY
                         appSecret:OCMOCK_ANY
                 completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {

        // Get ingestion block for later call.
        [invocation retainArguments];
        [invocation getArgument:&ingestionBlock atIndex:4];
        [invocation getArgument:&lastBatchLogContainer atIndex:2];
      });

  // Stub the storage load for that log.
  id storageMock = OCMProtocolMock(@protocol(MSStorage));
  OCMStub([storageMock loadLogsWithGroupId:kMSTestGroupId
                                     limit:batchSizeLimit
                            withCompletion:(OCMOCK_ANY)])
      .andDo(^(NSInvocation *invocation) {
        MSLoadDataCompletionBlock loadCallback;

        // Get ingestion block for later call.
        [invocation getArgument:&loadCallback atIndex:4];

        // Mock load.
        loadCallback(
            ((NSArray<id<MSLog>> *)@[ OCMProtocolMock(@protocol(MSLog)) ]),
            [@(currentBatchId) stringValue]);
      });

  // Configure channel.
  MSChannelUnitConfiguration *config =
      [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                 priority:MSPriorityDefault
                                            flushInterval:0.0
                                           batchSizeLimit:batchSizeLimit
                                      pendingBatchesLimit:1];
  self.sut.configuration = config;
  MSChannelUnitDefault *sut = [[MSChannelUnitDefault alloc]
      initWithIngestion:ingestionMock
                storage:storageMock
          configuration:config
      logsDispatchQueue:dispatch_get_main_queue()];
  [sut setAppSecret:MS_UUID_STRING];

  // When
  [sut enqueueItem:[self getValidMockLog]];

  // Try to release one batch.
  dispatch_async(self.logsDispatchQueue, ^{
    ingestionBlock([@(1) stringValue], 200, nil, nil);

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
  [self
      waitForExpectationsWithTimeout:1
                             handler:^(NSError *error) {

                               // Get sure it has been sent.
                               assertThat(lastBatchLogContainer.batchId,
                                          is([@(currentBatchId) stringValue]));
                               if (error) {
                                 XCTFail(@"Expectation Failed with error: %@",
                                         error);
                               }
                             }];
}

- (void)testDontForwardLogsToIngestionOnDisabled {

  // If
  [self initChannelEndJobExpectation];
  int batchSizeLimit = 1;
  id mockLog = [self getValidMockLog];
  id ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));
  OCMReject([ingestionMock sendAsync:OCMOCK_ANY
                           appSecret:OCMOCK_ANY
                   completionHandler:OCMOCK_ANY]);
  OCMStub([ingestionMock sendAsync:OCMOCK_ANY
                         appSecret:OCMOCK_ANY
                 completionHandler:OCMOCK_ANY]);
  id storageMock = OCMProtocolMock(@protocol(MSStorage));
  OCMStub([storageMock
      loadLogsWithGroupId:kMSTestGroupId
                    limit:batchSizeLimit
           withCompletion:([OCMArg invokeBlockWithArgs:((NSArray<id<MSLog>> *)
                                                            @[ mockLog ]),
                                                       @"1", nil])]);
  MSChannelUnitConfiguration *config =
      [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                 priority:MSPriorityDefault
                                            flushInterval:0.0
                                           batchSizeLimit:batchSizeLimit
                                      pendingBatchesLimit:10];
  self.sut.configuration = config;
  MSChannelUnitDefault *sut = [[MSChannelUnitDefault alloc]
      initWithIngestion:ingestionMock
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
                                 OCMVerifyAll(ingestionMock);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@",
                                           error);
                                 }
                               }];
}

- (void)testDeleteDataOnDisabled {

  // If
  [self initChannelEndJobExpectation];
  int batchSizeLimit = 1;
  id ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));
  id storageMock = OCMProtocolMock(@protocol(MSStorage));
  id mockLog = [self getValidMockLog];
  OCMStub([storageMock
      loadLogsWithGroupId:kMSTestGroupId
                    limit:batchSizeLimit
           withCompletion:([OCMArg invokeBlockWithArgs:((NSArray<id<MSLog>> *)
                                                            @[ mockLog ]),
                                                       @"1", nil])]);
  MSChannelUnitConfiguration *config =
      [[MSChannelUnitConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                 priority:MSPriorityDefault
                                            flushInterval:0.0
                                           batchSizeLimit:batchSizeLimit
                                      pendingBatchesLimit:10];
  MSChannelUnitDefault *sut = [[MSChannelUnitDefault alloc]
      initWithIngestion:ingestionMock
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

                                 // Check that logs as been requested for
                                 // deletion and that there is no batch left.
                                 OCMVerify([storageMock
                                     deleteLogsWithGroupId:kMSTestGroupId]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@",
                                           error);
                                 }
                               }];
}

- (void)testDontSaveLogsWhileDisabledWithDataDeletion {

  // If
  [self initChannelEndJobExpectation];
  id mockLog = [self getValidMockLog];
  OCMReject([self.storageMock saveLog:OCMOCK_ANY withGroupId:OCMOCK_ANY]);
  MSChannelUnitDefault *sut = [self createChannelUnit];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  OCMStub([delegateMock channel:sut
              didCompleteEnqueueingLog:mockLog
                        withInternalId:OCMOCK_ANY])
      .andDo(^(__unused NSInvocation *invocation) {
        [self enqueueChannelEndJobExpectation];
      });
  [sut addDelegate:delegateMock];

  // When
  [sut setEnabled:NO andDeleteDataOnDisabled:YES];
  [sut enqueueItem:mockLog];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 assertThatBool(sut.discardLogs, isTrue());
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@",
                                           error);
                                 }
                               }];
}

- (void)testSaveLogsAfterReEnabled {

  // If
  [self initChannelEndJobExpectation];
  MSChannelUnitDefault *sut = [self createChannelUnit];
  [sut setAppSecret:MS_UUID_STRING];
  [sut setEnabled:NO andDeleteDataOnDisabled:YES];
  id<MSLog> mockLog = [self getValidMockLog];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  OCMStub([delegateMock channel:sut
              didCompleteEnqueueingLog:mockLog
                        withInternalId:OCMOCK_ANY])
      .andDo(^(__unused NSInvocation *invocation) {
        [self enqueueChannelEndJobExpectation];
      });
  [sut addDelegate:delegateMock];

  // When
  [sut setEnabled:YES andDeleteDataOnDisabled:NO];
  [sut enqueueItem:mockLog];

  // Then
  [self
      waitForExpectationsWithTimeout:1
                             handler:^(NSError *error) {
                               assertThatBool(sut.discardLogs, isFalse());
                               OCMVerify([self.storageMock saveLog:mockLog
                                                       withGroupId:OCMOCK_ANY]);
                               if (error) {
                                 XCTFail(@"Expectation Failed with error: %@",
                                         error);
                               }
                             }];

  // If
  [self initChannelEndJobExpectation];
  id<MSLog> otherMockLog = [self getValidMockLog];
  [sut setEnabled:NO andDeleteDataOnDisabled:NO];
  OCMStub([delegateMock channel:sut
              didCompleteEnqueueingLog:otherMockLog
                        withInternalId:OCMOCK_ANY])
      .andDo(^(__unused NSInvocation *invocation) {
        [self enqueueChannelEndJobExpectation];
      });

  // When
  [sut setEnabled:YES andDeleteDataOnDisabled:NO];
  [sut enqueueItem:otherMockLog];

  // Then
  [self
      waitForExpectationsWithTimeout:1
                             handler:^(NSError *error) {
                               assertThatBool(sut.discardLogs, isFalse());
                               OCMVerify([self.storageMock saveLog:mockLog
                                                       withGroupId:OCMOCK_ANY]);
                               if (error) {
                                 XCTFail(@"Expectation Failed with error: %@",
                                         error);
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
                                   XCTFail(@"Expectation Failed with error: %@",
                                           error);
                                 }
                               }];
}

- (void)testResumeOnEnabled {

  // If
  __block BOOL result1, result2;
  [self initChannelEndJobExpectation];
  MSHttpIngestion *ingestion = [MSHttpIngestion new];
  self.sut.ingestion = ingestion;
  [self.sut setEnabled:NO andDeleteDataOnDisabled:NO];
  dispatch_async(self.logsDispatchQueue, ^{
    ingestion.suspended = NO;
  });

  // When
  [self.sut setEnabled:YES andDeleteDataOnDisabled:NO];
  dispatch_async(self.logsDispatchQueue, ^{
    result1 = self.sut.suspended;
  });

  // If
  [self.sut setEnabled:NO andDeleteDataOnDisabled:NO];
  dispatch_async(self.logsDispatchQueue, ^{
    ingestion.suspended = YES;
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
                                   XCTFail(@"Expectation Failed with error: %@",
                                           error);
                                 }
                               }];
}

- (void)testDelegateAfterChannelDisabled {

  // If
  [self initChannelEndJobExpectation];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  id mockLog = [self getValidMockLog];
  MSChannelUnitDefault *sut = [[MSChannelUnitDefault alloc]
      initWithIngestion:self.ingestionMock
                storage:self.storageMock
          configuration:self.configMock
      logsDispatchQueue:dispatch_get_main_queue()];
  [sut setAppSecret:MS_UUID_STRING];

  // When
  [sut addDelegate:delegateMock];
  [sut setEnabled:NO andDeleteDataOnDisabled:YES];

  // Enqueue now that the delegate is set.
  dispatch_async(self.logsDispatchQueue, ^{
    [sut enqueueItem:mockLog];
    [self enqueueChannelEndJobExpectation];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {

                                 // Check the callbacks were invoked for logs.
                                 OCMVerify([delegateMock channel:sut
                                                   didPrepareLog:mockLog
                                                  withInternalId:OCMOCK_ANY]);
                                 OCMVerify([delegateMock channel:sut
                                        didCompleteEnqueueingLog:mockLog
                                                  withInternalId:OCMOCK_ANY]);
                                 OCMVerify([delegateMock channel:sut
                                                     willSendLog:mockLog]);
                                 OCMVerify([delegateMock channel:sut
                                               didFailSendingLog:mockLog
                                                       withError:anything()]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@",
                                           error);
                                 }
                               }];
}

- (void)testDeviceAndTimestampAreAddedOnEnqueuing {

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

- (void)testDeviceAndTimestampAreNotOverwrittenOnEnqueuing {

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
  id storageMock = OCMProtocolMock(@protocol(MSStorage));
  OCMReject([storageMock saveLog:OCMOCK_ANY withGroupId:OCMOCK_ANY]);
  MSChannelUnitDefault *sut =
      [[MSChannelUnitDefault alloc] initWithIngestion:self.ingestionMock
                                              storage:storageMock
                                        configuration:self.configMock
                                    logsDispatchQueue:self.logsDispatchQueue];
  id<MSLog> log = [self getValidMockLog];
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  OCMStub([delegateMock channelUnit:sut shouldFilterLog:log]).andReturn(YES);
  id delegateMock2 = OCMProtocolMock(@protocol(MSChannelDelegate));
  OCMStub([delegateMock2 channelUnit:sut shouldFilterLog:log]).andReturn(NO);
  OCMExpect([delegateMock channel:sut prepareLog:log]);
  OCMExpect([delegateMock2 channel:sut prepareLog:log]);
  OCMExpect(
      [delegateMock channel:sut didPrepareLog:log withInternalId:OCMOCK_ANY]);
  OCMExpect(
      [delegateMock2 channel:sut didPrepareLog:log withInternalId:OCMOCK_ANY]);
  OCMExpect([delegateMock channel:sut
         didCompleteEnqueueingLog:log
                   withInternalId:OCMOCK_ANY]);
  OCMExpect([delegateMock2 channel:sut
          didCompleteEnqueueingLog:log
                    withInternalId:OCMOCK_ANY]);
  [sut addDelegate:delegateMock];
  [sut addDelegate:delegateMock2];

  // When
  dispatch_async(self.logsDispatchQueue, ^{

    // Enqueue now that the delegate is set.
    [sut enqueueItem:log];
    [self enqueueChannelEndJobExpectation];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 OCMVerifyAll(delegateMock);
                                 OCMVerifyAll(delegateMock2);
                                 OCMVerifyAll(storageMock);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@",
                                           error);
                                 }
                               }];
}

- (void)testEnqueuingLogPersistsUnfilteredLogs {

  // If
  [self initChannelEndJobExpectation];
  id<MSLog> log = [self getValidMockLog];
  id storageMock = OCMProtocolMock(@protocol(MSStorage));
  OCMExpect([storageMock saveLog:log withGroupId:self.configMock.groupId]);
  MSChannelUnitDefault *sut =
      [[MSChannelUnitDefault alloc] initWithIngestion:self.ingestionMock
                                              storage:storageMock
                                        configuration:self.configMock
                                    logsDispatchQueue:self.logsDispatchQueue];
  [sut setAppSecret:MS_UUID_STRING];
  OCMStub([sut.storage saveLog:log withGroupId:OCMOCK_ANY]).andReturn(YES);
  id delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  OCMStub([delegateMock channelUnit:sut shouldFilterLog:log]).andReturn(NO);
  OCMExpect(
      [delegateMock channel:sut didPrepareLog:log withInternalId:OCMOCK_ANY]);
  OCMExpect([delegateMock channel:sut
         didCompleteEnqueueingLog:log
                   withInternalId:OCMOCK_ANY]);
  [sut addDelegate:delegateMock];

  // When
  dispatch_async(self.logsDispatchQueue, ^{

    // Enqueue now that the delegate is set.
    [sut enqueueItem:log];
    [self enqueueChannelEndJobExpectation];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 OCMVerifyAll(delegateMock);
                                 OCMVerifyAll(storageMock);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@",
                                           error);
                                 }
                               }];
}

- (void)testDisableAndDeleteDataOnIngestionFatalError {

  // If
  id ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));
  MSChannelUnitDefault *sut = [self createChannelUnit];

  // When
  [sut ingestionDidReceiveFatalError:ingestionMock];

  // Then
  OCMVerify([sut setEnabled:NO andDeleteDataOnDisabled:YES]);
}

- (void)testSuspendOnIngestionSuspended {

  // If
  id ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));
  MSChannelUnitDefault *sut = [self createChannelUnit];

  // When
  [sut ingestionDidSuspend:ingestionMock];

  // Then
  OCMVerify([sut suspend]);
}

- (void)testResumeOnIngestionResumed {

  // If
  id ingestionMock = OCMProtocolMock(@protocol(MSIngestionProtocol));
  MSChannelUnitDefault *sut = [self createChannelUnit];

  // When
  [sut ingestionDidResume:ingestionMock];

  // Then
  OCMVerify([sut resume]);
}

#pragma mark - Helper

- (void)initChannelEndJobExpectation {
  self.channelEndJobExpectation =
      [self expectationWithDescription:@"Channel job should be finished"];
}

- (void)enqueueChannelEndJobExpectation {

  // Enqueue end job expectation on channel's queue to detect when channel
  // finished processing.
  dispatch_async(self.logsDispatchQueue, ^{
    [self.channelEndJobExpectation fulfill];
  });
}

- (id)getValidMockLog {
  id mockLog = OCMPartialMock([MSAbstractLog new]);
  OCMStub([mockLog isValid]).andReturn(YES);
  return mockLog;
}

- (MSChannelUnitDefault *)createChannelUnit {
  return
      [[MSChannelUnitDefault alloc] initWithIngestion:self.ingestionMock
                                              storage:self.storageMock
                                        configuration:self.configMock
                                    logsDispatchQueue:self.logsDispatchQueue];
}

@end
