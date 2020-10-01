// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACAbstractLog.h"
#import "MSACDistributeInfoTracker.h"
#import "MSACTestFrameworks.h"

@interface MSACDistributeInfoTrackerTests : XCTestCase

@property(nonatomic) MSACDistributeInfoTracker *sut;

@end

@implementation MSACDistributeInfoTrackerTests

- (void)setUp {
  [super setUp];
  self.sut = [[MSACDistributeInfoTracker alloc] init];
}

- (void)testAddDistributionGroupIdToLogs {

  // If
  NSString *expectedDistributionGroupId = @"GROUP-ID";
  MSACAbstractLog *log = [MSACAbstractLog new];

  // When
  [self.sut updateDistributionGroupId:expectedDistributionGroupId];
  [self.sut channel:nil prepareLog:log];

  // Then
  XCTAssertEqual(log.distributionGroupId, expectedDistributionGroupId);
}

- (void)testSetNewDistributionGroupId {

  // If
  MSACAbstractLog *log1 = [MSACAbstractLog new];

  // When
  [self.sut channel:nil prepareLog:log1];

  // Then
  XCTAssertNil(log1.distributionGroupId);

  // If
  NSString *expectedDistributionGroupId = @"GROUP-ID";
  MSACAbstractLog *log2 = [MSACAbstractLog new];

  // When
  [self.sut updateDistributionGroupId:expectedDistributionGroupId];
  [self.sut channel:nil prepareLog:log2];

  // Then
  XCTAssertEqual(log2.distributionGroupId, expectedDistributionGroupId);

  // If
  MSACAbstractLog *log3 = [MSACAbstractLog new];

  // When
  [self.sut removeDistributionGroupId];
  [self.sut channel:nil prepareLog:log3];

  // Then
  XCTAssertNil(log3.distributionGroupId);
}

@end
