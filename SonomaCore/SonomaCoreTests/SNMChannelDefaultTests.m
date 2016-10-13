#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "SNMAbstractLog.h"
#import "SNMChannelConfiguration.h"
#import "SNMChannelDefault.h"
#import "SNMLog.h"
#import "SNMSender.h"
#import "SNMStorage.h"

static NSString *const kSNMTestPriorityName = @"Prio";

@interface SNMChannelDefaultTests : XCTestCase

@property(nonatomic, strong) SNMChannelDefault *sut;

@end

@implementation SNMChannelDefaultTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];

  // TODO: Use mocks once protocols are available
  _sut = [SNMChannelDefault new];
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each
  // test method in the class.
  [super tearDown];
}

#pragma mark - Tests

- (void)testNewInstanceWasInitialisedCorrectly {
  id configMock = OCMClassMock([SNMChannelConfiguration class]);
  id storageMock = OCMProtocolMock(@protocol(SNMStorage));
  id senderMock = OCMProtocolMock(@protocol(SNMSender));

  SNMChannelDefault *sut = [[SNMChannelDefault alloc] initWithSender:senderMock
                                                             storage:storageMock
                                                       configuration:configMock
                                                       callbackQueue:dispatch_get_main_queue()];

  assertThat(sut, notNilValue());
  assertThat(sut.configuration, equalTo(configMock));
  assertThat(sut.sender, equalTo(senderMock));
  assertThat(sut.storage, equalTo(storageMock));
  assertThatUnsignedLong(sut.itemsCount, equalToInt(0));
}

- (void)testEnqueuingItemsWillIncreaseCounter {

  // If
  SNMChannelConfiguration *config = [[SNMChannelConfiguration alloc] initWithPriorityName:kSNMTestPriorityName
                                                                            flushInterval:5
                                                                           batchSizeLimit:10
                                                                      pendingBatchesLimit:3];
  self.sut.configuration = config;
  int itemsToAdd = 3;

  // When
  for (int i = 1; i <= itemsToAdd; i++) {

    [self.sut enqueueItem:[SNMAbstractLog new]];
  }

  // Then
  assertThatUnsignedLong(self.sut.itemsCount, equalToInt(itemsToAdd));
}

- (void)testQueueFlushedAfterBatchSizeReached {

  // If
  SNMChannelConfiguration *config = [[SNMChannelConfiguration alloc] initWithPriorityName:kSNMTestPriorityName
                                                                            flushInterval:0.0
                                                                           batchSizeLimit:3
                                                                      pendingBatchesLimit:3];
  _sut.configuration = config;
  int itemsToAdd = 3;
  XCTestExpectation *expectation = [self expectationWithDescription:@"All items enqueued"];

  // When
  for (int i = 1; i <= itemsToAdd; i++) {

    [self.sut enqueueItem:[SNMAbstractLog new]
           withCompletion:^(BOOL success) {
             if (i == itemsToAdd) {
               [expectation fulfill];
             }
           }];
  }

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 assertThatUnsignedLong(self.sut.itemsCount, equalToInt(0));
                               }];
}

- (void)testBatchQueueLimit {

  // If
  __block id<SNMLog> log;
  __block int currentBatchId;
  __block NSMutableArray<NSString *> *sentBatchIds = [NSMutableArray new];
  int expectedMaxPendingBatched = 2;

  // Set up mock and stubs.
  id senderMock = OCMProtocolMock(@protocol(SNMSender));
  OCMStub([senderMock sendAsync:[OCMArg any] callbackQueue:[OCMArg any] completionHandler:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        SNMLogContainer *container;
        [invocation getArgument:&container atIndex:2];
        if (container) {
          [sentBatchIds addObject:container.batchId];
        }
      });
  id storageMock = OCMProtocolMock(@protocol(SNMStorage));
  OCMStub([storageMock loadLogsForStorageKey:kSNMTestPriorityName withCompletion:([OCMArg any])])
      .andDo(^(NSInvocation *invocation) {

        SNMLoadDataCompletionBlock loadCallback;

        // Mock load.
        [invocation getArgument:&loadCallback atIndex:3];
        loadCallback(YES, ((NSArray<SNMLog> *)@[ log ]), [@(currentBatchId) stringValue]);
      });
  SNMChannelConfiguration *config = [[SNMChannelConfiguration alloc] initWithPriorityName:kSNMTestPriorityName
                                                                            flushInterval:0.0
                                                                           batchSizeLimit:1
                                                                      pendingBatchesLimit:expectedMaxPendingBatched];
  _sut.configuration = config;
  SNMChannelDefault *sut = [[SNMChannelDefault alloc] initWithSender:senderMock
                                                             storage:storageMock
                                                       configuration:config
                                                       callbackQueue:dispatch_get_main_queue()];

  // When
  for (int i = 1; i <= expectedMaxPendingBatched + 1; i++) {
    currentBatchId = i;
    log = [SNMAbstractLog new];
    [sut enqueueItem:log];
  }

  // Then
  assertThatUnsignedLong(sut.pendingBatchIds.count, equalToInt(expectedMaxPendingBatched));
  assertThatUnsignedLong(sentBatchIds.count, equalToInt(expectedMaxPendingBatched));
  assertThat(sentBatchIds[0], is(@"1"));
  assertThat(sentBatchIds[1], is(@"2"));
  assertThatBool(sut.pendingBatchQueueFull, isTrue());
}

