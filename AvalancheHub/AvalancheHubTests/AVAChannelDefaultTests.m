#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "AVAAbstractLog.h"
#import "AVAChannelConfiguration.h"
#import "AVAChannelDefault.h"
#import "AVASender.h"
#import "AVAStorage.h"

@interface AVAChannelDefaultTests : XCTestCase

@property(nonatomic, strong) AVAChannelDefault *sut;

@end

@implementation AVAChannelDefaultTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];

  // TODO: Use mocks once protocols are available
  _sut = [AVAChannelDefault new];
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each
  // test method in the class.
  [super tearDown];
}

#pragma mark - Tests

- (void)testNewInstanceWasInitialisedCorrectly {
  id configMock = OCMClassMock([AVAChannelConfiguration class]);
  id storageMock = OCMProtocolMock(@protocol(AVAStorage));
  id senderMock = OCMProtocolMock(@protocol(AVASender));
  AVAChannelDefault *sut = [[AVAChannelDefault alloc] initWithSender:senderMock
                                                             storage:storageMock
                                                       configuration:configMock
                                                       callbackQueue:nil];

  assertThat(sut, notNilValue());
  assertThat(sut.configuration, equalTo(configMock));
  assertThat(sut.sender, equalTo(senderMock));
  assertThat(sut.storage, equalTo(storageMock));
  assertThatUnsignedLong(sut.itemsCount, equalToInt(0));
}

- (void)testEnqueuingItemsWillIncreaseCounter {

  // If
  AVAChannelConfiguration *config =
      [[AVAChannelConfiguration alloc] initWithPriorityName:@"Prio"
                                              flushInterval:0.0
                                             batchSizeLimit:10
                                        pendingBatchesLimit:3];
  self.sut.configuration = config;
  int itemsToAdd = 3;

  // When
  for (int i = 1; i <= itemsToAdd; i++) {

    [self.sut enqueueItem:[AVAAbstractLog new]];
  }

  // Then
  assertThatUnsignedLong(self.sut.itemsCount, equalToInt(itemsToAdd));
}

- (void)testQueueFlushedAfterBatchSizeReached {

  // If
  AVAChannelConfiguration *config =
      [[AVAChannelConfiguration alloc] initWithPriorityName:@"Prio"
                                              flushInterval:0.0
                                             batchSizeLimit:3
                                        pendingBatchesLimit:3];
  _sut.configuration = config;
  int itemsToAdd = 3;
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"All items enqueued"];

  // When
  for (int i = 1; i <= itemsToAdd; i++) {

    [self.sut enqueueItem:[AVAAbstractLog new]
           withCompletion:^(BOOL success) {
             if (i == itemsToAdd) {
               [expectation fulfill];
             }
           }];
  }

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 assertThatUnsignedLong(self.sut.itemsCount,
                                                        equalToInt(0));
                               }];
}

- (void)testQueueFlushedAfterTimerFinished {

  // If
  AVAChannelConfiguration *config =
      [[AVAChannelConfiguration alloc] initWithPriorityName:@"Prio"
                                              flushInterval:2.5
                                             batchSizeLimit:10
                                        pendingBatchesLimit:3];
  _sut.configuration = config;
  int itemsToAdd = 3;
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"First item enqueued"];

  // When
  for (int i = 1; i <= itemsToAdd; i++) {
    [self.sut enqueueItem:[AVAAbstractLog new]
           withCompletion:^(BOOL success) {
             if (i == itemsToAdd) {

               // Wait for peiod of flush interval before returning expectation
               dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                            (int64_t)(config.flushInterval *
                                                      NSEC_PER_SEC)),
                              dispatch_get_main_queue(), ^{
                                [expectation fulfill];
                              });
             }
           }];
  }

  // Then
  [self waitForExpectationsWithTimeout:3
                               handler:^(NSError *error) {
                                 assertThatUnsignedLong(self.sut.itemsCount,
                                                        equalToInt(0));
                               }];
}

@end
