#import "MSStartSessionLog.h"
#import "MSTestFrameworks.h"

@interface MSStartSessionLogTests : XCTestCase

@property(nonatomic) MSStartSessionLog *sut;

@end

@implementation MSStartSessionLogTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
  self.sut = [MSStartSessionLog new];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - Tests

- (void)testSerializingSessionToDictionaryWorks {

  // If
  MSDevice *device = [MSDevice new];
  NSString *typeName = @"startSession";
  NSString *sessionId = @"1234567890";
  NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:42];

  self.sut.device = device;
  self.sut.timestamp = timestamp;
  self.sut.sid = sessionId;

  // When
  NSMutableDictionary *actual = [self.sut serializeToDictionary];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"type"], equalTo(typeName));
  assertThat(actual[@"device"], notNilValue());
  assertThat(actual[@"timestamp"], equalTo(@"1970-01-01T00:00:42.000Z"));
}

- (void)testNSCodingSerializationAndDeserializationWorks {

  // If
  MSDevice *device = [MSDevice new];
  NSString *typeName = @"startSession";
  NSString *sessionId = @"1234567890";
  NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:42];

  self.sut.device = device;
  self.sut.timestamp = timestamp;
  self.sut.sid = sessionId;

  // When
  NSData *serializedEvent = [NSKeyedArchiver archivedDataWithRootObject:self.sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([MSStartSessionLog class]));

  MSStartSessionLog *actualSession = actual;
  assertThat(actualSession.device, notNilValue());
  assertThat(actualSession.timestamp, equalTo(timestamp));
  assertThat(actualSession.type, equalTo(typeName));
  assertThat(actualSession.sid, equalTo(sessionId));
}

@end
