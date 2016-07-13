#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>

#import "AVAChannelDefault.h"
#import "AVAAbstractLog.h"

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
  // Put teardown code here. This method is called after the invocation of each test method in the class.
  [super tearDown];
}

#pragma mark - Tests

- (void)testNewInstanceWasInitialisedCorrectly {
  assertThat(_sut, notNilValue());
  assertThat(_sut.dataItemsOperations, notNilValue());
  assertThatUnsignedLong(self.sut.itemsCount, equalToInt(0));
}

- (void)testEnqueuingItemsWillIncreaseCounter {
  
  // If
  self.sut.flushInterval = 0.0;
  self.sut.batchSize = 10;
  int itemsToAdd = 3;
  XCTestExpectation *expectation = [self expectationWithDescription:@"All items enqueued"];
  
  // When
  for(int i=1; i<=itemsToAdd; i++) {
    
    [self.sut enqueueItem:[AVAAbstractLog new] withCompletion:^(BOOL success) {
      if (i == itemsToAdd) {
        [expectation fulfill];
      }
    }];
  }
  
  // Then
  [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
    assertThatUnsignedLong(self.sut.itemsCount, equalToInt(itemsToAdd));
  }];
}

- (void)testQueueFlushedAfterBatchSizeReached {
  
  // If
  self.sut.flushInterval = 0.0;
  self.sut.batchSize = 3;
  int itemsToAdd = 3;
  XCTestExpectation *expectation = [self expectationWithDescription:@"All items enqueued"];
  
  // When
  for(int i=1; i<=itemsToAdd; i++) {
    
    [self.sut enqueueItem:[AVAAbstractLog new] withCompletion:^(BOOL success) {
      if (i == itemsToAdd) {
        [expectation fulfill];
      }
    }];
  }
  
  // Then
  [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
    assertThatUnsignedLong(self.sut.itemsCount, equalToInt(0));
  }];
}

- (void)testQueueFlushedAfterTimerFinished {
  
  // If
  self.sut.flushInterval = 2.5;
  self.sut.batchSize = 10;
  int itemsToAdd = 3;
    XCTestExpectation *expectation = [self expectationWithDescription:@"First item enqueued"];
  
  // When
  for(int i=1; i<=itemsToAdd; i++) {
    [self.sut enqueueItem:[AVAAbstractLog new] withCompletion:^(BOOL success) {
      if (i == itemsToAdd) {
        
        // Wait for peiod of flush interval before returning expectation
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.sut.flushInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
          [expectation fulfill];
        });
        
      }
    }];
  }
  
  // Then
  [self waitForExpectationsWithTimeout:3 handler:^(NSError *error) {
    assertThatUnsignedLong(self.sut.itemsCount, equalToInt(0));
  }];
}

@end
