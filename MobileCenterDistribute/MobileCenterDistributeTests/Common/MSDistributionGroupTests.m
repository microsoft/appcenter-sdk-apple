#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "MSDistributionGroup.h"

@interface MSDistributionGroupTests : XCTestCase

@end

@implementation MSDistributionGroupTests

#pragma mark - Tests

- (void)testIsEqual {

  // Then
  XCTAssertTrue([[MSDistributionGroup new] isEqual:[MSDistributionGroup new]]);
}

- (void)testIsNotEqualToNil {

  // Then
  XCTAssertFalse([[MSDistributionGroup new] isEqual:nil]);
}

@end
