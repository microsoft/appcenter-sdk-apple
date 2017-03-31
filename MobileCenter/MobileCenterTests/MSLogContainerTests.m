#import <XCTest/XCTest.h>
#import "MobileCenter+Internal.h"
#import "MSAbstractLog.h"
#import "MSLogContainer.h"

@interface MSLogContainerTests : XCTestCase

@end

@implementation MSLogContainerTests

- (void)testLogContainerSerialization {

  // If
  MSLogContainer *logContainer = [MSLogContainer new];

  MSAbstractLog *log1 = [MSAbstractLog new];
  log1.sid = MS_UUID_STRING;
  log1.toffset = [NSNumber numberWithLongLong:@((long long)[MSUtility nowInMilliseconds])];

  MSAbstractLog *log2 = [MSAbstractLog new];
  log2.sid = MS_UUID_STRING;
  log2.toffset = [NSNumber numberWithLongLong:@((long long)[MSUtility nowInMilliseconds])];

  logContainer.logs = (NSArray<MSLog> *)@[ log1, log2 ];

  // When
  NSString *jsonString = [logContainer serializeLog];

  // Then
  XCTAssertTrue([jsonString length] > 0);
}

- (void)testIsValidForEmptyLogs {

  // If
  MSLogContainer *logContainer = [MSLogContainer new];

  XCTAssertFalse([logContainer isValid]);
}

@end
