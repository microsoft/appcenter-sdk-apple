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

@property(nonatomic, strong) dispatch_queue_t logsDispatchQueue;

@property(nonatomic, strong) SNMChannelConfiguration *configMock;

@property(nonatomic, strong) id<SNMStorage> storageMock;

@property(nonatomic, strong) id<SNMSender> senderMock;

/**
 * Most of the channel APIs are asynchronous, this expectation is meant to be enqueued to the data dispatch queue
 * at the end of the test before any asserts. Then it will be triggered on the next queue loop right after the channel
 * finished its job. Wrap asserts within the handler of a waitForExpectationsWithTimeout method.
 */
@property(nonatomic, strong) XCTestExpectation *channelEndJobExpectation;

@end

@implementation SNMChannelDefaultTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];

  _logsDispatchQueue = dispatch_get_main_queue();
  _configMock = OCMClassMock([SNMChannelConfiguration class]);
  _storageMock = OCMProtocolMock(@protocol(SNMStorage));
  _senderMock = OCMProtocolMock(@protocol(SNMSender));
  _sut = [[SNMChannelDefault alloc] initWithSender:_senderMock
                                           storage:_storageMock
                                     configuration:_configMock
                                 logsDispatchQueue:_logsDispatchQueue];
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
  [self queueChannelEndJobExpectation];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 assertThatUnsignedLong(self.sut.itemsCount, equalToInt(itemsToAdd));
                               }];
}

- (void)testQueueFlushedAfterBatchSizeReached {

  // If
  [self initChannelEndJobExpectation];
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
  [self queueChannelEndJobExpectation];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 assertThatUnsignedLong(self.sut.itemsCount, equalToInt(0));
                               }];
}

- (void)testBatchQueueLimit {

  // If
  [self initChannelEndJobExpectation];
  __block id<SNMLog> log;
  __block int currentBatchId = 1;
  __block NSMutableArray<NSString *> *sentBatchIds = [NSMutableArray new];
  int expectedMaxPendingBatched = 2;

  // Set up mock and stubs.
  id senderMock = OCMProtocolMock(@protocol(SNMSender));
  OCMStub([senderMock sendAsync:[OCMArg any] logsDispatchQueue:[OCMArg any] completionHandler:[OCMArg any]])
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
        loadCallback(YES, ((NSArray<SNMLog> *)@[ log ]), [@(currentBatchId++) stringValue]);
      });
  SNMChannelConfiguration *config = [[SNMChannelConfiguration alloc] initWithPriorityName:kSNMTestPriorityName
                                                                            flushInterval:0.0
                                                                           batchSizeLimit:1
                                                                      pendingBatchesLimit:expectedMaxPendingBatched];
  _sut.configuration = config;
  SNMChannelDefault *sut = [[SNMChannelDefault alloc] initWithSender:senderMock
                                                             storage:storageMock
                                                       configuration:config
                                                   logsDispatchQueue:self.logsDispatchQueue];

  // When
  for (int i = 1; i <= expectedMaxPendingBatched + 1; i++) {
    log = [SNMAbstractLog new];
    [sut enqueueItem:log];
  }
  [self queueChannelEndJobExpectation];

  // Then
  [self
      waitForExpectationsWithTimeout:1
                             handler:^(NSError *error) {
                               assertThatUnsignedLong(sut.pendingBatchIds.count, equalToInt(expectedMaxPendingBatched));
                               assertThatUnsignedLong(sentBatchIds.count, equalToInt(expectedMaxPendingBatched));
                               assertThat(sentBatchIds[0], is(@"1"));
                               assertThat(sentBatchIds[1], is(@"2"));
                               assertThatBool(sut.pendingBatchQueueFull, isTrue());
                             }];
}

- (void)testNextBatchSentIfPendingQueueGotRoomAgain {

  /**
   * If
   */
  [self initChannelEndJobExpectation];
  XCTestExpectation *oneLogSentExpectation = [self expectationWithDescription:@"One log sent"];
  __block SNMSendAsyncCompletionHandler senderBlock;
  __block SNMLogContainer *lastBatchLogContainer;
  __block int currentBatchId = 1;
  __block id<SNMLog> log = [SNMAbstractLog new];

  // Init mocks.
  id senderMock = OCMProtocolMock(@protocol(SNMSender));
  OCMStub([senderMock sendAsync:[OCMArg any] logsDispatchQueue:[OCMArg any] completionHandler:[OCMArg any]])
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
                                                   logsDispatchQueue:dispatch_get_main_queue()];

  /**
   * When
   */
  [sut enqueueItem:log];

  // Try to release one batch.
  dispatch_async(self.logsDispatchQueue, ^{
    senderBlock([@(currentBatchId) stringValue], nil, @(200));

    /**
     * Then
     */

    // Batch queue should not be full;
    assertThatBool(sut.pendingBatchQueueFull, isFalse());
    [oneLogSentExpectation fulfill];
  });

  /**
   * When
   */

  // Send another batch.
  currentBatchId++;
  log = [SNMAbstractLog new];
  log.toffset = @(currentBatchId);
  [sut enqueueItem:log];
  [self queueChannelEndJobExpectation];

  /**
   * Then
   */
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {

                                 // Get sure it has been sent.
                                 assertThat(lastBatchLogContainer.batchId, is([@(currentBatchId) stringValue]));
                               }];
}

- (void)testDontForwardLogsToSenderOnDisabled {

  // If
  [self initChannelEndJobExpectation];
  __block id<SNMLog> log = [SNMAbstractLog new];
  id senderMock = OCMProtocolMock(@protocol(SNMSender));
  OCMStub([senderMock sendAsync:[OCMArg any] logsDispatchQueue:[OCMArg any] completionHandler:[OCMArg any]]);
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
                                                   logsDispatchQueue:dispatch_get_main_queue()];
  /**
   * When
   */
  [sut setEnabled:NO andDeleteDataOnDisabled:NO];
  [sut enqueueItem:log];
  [self queueChannelEndJobExpectation];

  /**
   * Then
   */
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {

                                 // Get sure it hasn't been sent.
                                 OCMReject([senderMock sendAsync:[OCMArg any]
                                               logsDispatchQueue:[OCMArg any]
                                               completionHandler:[OCMArg any]]);
                               }];
}

- (void)testDeleteDataOnDisabled {

  // If
  [self initChannelEndJobExpectation];
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
                                                   logsDispatchQueue:dispatch_get_main_queue()];
  // When
  [sut enqueueItem:log];
  [sut setEnabled:NO andDeleteDataOnDisabled:YES];
  [self queueChannelEndJobExpectation];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {

                                 // Check that logs as been requested for deletion and that there is no batch left.
                                 OCMVerify([storageMock deleteLogsForStorageKey:kSNMTestPriorityName]);
                                 assertThatUnsignedLong(sut.pendingBatchIds.count, equalToInt(0));
                               }];
}

#pragma mark - Helper

- (void)initChannelEndJobExpectation {
  _channelEndJobExpectation = [self expectationWithDescription:@"Channel job should be finished"];
}

- (void)queueChannelEndJobExpectation {

  // Enqueue end job expectation on channel's queue to detect when channel finished processing.
  dispatch_async(self.logsDispatchQueue, ^{
    [self.channelEndJobExpectation fulfill];
  });
}

@end
