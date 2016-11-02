#import <XCTest/XCTest.h>
#import "SNMLogger.h"
#import "SNMSonoma.h"
#import "SNMSonomaInternal.h"

@interface SNMLoggerTests : XCTestCase

@end

@implementation SNMLoggerTests

- (void)setUp {
  [super setUp];
  
  [SNMLogger setCurrentLogLevel:SNMLogLevelAssert];
  [SNMLogger setIsUserDefinedLogLevel:NO];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testDefaultLogLevels {
  // Check default loglevel before SNMSonoma was started.
  XCTAssertTrue([SNMLogger currentLogLevel] == SNMLogLevelAssert);
  // Need to set sdkStarted to NO to make sure the start-logic goes through once, otherwise this test will fail
  // randomly as other tests might call start:withFeatures, too.
  [SNMSonoma sharedInstance].sdkStarted = NO;
  [SNMSonoma start:[[NSUUID UUID] UUIDString] withFeatures:nil];
  
  XCTAssertTrue([SNMLogger currentLogLevel] == SNMLogLevelWarning);
}

- (void)testLoglevels {
  // Check isUserDefinedLogLevel
  XCTAssertFalse([SNMLogger isUserDefinedLogLevel]);
  [SNMLogger setCurrentLogLevel:SNMLogLevelVerbose];
  XCTAssertTrue([SNMLogger isUserDefinedLogLevel]);
}

- (void)testSetCurrentLoglevelWorks {
  [SNMLogger setCurrentLogLevel:SNMLogLevelWarning];
  XCTAssertTrue([SNMLogger currentLogLevel] == SNMLogLevelWarning);
}

@end