- (void)testNextBatchSentIfPendingQueueGotRoomAgain {

  /**
   * If
   */
  __block SNMSendAsyncCompletionHandler senderBlock;
  __block SNMLogContainer *lastBatchLogContainer;
  __block int currentBatchId = 1;
  __block id<SNMLog> log = [SNMAbstractLog new];

  // Init mocks.
  id senderMock = OCMProtocolMock(@protocol(SNMSender));
  OCMStub([senderMock sendAsync:[OCMArg any] callbackQueue:[OCMArg any] completionHandler:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {

        // Get sender bloc for later call.
        [invocation retainArguments];
        [invocation getArgument:&senderBlock atIndex:4];
        [invocation getArgument:&lastBatchLogContainer atIndex:2];
      });

  // Stub the storage load for that log.
  id storageMock = OCMProtocolMock(@protocol(SNMStorage));
  OCMStub([storageMock loadLogsForStorageKey:kSNMTestPriorityName withCompletion:([OCMArg any])])
      .andDo(^(NSInvocation *invocation) {

        SNMLoadDataCompletionBlock loadCallback;

        // Get sender bloc for later call.
        [invocation getArgument:&loadCallback atIndex:3];

        // Mock load.
        loadCallback(YES, ((NSArray<SNMLog> *)@[ log ]), [@(currentBatchId) stringValue]);
      });

  // Send one batch to fulfill the queue.
  log.toffset = @(currentBatchId);

  // Configure channel.
  SNMChannelConfiguration *config = [[SNMChannelConfiguration alloc] initWithPriorityName:kSNMTestPriorityName
                                                                            flushInterval:0.0
                                                                           batchSizeLimit:1
                                                                      pendingBatchesLimit:1];
  _sut.configuration = config;
  SNMChannelDefault *sut = [[SNMChannelDefault alloc] initWithSender:senderMock
                                                             storage:storageMock
                                                       configuration:config
                                                       callbackQueue:dispatch_get_main_queue()];

  /**
   * When
   */
  [sut enqueueItem:log];

  // Try to release one batch.
  senderBlock([@(currentBatchId) stringValue], nil, @(200));

  /**
   * Then
   */

  // Batch queue should not be full;
  assertThatBool(sut.pendingBatchQueueFull, isFalse());

  /**
   * When
   */

  // Send another batch.
  currentBatchId++;
  log = [SNMAbstractLog new];
  log.toffset = @(currentBatchId);
  [sut enqueueItem:log];

  /**
   * Then
   */

  // Get sure it has been sent.
  assertThat(lastBatchLogContainer.batchId, is([@(currentBatchId) stringValue]));
}

- (void)testDontForwardLogsToSenderOnDisabled {

  // If
  __block BOOL logForwarded;
  __block id<SNMLog> log = [SNMAbstractLog new];
  id senderMock = OCMProtocolMock(@protocol(SNMSender));
  OCMStub([senderMock sendAsync:[OCMArg any] callbackQueue:[OCMArg any] completionHandler:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        logForwarded = YES;
      });
  id storageMock = OCMProtocolMock(@protocol(SNMStorage));
  OCMStub([storageMock
      loadLogsForStorageKey:kSNMTestPriorityName
             withCompletion:([OCMArg invokeBlockWithArgs:@YES, ((NSArray<SNMLog> *)@[ log ]), @"1", nil])]);
  SNMChannelConfiguration *config = [[SNMChannelConfiguration alloc] initWithPriorityName:kSNMTestPriorityName
                                                                            flushInterval:0.0
                                                                           batchSizeLimit:1
                                                                      pendingBatchesLimit:10];
  _sut.configuration = config;
  SNMChannelDefault *sut = [[SNMChannelDefault alloc] initWithSender:senderMock
                                                             storage:storageMock
                                                       configuration:config
                                                       callbackQueue:dispatch_get_main_queue()];
  /**
   * When
   */
  [sut setEnabled:NO andDeleteDataOnDisabled:NO];
  [sut enqueueItem:log];

  /**
   * Then
   */
  assertThatBool(logForwarded, isFalse());
}

- (void)testDeleteDataOnDisabled {

  // If
  id senderMock = OCMProtocolMock(@protocol(SNMSender));
  id storageMock = OCMProtocolMock(@protocol(SNMStorage));
  id<SNMLog> log = [SNMAbstractLog new];
  OCMStub([storageMock
      loadLogsForStorageKey:kSNMTestPriorityName
             withCompletion:([OCMArg invokeBlockWithArgs:@YES, ((NSArray<SNMLog> *)@[ log ]), @"1", nil])]);
  SNMChannelConfiguration *config = [[SNMChannelConfiguration alloc] initWithPriorityName:kSNMTestPriorityName
                                                                            flushInterval:0.0
                                                                           batchSizeLimit:1
                                                                      pendingBatchesLimit:10];
  _sut.configuration = config;
  SNMChannelDefault *sut = [[SNMChannelDefault alloc] initWithSender:senderMock
                                                             storage:storageMock
                                                       configuration:config
                                                       callbackQueue:dispatch_get_main_queue()];
  // When
  [sut enqueueItem:log];
  [sut setEnabled:NO andDeleteDataOnDisabled:YES];

  // Then
  OCMVerify([storageMock deleteLogsForStorageKey:kSNMTestPriorityName]);
  assertThatUnsignedLong(sut.pendingBatchIds.count, equalToInt(0));
}

@end
