#import <XCTest/XCTest.h>
#import "MSLogger.h"
#import "MSMobileCenter.h"
#import "MSMobileCenterInternal.h"

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
  // Need to set sdkStarted to NO to make sure the start-logic goes through once, otherwise this test will fail
  // randomly as other tests might call start:withFeatures, too.
  [MSMobileCenter sharedInstance].sdkStarted = NO;
  [MSMobileCenter start:[[NSUUID UUID] UUIDString] withFeatures:nil];
  
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
