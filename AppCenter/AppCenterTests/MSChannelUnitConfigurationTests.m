// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSChannelUnitConfiguration.h"
#import "MSTestFrameworks.h"

@interface MSChannelUnitConfigurationTests : XCTestCase

@end

@implementation MSChannelUnitConfigurationTests

#pragma mark - Tests

- (void)testNewInstanceWasInitialisedCorrectly {

  // If
  NSString *groupId = @"FooBar";
  MSPriority priority = MSPriorityDefault;
  NSUInteger batchSizeLimit = 10;
  NSUInteger pendingBatchesLimit = 20;
  NSUInteger flushInterval = 9;

  // When
  MSChannelUnitConfiguration *sut = [[MSChannelUnitConfiguration alloc] initWithGroupId:groupId
                                                                               priority:priority
                                                                          flushInterval:flushInterval
                                                                         batchSizeLimit:batchSizeLimit
                                                                    pendingBatchesLimit:pendingBatchesLimit];

  // Then
  assertThat(sut, notNilValue());
  assertThat(sut.groupId, equalTo(groupId));
  XCTAssertTrue(sut.priority == priority);
  assertThatUnsignedInteger(sut.batchSizeLimit, equalToUnsignedInteger(batchSizeLimit));
  assertThatUnsignedInteger(sut.pendingBatchesLimit, equalToUnsignedInteger(pendingBatchesLimit));
  assertThatUnsignedInteger(sut.flushInterval, equalToUnsignedInteger(flushInterval));
}

- (void)testNewInstanceWithDefaultSettings {

  // If
  NSString *groupId = @"FooBar";

  // When
  MSChannelUnitConfiguration *sut = [[MSChannelUnitConfiguration alloc] initDefaultConfigurationWithGroupId:groupId];

  // Then
  assertThat(sut, notNilValue());
  assertThat(sut.groupId, equalTo(groupId));
  XCTAssertTrue(sut.priority == MSPriorityDefault);
  assertThatUnsignedInteger(sut.batchSizeLimit, equalToUnsignedInteger(50));
  assertThatUnsignedInteger(sut.pendingBatchesLimit, equalToUnsignedInteger(3));
  assertThatUnsignedInteger(sut.flushInterval, equalToUnsignedInteger(3));
}

@end
