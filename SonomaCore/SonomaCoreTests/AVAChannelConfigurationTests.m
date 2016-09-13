#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "AVAChannelConfiguration.h"
#import "AVAConstants+Internal.h"

@interface AVAChannelConfigurationTests : XCTestCase

@end

@implementation AVAChannelConfigurationTests

#pragma mark - Tests

- (void)testNewInstanceWasInitialisedCorrectly {

  // If
  NSString *name = @"FooBar";
  NSUInteger batchSizeLimit = 10;
  NSUInteger pendingBatchesLimit = 20;
  float flushInterval = 9.9;

  // When
  AVAChannelConfiguration *sut = [[AVAChannelConfiguration alloc] initWithPriorityName:name
                                                                         flushInterval:flushInterval
                                                                        batchSizeLimit:batchSizeLimit
                                                                   pendingBatchesLimit:pendingBatchesLimit];

  // Then
  assertThat(sut, notNilValue());
  assertThat(sut.name, equalTo(name));
  assertThatUnsignedInteger(sut.batchSizeLimit, equalToUnsignedInteger(batchSizeLimit));
  assertThatUnsignedInteger(sut.pendingBatchesLimit, equalToUnsignedInteger(pendingBatchesLimit));
  assertThatFloat(sut.flushInterval, equalToFloat(flushInterval));
}

- (void)testClassWillReturnCorrectConfigurationForGivenDefaultPriority {

  // When
  AVAChannelConfiguration *sut = [AVAChannelConfiguration configurationForPriority:AVAPriorityDefault];

  // Then
  assertThat(sut, notNilValue());
  assertThat(sut.name, equalTo(@"AVAPriorityDefault"));
  assertThatUnsignedInteger(sut.batchSizeLimit, equalToUnsignedInteger(50));
  assertThatUnsignedInteger(sut.pendingBatchesLimit, equalToUnsignedInteger(3));
  assertThatFloat(sut.flushInterval, equalToFloat(30.0));
}

- (void)testClassWillReturnCorrectConfigurationForGivenHighPriority {

  // When
  AVAChannelConfiguration *sut = [AVAChannelConfiguration configurationForPriority:AVAPriorityHigh];

  // Then
  assertThat(sut, notNilValue());
  assertThat(sut.name, equalTo(@"AVAPriorityHigh"));
  assertThatUnsignedInteger(sut.batchSizeLimit, equalToUnsignedInteger(1));
  assertThatUnsignedInteger(sut.pendingBatchesLimit, equalToUnsignedInteger(6));
  assertThatFloat(sut.flushInterval, equalToFloat(3.0));
}

- (void)testClassWillReturnCorrectConfigurationForGivenBackgroundPriority {

  // When
  AVAChannelConfiguration *sut = [AVAChannelConfiguration configurationForPriority:AVAPriorityBackground];

  // Then
  assertThat(sut, notNilValue());
  assertThat(sut.name, equalTo(@"AVAPriorityBackground"));
  assertThatUnsignedInteger(sut.batchSizeLimit, equalToUnsignedInteger(100));
  assertThatUnsignedInteger(sut.pendingBatchesLimit, equalToUnsignedInteger(1));
  assertThatFloat(sut.flushInterval, equalToFloat(60.0));
}

- (void)testRequestingSamePredefinedConfigurationMultipleTimesReturnsSameObject {

  // If
  NSArray *priorities = @[ @(AVAPriorityHigh), @(AVAPriorityDefault), @(AVAPriorityBackground) ];

  for (NSNumber *priority in priorities) {
    AVAPriority prio = priority.integerValue;

    // When
    AVAChannelConfiguration *sut1 = [AVAChannelConfiguration configurationForPriority:prio];
    AVAChannelConfiguration *sut2 = [AVAChannelConfiguration configurationForPriority:prio];

    // Then
    assertThat(sut2, equalTo(sut1));
  }
}

@end
