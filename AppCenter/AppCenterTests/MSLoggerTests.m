#import "MSAppCenter.h"
#import "MSAppCenterInternal.h"
#import "MSAppCenterPrivate.h"
#import "MSLoggerInternal.h"
#import "MSTestFrameworks.h"

@interface MSLoggerTests : XCTestCase

@end

@implementation MSLoggerTests

- (void)setUp {
  [super setUp];

  [MSLogger setCurrentLogLevel:MSLogLevelAssert];
  [MSLogger setIsUserDefinedLogLevel:NO];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testDefaultLogLevels {

  // Check default loglevel before MSAppCenter was started.
  XCTAssertTrue([MSLogger currentLogLevel] == MSLogLevelAssert);

  // Need to set sdkConfigured to NO to make sure the start-logic goes through once, otherwise this test will fail randomly as other tests
  // might call start:withServices, too.
  [MSAppCenter resetSharedInstance];
  [MSAppCenter sharedInstance].sdkConfigured = NO;
  [MSAppCenter start:MS_UUID_STRING withServices:nil];

  XCTAssertTrue([MSLogger currentLogLevel] == MSLogLevelWarning);
}

- (void)testSetLoglevels {

  // Check isUserDefinedLogLevel
  XCTAssertFalse([MSLogger isUserDefinedLogLevel]);
  [MSLogger setCurrentLogLevel:MSLogLevelVerbose];
  XCTAssertTrue([MSLogger isUserDefinedLogLevel]);
}

- (void)testSetCurrentLoglevelWorks {
  [MSLogger setCurrentLogLevel:MSLogLevelWarning];
  XCTAssertTrue([MSLogger currentLogLevel] == MSLogLevelWarning);
}

- (void)testLoglevelNoneDoesNotLogMessages {

  // If
  MSLogMessageProvider messageProvider = ^() {

    // Then
    XCTFail(@"Log shouldn't be printed.");
    return @"";
  };

  // When
  [MSLogger setCurrentLogLevel:MSLogLevelNone];
  [MSLogger logMessage:messageProvider level:MSLogLevelNone tag:@"TAG" file:nil function:nil line:0];
}

@end
