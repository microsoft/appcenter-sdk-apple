#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <XCTest/XCTest.h>

#import "MSChannelConfiguration.h"

@interface MSChannelConfigurationTests : XCTestCase

@end

@implementation MSChannelConfigurationTests

#pragma mark - Tests

- (void)testNewInstanceWasInitialisedCorrectly {

  // If
  NSString *groupID = @"FooBar";
  NSUInteger batchSizeLimit = 10;
  NSUInteger pendingBatchesLimit = 20;
  float flushInterval = 9.9;

  // When
  MSChannelConfiguration *sut = [[MSChannelConfiguration alloc] initWithGroupID:groupID
                                                                  flushInterval:flushInterval
                                                                 batchSizeLimit:batchSizeLimit
                                                            pendingBatchesLimit:pendingBatchesLimit];

  // Then
  assertThat(sut, notNilValue());
  assertThat(sut.groupID, equalTo(groupID));
  assertThatUnsignedInteger(sut.batchSizeLimit, equalToUnsignedInteger(batchSizeLimit));
  assertThatUnsignedInteger(sut.pendingBatchesLimit, equalToUnsignedInteger(pendingBatchesLimit));
  assertThatFloat(sut.flushInterval, equalToFloat(flushInterval));
}

- (void)testClassWillReturnCorrectConfigurationForGivenDefaultPriority {

  // When
  MSChannelConfiguration *sut = [MSChannelConfiguration configurationForPriority:MSPriorityDefault groupID:@"GroupID"];

  // Then
  assertThat(sut, notNilValue());
  assertThat(sut.groupID, equalTo(@"GroupID"));
  assertThatUnsignedInteger(sut.batchSizeLimit, equalToUnsignedInteger(50));
  assertThatUnsignedInteger(sut.pendingBatchesLimit, equalToUnsignedInteger(3));
  assertThatFloat(sut.flushInterval, equalToFloat(3.0));
}

- (void)testClassWillReturnCorrectConfigurationForGivenHighPriority {

  // When
  MSChannelConfiguration *sut = [MSChannelConfiguration configurationForPriority:MSPriorityHigh groupID:@"GroupID"];

  // Then
  assertThat(sut, notNilValue());
  assertThat(sut.groupID, equalTo(@"GroupID"));
  assertThatUnsignedInteger(sut.batchSizeLimit, equalToUnsignedInteger(10));
  assertThatUnsignedInteger(sut.pendingBatchesLimit, equalToUnsignedInteger(6));
  assertThatFloat(sut.flushInterval, equalToFloat(1.0));
}

- (void)testClassWillReturnCorrectConfigurationForGivenBackgroundPriority {

  // When
  MSChannelConfiguration *sut = [MSChannelConfiguration configurationForPriority:MSPriorityBackground groupID:@"GroupID"];

  // Then
  assertThat(sut, notNilValue());
  assertThat(sut.groupID, equalTo(@"GroupID"));
  assertThatUnsignedInteger(sut.batchSizeLimit, equalToUnsignedInteger(100));
  assertThatUnsignedInteger(sut.pendingBatchesLimit, equalToUnsignedInteger(1));
  assertThatFloat(sut.flushInterval, equalToFloat(60.0));
}

@end
