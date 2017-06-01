#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#else
#import <OCHamcrest/OCHamcrest.h>
#endif
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSAbstractLogInternal.h"
#import "MSChannelConfiguration.h"
#import "MSChannelDefault.h"
#import "MSChannelDefaultPrivate.h"
#import "MSChannelDelegate.h"
#import "MSHttpSender.h"
#import "MSMobileCenterErrors.h"
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
  __block int currentBatchId = 1;
  __block NSMutableArray<NSString *> *sentBatchIds = [NSMutableArray new];
  NSUInteger expectedMaxPendingBatched = 2;

  // Set up mock and stubs.
  id senderMock = OCMProtocolMock(@protocol(MSSender));
  OCMStub([senderMock sendAsync:[OCMArg any] completionHandler:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    MSLogContainer *container;
    [invocation getArgument:&container atIndex:2];
    if (container) {
      [sentBatchIds addObject:container.batchId];
    }
  });
  id storageMock = OCMProtocolMock(@protocol(MSStorage));
  OCMStub([storageMock loadLogsForGroupId:kMSTestGroupId withCompletion:([OCMArg any])])
      .andDo(^(NSInvocation *invocation) {

        MSLoadDataCompletionBlock loadCallback;

        // Mock load.
        [invocation getArgument:&loadCallback atIndex:3];
        loadCallback(YES, ((NSArray<MSLog> *)@[ OCMProtocolMock(@protocol(MSLog)) ]),
                     [@(currentBatchId++) stringValue]);
      });
  MSChannelConfiguration *config = [[MSChannelConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                          priority:MSPriorityDefault
                                                                     flushInterval:0.0
                                                                    batchSizeLimit:1
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
  [self waitForExpectationsWithTimeout:1
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

  /**
   * If
   */
  [self initChannelEndJobExpectation];
  XCTestExpectation *oneLogSentExpectation = [self expectationWithDescription:@"One log sent"];
  __block MSSendAsyncCompletionHandler senderBlock;
  __block MSLogContainer *lastBatchLogContainer;
  __block int currentBatchId = 1;

  // Init mocks.
  id senderMock = OCMProtocolMock(@protocol(MSSender));
  OCMStub([senderMock sendAsync:[OCMArg any] completionHandler:[OCMArg any]]).andDo(^(NSInvocation *invocation) {

    // Get sender bloc for later call.
    [invocation retainArguments];
    [invocation getArgument:&senderBlock atIndex:3];
    [invocation getArgument:&lastBatchLogContainer atIndex:2];
  });

  // Stub the storage load for that log.
  id storageMock = OCMProtocolMock(@protocol(MSStorage));
  OCMStub([storageMock loadLogsForGroupId:kMSTestGroupId withCompletion:([OCMArg any])])
      .andDo(^(NSInvocation *invocation) {
        MSLoadDataCompletionBlock loadCallback;

        // Get sender bloc for later call.
        [invocation getArgument:&loadCallback atIndex:3];

        // Mock load.
        loadCallback(YES, ((NSArray<MSLog> *)@[ OCMProtocolMock(@protocol(MSLog)) ]), [@(currentBatchId) stringValue]);
      });

  // Configure channel.
  MSChannelConfiguration *config = [[MSChannelConfiguration alloc] initWithGroupId:kMSTestGroupId
                                                                          priority:MSPriorityDefault
                                                                     flushInterval:0.0
                                                                    batchSizeLimit:1
                                                               pendingBatchesLimit:1];
  self.sut.configuration = config;
  MSChannelDefault *sut = [[MSChannelDefault alloc] initWithSender:senderMock
                                                           storage:storageMock
                                                     configuration:config
                                                 logsDispatchQueue:dispatch_get_main_queue()];

  /**
   * When
   */
  [sut enqueueItem:[self getValidMockLog] withCompletion:nil];

  // Try to release one batch.
  dispatch_async(self.logsDispatchQueue, ^{
    senderBlock([@(1) stringValue], 200, nil, nil);

    /**
     * Then
     */
    dispatch_async(self.logsDispatchQueue, ^{

      // Batch queue should not be full;
      assertThatBool(sut.pendingBatchQueueFull, isFalse());
      [oneLogSentExpectation fulfill];

      /**
       * When
       */

      // Send another batch.
      currentBatchId++;
      [sut enqueueItem:[self getValidMockLog] withCompletion:nil];
      [self enqueueChannelEndJobExpectation];
    });
  });

  /**
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
  id mockLog = [self getValidMockLog];
  id senderMock = OCMProtocolMock(@protocol(MSSender));
  OCMStub([senderMock sendAsync:[OCMArg any] completionHandler:[OCMArg any]]);
  id storageMock = OCMProtocolMock(@protocol(MSStorage));
  OCMStub([storageMock
      loadLogsForGroupId:kMSTestGroupId
          withCompletion:([OCMArg invokeBlockWithArgs:@YES, ((NSArray<MSLog> *)@[ mockLog ]), @"1", nil])]);
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
  /**
   * When
   */
  [sut setEnabled:NO andDeleteDataOnDisabled:NO];
  [sut enqueueItem:mockLog withCompletion:nil];
  [self enqueueChannelEndJobExpectation];

  /**
   * Then
   */
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {

                                 // Get sure it hasn't been sent.
                                 OCMReject([senderMock sendAsync:[OCMArg any] completionHandler:[OCMArg any]]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testDeleteDataOnDisabled {

  // If
  [self initChannelEndJobExpectation];
  id senderMock = OCMProtocolMock(@protocol(MSSender));
  id storageMock = OCMProtocolMock(@protocol(MSStorage));
  id mockLog = [self getValidMockLog];
  OCMStub([storageMock
      loadLogsForGroupId:kMSTestGroupId
          withCompletion:([OCMArg invokeBlockWithArgs:@YES, ((NSArray<MSLog> *)@[ mockLog ]), @"1", nil])]);
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
  [sut setEnabled:NO andDeleteDataOnDisabled:YES];
  [self enqueueChannelEndJobExpectation];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {

                                 // Check that logs as been requested for deletion and that there is no batch left.
                                 OCMVerify([storageMock deleteLogsForGroupId:kMSTestGroupId]);
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
           loadLogsForGroupId:kMSTestGroupId
           withCompletion:([OCMArg invokeBlockWithArgs:@YES, ((NSArray<MSLog> *)@[ mockLog ]), @"1", nil])]);
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
                                 OCMVerify([storageMock deleteLogsForGroupId:kMSTestGroupId]);
                                 assertThatBool(sut.enabled, isFalse());
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testSuspendOnDisabled{
  
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

- (void)testResumeOnEnabled{
  
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


- (void)testSuspendOnSenderSuspended{
  
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

- (void)testSuspendOnSenderResumed{
  
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
