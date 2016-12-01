#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "MSAnalytics.h"
#import "MSAnalyticsInternal.h"

@interface MSAnalyticsTests : XCTestCase
@end

@implementation MSAnalyticsTests

#pragma mark - Tests

- (void)testValidatePropertyType {

  // If
  NSDictionary *validProperties = @{@"Key1": @"Value1", @"Key2": @"Value2", @"Key3": @"Value3"};
  NSDictionary *invalidProperties = @{@"Key1": @"Value1", @"Key2": @(2), @"Key3": @"Value3"};

  // When
  BOOL valid = [[MSAnalytics sharedInstance] validatePropertyValueType:validProperties];
  BOOL invalid = [[MSAnalytics sharedInstance] validatePropertyValueType:invalidProperties];

  // Then
  XCTAssertTrue(valid);
  XCTAssertFalse(invalid);
}

@end
