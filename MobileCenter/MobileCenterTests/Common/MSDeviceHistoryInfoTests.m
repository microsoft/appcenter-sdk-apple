#import <XCTest/XCTest.h>

#import "MSDevice.h"
#import "MSDeviceHistoryInfo.h"

@interface MSDeviceHistoryInfoTests : XCTestCase

@end

@implementation MSDeviceHistoryInfoTests

- (void)testCreationWorks {

  // When
  MSDeviceHistoryInfo *expected = [MSDeviceHistoryInfo new];
  
  // Then
  XCTAssertNotNil(expected);
  
  // When
  MSDevice *aDevice = [MSDevice new];
  expected = [[MSDeviceHistoryInfo alloc] initWithTOffset:@1 andDevice:aDevice];
  
  // Then
  XCTAssertNotNil(expected);
  XCTAssertTrue([expected.device isEqual:aDevice]);
  XCTAssertTrue([expected.tOffset isEqualToNumber:@1]);
}

@end
