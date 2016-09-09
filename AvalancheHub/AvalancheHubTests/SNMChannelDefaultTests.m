#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "SNMAbstractLog.h"
#import "SNMChannelConfiguration.h"
#import "SNMChannelDefault.h"
#import "SNMSender.h"
#import "SNMStorage.h"

@interface SNMChannelDefaultTests : XCTestCase

@property(nonatomic, strong) SNMChannelDefault *sut;

@end

@implementation SNMChannelDefaultTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];

  // TODO: Use mocks once protocols are SNMilable
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
  SNMChannelConfiguration *config = [[SNMChannelConfiguration alloc] initWithPriorityName:@"Prio"
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
  SNMChannelConfiguration *config = [[SNMChannelConfiguration alloc] initWithPriorityName:@"Prio"
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

- (void)testQueueFlushedAfterTimerFinished {

  // If
  SNMChannelConfiguration *config = [[SNMChannelConfiguration alloc] initWithPriorityName:@"Prio"
                                                                            flushInterval:2.5
                                                                           batchSizeLimit:10
                                                                      pendingBatchesLimit:3];
  _sut.configuration = config;
  int itemsToAdd = 3;
  XCTestExpectation *expectation = [self expectationWithDescription:@"First item enqueued"];

  // When
  for (int i = 1; i <= itemsToAdd; i++) {
    [self.sut enqueueItem:[SNMAbstractLog new]
           withCompletion:^(BOOL success) {
             if (i == itemsToAdd) {

               // Wait for peiod of flush interval before returning expectation
               dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(config.flushInterval * NSEC_PER_SEC)),
                              dispatch_get_main_queue(), ^{
                                [expectation fulfill];
                              });
             }
           }];
  }

  // Then
  [self waitForExpectationsWithTimeout:3
                               handler:^(NSError *error) {
                                 assertThatUnsignedLong(self.sut.itemsCount, equalToInt(0));
                               }];
}

@end
