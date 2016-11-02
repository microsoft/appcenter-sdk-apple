#import <XCTest/XCTest.h>
#import "MSLogger.h"
#import "MSSonoma.h"
#import "MSSonomaInternal.h"

@interface MSLoggerTests : XCTestCase

@end

@implementation MSLoggerTests

- (void)setUp {
  [super setUp];
  
  [MSLogger setCurrentLogLevel:SNMLogLevelAssert];
  [MSLogger setIsUserDefinedLogLevel:NO];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testDefaultLogLevels {
  // Check default loglevel before MSSonoma was started.
  XCTAssertTrue([MSLogger currentLogLevel] == SNMLogLevelAssert);
  // Need to set sdkStarted to NO to make sure the start-logic goes through once, otherwise this test will fail
  // randomly as other tests might call start:withFeatures, too.
  [MSSonoma sharedInstance].sdkStarted = NO;
  [MSSonoma start:[[NSUUID UUID] UUIDString] withFeatures:nil];
  
  XCTAssertTrue([MSLogger currentLogLevel] == SNMLogLevelWarning);
}

- (void)testLoglevels {
  // Check isUserDefinedLogLevel
  XCTAssertFalse([MSLogger isUserDefinedLogLevel]);
  [MSLogger setCurrentLogLevel:SNMLogLevelVerbose];
  XCTAssertTrue([MSLogger isUserDefinedLogLevel]);
}

- (void)testSetCurrentLoglevelWorks {
  [MSLogger setCurrentLogLevel:SNMLogLevelWarning];
  XCTAssertTrue([MSLogger currentLogLevel] == SNMLogLevelWarning);
}

@end
