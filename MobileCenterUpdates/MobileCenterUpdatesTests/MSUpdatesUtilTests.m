#import <XCTest/XCTest.h>
#import "MSUpdatesUtil.h"

@interface MobileCenterUpdatesTests : XCTestCase

@end

@implementation MobileCenterUpdatesTests

- (void)testGetMainBundle {
  
  // When
  NSBundle *bundle = MSUpdatesBundle();
  
  // Then
  XCTAssertNotNil(bundle);
}

- (void)testLocalizedString {
  
  // When
  NSString *test = MSUpdatesLocalizedString(@"");
  
  // Then
  XCTAssertTrue([test isEqualToString:@""]);
  
  // When
  test = MSUpdatesLocalizedString(@"NonExistendString");
  
  // Then
  XCTAssertTrue([test isEqualToString:@"NonExistendString"]);
  
  // When
  test = MSUpdatesLocalizedString(@"Working");
  
  // Then
  XCTAssertTrue([test isEqualToString:@"Yes, this works!"]);
}

@end
