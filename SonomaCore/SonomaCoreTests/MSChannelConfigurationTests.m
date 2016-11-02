#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSChannelConfiguration.h"
#import "MSConstants+Internal.h"

@interface MSChannelConfigurationTests : XCTestCase

@end

@implementation MSChannelConfigurationTests

#pragma mark - Tests

- (void)testNewInstanceWasInitialisedCorrectly {

  // If
  NSString *name = @"FooBar";
  NSUInteger batchSizeLimit = 10;
  NSUInteger pendingBatchesLimit = 20;
  float flushInterval = 9.9;

  // When
  MSChannelConfiguration *sut = [[MSChannelConfiguration alloc] initWithPriorityName:name
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
  MSChannelConfiguration *sut = [MSChannelConfiguration configurationForPriority:SNMPriorityDefault];

  // Then
  assertThat(sut, notNilValue());
  assertThat(sut.name, equalTo(@"SNMPriorityDefault"));
  assertThatUnsignedInteger(sut.batchSizeLimit, equalToUnsignedInteger(50));
  assertThatUnsignedInteger(sut.pendingBatchesLimit, equalToUnsignedInteger(3));
  assertThatFloat(sut.flushInterval, equalToFloat(3.0));
}

- (void)testClassWillReturnCorrectConfigurationForGivenHighPriority {

  // When
  MSChannelConfiguration *sut = [MSChannelConfiguration configurationForPriority:SNMPriorityHigh];

  // Then
  assertThat(sut, notNilValue());
  assertThat(sut.name, equalTo(@"SNMPriorityHigh"));
  assertThatUnsignedInteger(sut.batchSizeLimit, equalToUnsignedInteger(1));
  assertThatUnsignedInteger(sut.pendingBatchesLimit, equalToUnsignedInteger(6));
  assertThatFloat(sut.flushInterval, equalToFloat(3.0));
}

- (void)testClassWillReturnCorrectConfigurationForGivenBackgroundPriority {

  // When
  MSChannelConfiguration *sut = [MSChannelConfiguration configurationForPriority:SNMPriorityBackground];

  // Then
  assertThat(sut, notNilValue());
  assertThat(sut.name, equalTo(@"SNMPriorityBackground"));
  assertThatUnsignedInteger(sut.batchSizeLimit, equalToUnsignedInteger(100));
  assertThatUnsignedInteger(sut.pendingBatchesLimit, equalToUnsignedInteger(1));
  assertThatFloat(sut.flushInterval, equalToFloat(60.0));
}

- (void)testRequestingSamePredefinedConfigurationMultipleTimesReturnsSameObject {

  // If
  NSArray *priorities = @[ @(SNMPriorityHigh), @(SNMPriorityDefault), @(SNMPriorityBackground) ];

  for (NSNumber *priority in priorities) {
    SNMPriority prio = priority.integerValue;

    // When
    MSChannelConfiguration *sut1 = [MSChannelConfiguration configurationForPriority:prio];
    MSChannelConfiguration *sut2 = [MSChannelConfiguration configurationForPriority:prio];

    // Then
    assertThat(sut2, equalTo(sut1));
  }
}

@end
