#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "SNMStartSessionLog.h"

@interface SNMStartSessionLogTests : XCTestCase

@property(nonatomic, strong) SNMStartSessionLog *sut;

@end

@implementation SNMStartSessionLogTests

@synthesize sut = _sut;

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
  _sut = [SNMStartSessionLog new];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - Tests

- (void)testSerializingSessionToDictionaryWorks {

  // If
  MSDevice *device = [MSDevice new];
  NSString *typeName = @"start_session";
  NSString *sessionId = @"1234567890";
  NSTimeInterval createTime = [[NSDate date] timeIntervalSince1970];
  NSNumber *tOffset = @(createTime);

  self.sut.device = device;
  self.sut.toffset = tOffset;
  self.sut.sid = sessionId;

  // When
  NSMutableDictionary *actual = [self.sut serializeToDictionary];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"type"], equalTo(typeName));
  assertThat(actual[@"device"], notNilValue());
  NSTimeInterval seralizedToffset = [actual[@"toffset"] integerValue];
  NSTimeInterval actualToffset = [[NSDate date] timeIntervalSince1970] - createTime;
  assertThat(@(seralizedToffset), lessThan(@(actualToffset)));
}

- (void)testNSCodingSerializationAndDeserializationWorks {

  // If
  MSDevice *device = [MSDevice new];
  NSString *typeName = @"start_session";
  NSString *sessionId = @"1234567890";
  NSNumber *tOffset = @(3);

  self.sut.device = device;
  self.sut.toffset = tOffset;
  self.sut.sid = sessionId;

  // When
  NSData *serializedEvent = [NSKeyedArchiver archivedDataWithRootObject:self.sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([SNMStartSessionLog class]));

  SNMStartSessionLog *actualSession = actual;
  assertThat(actualSession.device, notNilValue());
  assertThat(actualSession.toffset, equalTo(tOffset));
  assertThat(actualSession.type, equalTo(typeName));
  assertThat(actualSession.sid, equalTo(sessionId));
}

@end
