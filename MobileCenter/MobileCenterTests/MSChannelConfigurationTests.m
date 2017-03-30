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
  MSPriority priority = MSPriorityDefault;
  NSUInteger batchSizeLimit = 10;
  NSUInteger pendingBatchesLimit = 20;
  float flushInterval = 9.9;

  // When
  MSChannelConfiguration *sut = [[MSChannelConfiguration alloc] initWithGroupID:groupID
                                                                       priority:priority
                                                                  flushInterval:flushInterval
                                                                 batchSizeLimit:batchSizeLimit
                                                            pendingBatchesLimit:pendingBatchesLimit];

  // Then
  assertThat(sut, notNilValue());
  assertThat(sut.groupID, equalTo(groupID));
  XCTAssertTrue(sut.priority == priority);
  assertThatUnsignedInteger(sut.batchSizeLimit, equalToUnsignedInteger(batchSizeLimit));
  assertThatUnsignedInteger(sut.pendingBatchesLimit, equalToUnsignedInteger(pendingBatchesLimit));
  assertThatFloat(sut.flushInterval, equalToFloat(flushInterval));
}

@end
