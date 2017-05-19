#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#else
#import <OCHamcrest/OCHamcrest.h>
#endif
#import <XCTest/XCTest.h>

#import "MSChannelConfiguration.h"

@interface MSChannelConfigurationTests : XCTestCase

@end

@implementation MSChannelConfigurationTests

#pragma mark - Tests

- (void)testNewInstanceWasInitialisedCorrectly {

  // If
  NSString *groupId = @"FooBar";
  MSPriority priority = MSPriorityDefault;
  NSUInteger batchSizeLimit = 10;
  NSUInteger pendingBatchesLimit = 20;
  float flushInterval = 9.9f;

  // When
  MSChannelConfiguration *sut = [[MSChannelConfiguration alloc] initWithGroupId:groupId
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
  assertThatFloat(sut.flushInterval, equalToFloat(flushInterval));
}

- (void)testNewInstanceWithDefaultSettings {

  // If
  NSString *groupId = @"FooBar";

  // When
  MSChannelConfiguration *sut = [[MSChannelConfiguration alloc] initDefaultConfigurationWithGroupId:groupId];

  // Then
  assertThat(sut, notNilValue());
  assertThat(sut.groupId, equalTo(groupId));
  XCTAssertTrue(sut.priority == MSPriorityDefault);
  assertThatUnsignedInteger(sut.batchSizeLimit, equalToUnsignedInteger(50));
  assertThatUnsignedInteger(sut.pendingBatchesLimit, equalToUnsignedInteger(3));
  assertThatFloat(sut.flushInterval, equalToFloat(3));
}

@end
