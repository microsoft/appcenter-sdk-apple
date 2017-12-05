#import "MSPushLog.h"
#import "MSTestFrameworks.h"

@interface MSPushLogTests : XCTestCase

@property(nonatomic) MSPushLog *sut;

@end

@implementation MSPushLogTests

@synthesize sut = _sut;

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
  self.sut = [MSPushLog new];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - Tests

- (void)testSerializingPushLogToDictionaryWorks {

  // If
  NSString *typeName = @"pushInstallation";
  NSString *pushToken = MS_UUID_STRING;
  self.sut.pushToken = pushToken;

  // When
  NSMutableDictionary *pushLogDictionary = [self.sut serializeToDictionary];

  // Then
  XCTAssertNotNil(pushLogDictionary);
  assertThat(pushLogDictionary[@"type"], equalTo(typeName));
  assertThat(pushLogDictionary[@"pushToken"], equalTo(pushToken));
}

- (void)testNSCodingSerializationAndDeserializationWorks {

  // If
  NSString *typeName = @"pushInstallation";
  NSString *pushToken = MS_UUID_STRING;
  self.sut.pushToken = pushToken;

  // When
  NSData *serializedEvent = [NSKeyedArchiver archivedDataWithRootObject:self.sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];

  // Then
  XCTAssertNotNil(actual);
  assertThat(actual, instanceOf([MSPushLog class]));
  MSPushLog *actualPush = actual;
  assertThat(actualPush.type, equalTo(typeName));
  assertThat(actualPush.pushToken, equalTo(pushToken));
}

- (void)testIsValid {

  // If
  self.sut.device = OCMClassMock([MSDevice class]);
  OCMStub([self.sut.device isValid]).andReturn(YES);
  self.sut.timestamp = [NSDate dateWithTimeIntervalSince1970:42];
  self.sut.sid = @"1234567890";

  // Then
  XCTAssertFalse([self.sut isValid]);

  // When
  self.sut.pushToken = MS_UUID_STRING;

  // Then
  XCTAssertTrue([self.sut isValid]);
}

- (void)testIsEqual {

  // If
  MSPushLog *first = [MSPushLog new];
  MSPushLog *second = [MSPushLog new];

  // Then
  XCTAssertTrue([first isEqual:second]);

  // When
  second.pushToken = @"SomethingElse";

  // Then
  XCTAssertFalse([first isEqual:second]);
}

- (void)testIsNotEqualToNil {

  // Then
  XCTAssertFalse([self.sut isEqual:nil]);
}

@end
