#import <XCTest/XCTest.h>
#import "MSDistributeUtil.h"

@interface MobileCenterDistributeTests : XCTestCase

@end

@implementation MobileCenterDistributeTests

- (void)testGetMainBundle {

  // When
  NSBundle *bundle = MSDistributeBundle();

  // Then
  XCTAssertNotNil(bundle);
}

- (void)testLocalizedString {

  // When
  NSString *test = MSDistributeLocalizedString(@"");

  // Then
  XCTAssertTrue([test isEqualToString:@""]);

  // When
  test = MSDistributeLocalizedString(nil);

  // Then
  XCTAssertTrue([test isEqualToString:@""]);

  // When
  test = MSDistributeLocalizedString(@"NonExistendString");

  // Then
  XCTAssertTrue([test isEqualToString:@"NonExistendString"]);

  // When
  test = MSDistributeLocalizedString(@"Ignore");
  
  // Then
  XCTAssertTrue([test isEqualToString:@"Ignore"]);
}

- (void)testDebugConfiurationDetectionWorks {
  
  // When
  XCTAssertTrue([MSUpdatesUtil isRunningInDebugConfiguration]);
}

@end
