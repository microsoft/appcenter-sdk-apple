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
  NSDictionary *invalidKeyInProperties = @{@"Key1": @"Value1", @"Key2": @(2), @"Key3": @"Value3"};
  NSDictionary *invalidValueInProperties = @{@"Key1": @"Value1", @(2): @"Value2", @"Key3": @"Value3"};

  // When
  BOOL valid = [[MSAnalytics sharedInstance] validateProperties:validProperties];
  BOOL invalidKey = [[MSAnalytics sharedInstance] validateProperties:invalidKeyInProperties];
  BOOL invalidValue = [[MSAnalytics sharedInstance] validateProperties:invalidValueInProperties];

  // Then
  XCTAssertTrue(valid);
  XCTAssertFalse(invalidKey);
  XCTAssertFalse(invalidValue);
}

@end
