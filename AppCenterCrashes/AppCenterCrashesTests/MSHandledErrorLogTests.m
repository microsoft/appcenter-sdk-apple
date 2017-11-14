#import "MSCrashesTestUtil.h"
#import "MSException.h"
#import "MSHandledErrorLog.h"
#import "MSTestFrameworks.h"

@interface MSHandledErrorLogTests : XCTestCase

@property(nonatomic) MSHandledErrorLog *sut;

@end

@implementation MSHandledErrorLogTests

#pragma mark - Housekeeping

- (void)setUp {
  [super setUp];
  self.sut = [self handledErrorLog];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - Helper

- (MSHandledErrorLog *)handledErrorLog {
  MSHandledErrorLog *handledErrorLog = [MSHandledErrorLog new];
  handledErrorLog.type = @"handledError";
  handledErrorLog.exception = [MSCrashesTestUtil exception];
  handledErrorLog.errorId = @"123";
  return handledErrorLog;
}

#pragma mark - Tests

- (void)testInitializationWorks {
  XCTAssertNotNil(self.sut);
}

- (void)testSerializationToDictionaryWorks {

  // When
  NSDictionary *actual = [self.sut serializeToDictionary];

  // Then
  XCTAssertNotNil(actual);
  assertThat(actual[@"type"], equalTo(self.sut.type));
  assertThat(actual[@"id"], equalTo(self.sut.errorId));
  NSDictionary *exceptionDictionary = actual[@"exception"];
  XCTAssertNotNil(exceptionDictionary);
  assertThat(exceptionDictionary[@"type"], equalTo(self.sut.exception.type));
  assertThat(exceptionDictionary[@"message"], equalTo(self.sut.exception.message));
  assertThat(exceptionDictionary[@"wrapperSdkName"], equalTo(self.sut.exception.wrapperSdkName));
}

- (void)testNSCodingSerializationAndDeserializationWorks {

  // When
  NSData *serializedEvent = [NSKeyedArchiver archivedDataWithRootObject:self.sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([MSHandledErrorLog class]));

  // The MSHandledErrorLog.
  MSHandledErrorLog *actualLog = actual;
  assertThat(actualLog, equalTo(self.sut));
  XCTAssertTrue([actualLog isEqual:self.sut]);
  assertThat(actualLog.type, equalTo(self.sut.type));
  assertThat(actualLog.errorId, equalTo(self.sut.errorId));

  // The exception field.
  MSException *actualException = actualLog.exception;
  assertThat(actualException.type, equalTo(self.sut.exception.type));
  assertThat(actualException.message, equalTo(self.sut.exception.message));
  assertThat(actualException.wrapperSdkName, equalTo(self.sut.exception.wrapperSdkName));
}

- (void)testIsEqual {

  // When
  MSHandledErrorLog *first = [self handledErrorLog];
  MSHandledErrorLog *second = [self handledErrorLog];

  // Then
  XCTAssertTrue([first isEqual:second]);

  // When
  second.errorId = MS_UUID_STRING;

  // Then
  XCTAssertFalse([first isEqual:second]);
}

- (void)testIsValid {

  // When
  MSHandledErrorLog *log = [MSHandledErrorLog new];
  log.device = OCMClassMock([MSDevice class]);
  OCMStub([log.device isValid]).andReturn(YES);
  log.sid = @"sid";
  log.timestamp = [NSDate dateWithTimeIntervalSince1970:42];
  log.errorId = @"errorId";
  log.sid = MS_UUID_STRING;

  // Then
  XCTAssertFalse([log isValid]);

  // When
  log.errorId = MS_UUID_STRING;

  // Then
  XCTAssertFalse([log isValid]);

  // When
  log.exception = [MSCrashesTestUtil exception];

  // Then
  XCTAssertTrue([log isValid]);
}

@end
