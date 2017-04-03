#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "MSEventLog.h"

@interface MSEventLogTests : XCTestCase

@property(nonatomic) MSEventLog *sut;

@end

@implementation MSEventLogTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
  self.sut = [MSEventLog new];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - Tests

- (void)testSerializingEventToDictionaryWorks {

  // If
  NSString *typeName = @"event";
  NSString *eventId = MS_UUID_STRING;
  NSString *eventName = @"eventName";
  MSDevice *device = [MSDevice new];
  NSString *sessionId = @"1234567890";
  NSDictionary *properties = @{ @"Key" : @"Value" };
  long long createTime = (long long)[MSUtility nowInMilliseconds];
  NSNumber *tOffset = @(createTime);

  self.sut.eventId = eventId;
  self.sut.name = eventName;
  self.sut.device = device;
  self.sut.toffset = tOffset;
  self.sut.sid = sessionId;
  self.sut.properties = properties;

  // When
  NSMutableDictionary *actual = [self.sut serializeToDictionary];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"id"], equalTo(eventId));
  assertThat(actual[@"name"], equalTo(eventName));
  assertThat(actual[@"device"], notNilValue());
  assertThat(actual[@"sid"], equalTo(sessionId));
  assertThat(actual[@"type"], equalTo(typeName));
  assertThat(actual[@"properties"], equalTo(properties));
  assertThat(actual[@"device"], notNilValue());
  NSTimeInterval seralizedToffset = [actual[@"toffset"] longLongValue];
  NSTimeInterval actualToffset = [MSUtility nowInMilliseconds] - createTime;
  assertThat(@(seralizedToffset), lessThan(@(actualToffset)));
}

- (void)testNSCodingSerializationAndDeserializationWorks {

  // If
  NSString *typeName = @"event";
  NSString *eventId = MS_UUID_STRING;
  NSString *eventName = @"eventName";
  MSDevice *device = [MSDevice new];
  NSString *sessionId = @"1234567890";
  NSNumber *tOffset = @(3);
  NSDictionary *properties = @{ @"Key" : @"Value" };

  self.sut.eventId = eventId;
  self.sut.name = eventName;
  self.sut.device = device;
  self.sut.toffset = tOffset;
  self.sut.sid = sessionId;
  self.sut.properties = properties;

  // When
  NSData *serializedEvent = [NSKeyedArchiver archivedDataWithRootObject:self.sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([MSEventLog class]));

  MSEventLog *actualEvent = actual;
  assertThat(actualEvent.name, equalTo(eventName));
  assertThat(actualEvent.eventId, equalTo(eventId));
  assertThat(actualEvent.device, notNilValue());
  assertThat(actualEvent.toffset, equalTo(tOffset));
  assertThat(actualEvent.type, equalTo(typeName));
  assertThat(actualEvent.sid, equalTo(sessionId));
  assertThat(actualEvent.properties, equalTo(properties));
}

- (void)testIsValid {

  // If
  self.sut.device = OCMClassMock([MSDevice class]);
  OCMStub([self.sut.device isValid]).andReturn(YES);
  self.sut.toffset = @(3);
  self.sut.sid = @"1234567890";

  // Then
  XCTAssertFalse([self.sut isValid]);

  // When
  self.sut.eventId = MS_UUID_STRING;

  // Then
  XCTAssertFalse([self.sut isValid]);

  // When
  self.sut.name = @"eventName";

  // Then
  XCTAssertTrue([self.sut isValid]);
}

@end
