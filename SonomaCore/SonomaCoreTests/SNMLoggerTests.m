#import <XCTest/XCTest.h>
#import "SNMLoggerPrivate.h"
#import "SNMSonoma.h"

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
