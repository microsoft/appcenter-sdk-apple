#import "AppCenter+Internal.h"
#import "MSAbstractLogInternal.h"
#import "MSLogContainer.h"
#import "MSTestFrameworks.h"

@interface MSLogContainerTests : XCTestCase

@end

@implementation MSLogContainerTests

- (void)testLogContainerSerialization {

  // If
  MSLogContainer *logContainer = [MSLogContainer new];

  MSAbstractLog *log1 = [MSAbstractLog new];
  log1.sid = MS_UUID_STRING;
  log1.timestamp = [NSDate date];

  MSAbstractLog *log2 = [MSAbstractLog new];
  log2.sid = MS_UUID_STRING;
  log2.timestamp = [NSDate date];

  logContainer.logs = (NSArray<id<MSLog>> *)@[ log1, log2 ];

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
