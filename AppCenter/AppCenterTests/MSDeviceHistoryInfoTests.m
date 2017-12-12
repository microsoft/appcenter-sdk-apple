#import "MSDevice.h"
#import "MSDeviceHistoryInfo.h"
#import "MSTestFrameworks.h"

@interface MSDeviceHistoryInfoTests : XCTestCase

@end

@implementation MSDeviceHistoryInfoTests

- (void)testCreationWorks {

  // When
  MSDeviceHistoryInfo *expected = [MSDeviceHistoryInfo new];

  // Then
  XCTAssertNotNil(expected);

  // When
  NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:42];
  MSDevice *aDevice = [MSDevice new];
  expected = [[MSDeviceHistoryInfo alloc] initWithTimestamp:timestamp andDevice:aDevice];

  // Then
  XCTAssertNotNil(expected);
  XCTAssertTrue([expected.timestamp isEqual:timestamp]);
  XCTAssertTrue([expected.device isEqual:aDevice]);
}

@end
