#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSAbstractLog.h"
#import "MSChannelConfiguration.h"
#import "MSChannelDefault.h"
#import "MSChannelDelegate.h"
#import "MSMobileCenterErrors.h"
#import "MSUtility.h"

static NSString *const kMSTestGroupID = @"GroupID";

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
  MSChannelConfiguration *config = [[MSChannelConfiguration alloc] initWithGroupID:kMSTestGroupID
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
  MSChannelConfiguration *config = [[MSChannelConfiguration alloc] initWithGroupID:kMSTestGroupID
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
  OCMStub([storageMock loadLogsForGroupID:kMSTestGroupID withCompletion:([OCMArg any])])
      .andDo(^(NSInvocation *invocation) {

        MSLoadDataCompletionBlock loadCallback;

        // Mock load.
        [invocation getArgument:&loadCallback atIndex:3];
        loadCallback(YES, ((NSArray<MSLog> *)@[ OCMProtocolMock(@protocol(MSLog)) ]),
                     [@(currentBatchId++) stringValue]);
      });
  MSChannelConfiguration *config = [[MSChannelConfiguration alloc] initWithGroupID:kMSTestGroupID
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
  OCMStub([storageMock loadLogsForGroupID:kMSTestGroupID withCompletion:([OCMArg any])])
      .andDo(^(NSInvocation *invocation) {
        MSLoadDataCompletionBlock loadCallback;

        // Get sender bloc for later call.
        [invocation getArgument:&loadCallback atIndex:3];

        // Mock load.
        loadCallback(YES, ((NSArray<MSLog> *)@[ OCMProtocolMock(@protocol(MSLog)) ]), [@(currentBatchId) stringValue]);
      });

  // Configure channel.
  MSChannelConfiguration *config = [[MSChannelConfiguration alloc] initWithGroupID:kMSTestGroupID
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
      loadLogsForGroupID:kMSTestGroupID
          withCompletion:([OCMArg invokeBlockWithArgs:@YES, ((NSArray<MSLog> *)@[ mockLog ]), @"1", nil])]);
  MSChannelConfiguration *config = [[MSChannelConfiguration alloc] initWithGroupID:kMSTestGroupID
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
      loadLogsForGroupID:kMSTestGroupID
          withCompletion:([OCMArg invokeBlockWithArgs:@YES, ((NSArray<MSLog> *)@[ mockLog ]), @"1", nil])]);
  MSChannelConfiguration *config = [[MSChannelConfiguration alloc] initWithGroupID:kMSTestGroupID
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
                                 OCMVerify([storageMock deleteLogsForGroupID:kMSTestGroupID]);
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

- (void)testDelegateCalledOnNonRecouverableError {

  /**
   * If
   */
  [self initChannelEndJobExpectation];
  NSUInteger expectedHTTPCode = MSHTTPCodesNo404NotFound;
  NSDictionary *userInfo = @{
    NSLocalizedDescriptionKey : kMSMCConnectionHttpErrorDesc,
    kMSMCConnectionHttpCodeErrorKey : @(MSHTTPCodesNo404NotFound)
  };
  NSError *expectedHTTPError =
      [NSError errorWithDomain:kMSMCErrorDomain code:kMSMCConnectionHttpErrorCode userInfo:userInfo];
  NSError *expectedSuspendedError =
      [NSError errorWithDomain:kMSMCErrorDomain
                          code:kMSMCConnectionSuspendedErrorCode
                      userInfo:@{NSLocalizedDescriptionKey : kMSMCConnectionSuspendedErrorDesc}];

  __block MSSendAsyncCompletionHandler senderBlock;
  __block NSMutableArray<MSAbstractLog *> *expectedLogs = [NSMutableArray<MSAbstractLog *> new];
  __block NSMutableArray<MSLog> *failedForwardedLogs = [NSMutableArray<MSLog> new];
  __block NSMutableArray<NSError *> *failedForwardedErrors = [NSMutableArray<NSError *> new];
  __block NSMutableArray<MSLog> *willSendForwardedLogs = [NSMutableArray<MSLog> new];
  id<MSChannelDelegate> delegateMock = OCMProtocolMock(@protocol(MSChannelDelegate));
  for (int i = 0; i < 3; i++) {
    [expectedLogs addObject:[self getValidMockLog]];
  }

  // Stub the sender for that log.
  id senderMock = OCMProtocolMock(@protocol(MSSender));
  OCMStub([senderMock sendAsync:[OCMArg any] completionHandler:[OCMArg any]]).andDo(^(NSInvocation *invocation) {

    // Get sender bloc for later call.
    [invocation retainArguments];
    [invocation getArgument:&senderBlock atIndex:3];
  });

  // Stub the storage load for that log.
  id storageMock = OCMProtocolMock(@protocol(MSStorage));
  OCMStub([storageMock loadLogsForGroupID:kMSTestGroupID withCompletion:([OCMArg any])])
      .andDo(^(NSInvocation *invocation) {
        MSLoadDataCompletionBlock loadCallback;

        // Get sender bloc for later call.
        [invocation getArgument:&loadCallback atIndex:3];

        // Mock load of the first log.
        loadCallback(YES, ((NSArray<MSLog> *)@[ expectedLogs[0] ]), @"0");
      });

  // Stub the storage to return deleted values.
  OCMStub([storageMock deleteLogsForGroupID:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    NSMutableArray<MSLog> *deletedLogs = [expectedLogs mutableCopy];
    [deletedLogs removeObjectAtIndex:0];

    // Return the supposed deleted logs.
    [invocation setReturnValue:&deletedLogs];
    [invocation retainArguments];
  });

  // Configure channel.
  MSChannelConfiguration *config = [[MSChannelConfiguration alloc] initWithGroupID:kMSTestGroupID
                                                                          priority:MSPriorityDefault
                                                                     flushInterval:0.0
                                                                    batchSizeLimit:1
                                                               pendingBatchesLimit:1];
  self.sut = [[MSChannelDefault alloc] initWithSender:senderMock
                                              storage:storageMock
                                        configuration:config
                                    logsDispatchQueue:self.logsDispatchQueue];
  [self.sut addDelegate:delegateMock];

  // Monitor will send callback.
  OCMStub([delegateMock channel:self.sut willSendLog:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    id<MSLog> log;
    [invocation getArgument:&log atIndex:3];
    [willSendForwardedLogs addObject:log];
  });

  // Monitor did fail callback.
  OCMStub([delegateMock channel:self.sut didFailSendingLog:[OCMArg any] withError:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        id<MSLog> log;
        NSError *error;
        [invocation retainArguments];
        [invocation getArgument:&error atIndex:4];
        [invocation getArgument:&log atIndex:3];
        [failedForwardedErrors addObject:error];
        [failedForwardedLogs addObject:log];
      });

  // Stub sender suspended method.
  OCMStub([senderMock setEnabled:NO andDeleteDataOnDisabled:YES])
      .andDo(^(__attribute__((unused)) NSInvocation *invocation) {
        [self.sut sender:senderMock didSetEnabled:(NO) andDeleteDataOnDisabled:YES];
        [self enqueueChannelEndJobExpectation];
      });

  // Enqueue items to the channel.
  for (id<MSLog> log in expectedLogs) {
    log.sid = MS_UUID_STRING;
    [self.sut enqueueItem:log withCompletion:nil];
  }

  /**
   * When
   */

  // Forward a non recoverable error.
  dispatch_async(self.logsDispatchQueue, ^{
    senderBlock([@(0) stringValue], expectedHTTPCode, nil, expectedHTTPError);
  });

  /**
   * Then
   */
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {

                                 // Forwarded logs are equal to expected logs.
                                 assertThatBool([willSendForwardedLogs isEqualToArray:expectedLogs], isTrue());
                                 assertThatBool([failedForwardedLogs isEqualToArray:expectedLogs], isTrue());

                                 // Forwarded errors must match
                                 assertThat(failedForwardedErrors[0], is(expectedHTTPError));
                                 assertThat(failedForwardedErrors[1], is(expectedSuspendedError));
                                 assertThat(failedForwardedErrors[2], is(expectedSuspendedError));
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
