// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSACDistributionGroup.h"
#import "MSACTestFrameworks.h"

@interface MSACDistributionGroupTests : XCTestCase

@end

@implementation MSACDistributionGroupTests

#pragma mark - Tests

- (void)testIsEqual {

  // Then
  XCTAssertTrue([[MSACDistributionGroup new] isEqual:[MSACDistributionGroup new]]);
}

- (void)testIsNotEqualToNil {

  // Then
  XCTAssertFalse([[MSACDistributionGroup new] isEqual:nil]);
}

@end
