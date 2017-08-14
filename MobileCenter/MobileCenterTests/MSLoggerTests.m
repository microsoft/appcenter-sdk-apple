#import "MSLogger.h"
#import "MSMobileCenter.h"
#import "MSMobileCenterInternal.h"
#import "MSMobileCenterPrivate.h"
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
  // Check default loglevel before MSMobileCenter was started.
  XCTAssertTrue([MSLogger currentLogLevel] == MSLogLevelAssert);
  // Need to set sdkConfigured to NO to make sure the start-logic goes through once, otherwise this test will fail
  // randomly as other tests might call start:withServices, too.
  [MSMobileCenter resetSharedInstance];
  [MSMobileCenter sharedInstance].sdkConfigured = NO;
  [MSMobileCenter start:MS_UUID_STRING withServices:nil];

  XCTAssertTrue([MSLogger currentLogLevel] == MSLogLevelWarning);
}

- (void)testLoglevels {
  // Check isUserDefinedLogLevel
  XCTAssertFalse([MSLogger isUserDefinedLogLevel]);
  [MSLogger setCurrentLogLevel:MSLogLevelVerbose];
  XCTAssertTrue([MSLogger isUserDefinedLogLevel]);
}

- (void)testSetCurrentLoglevelWorks {
  [MSLogger setCurrentLogLevel:MSLogLevelWarning];
  XCTAssertTrue([MSLogger currentLogLevel] == MSLogLevelWarning);
}

@end
