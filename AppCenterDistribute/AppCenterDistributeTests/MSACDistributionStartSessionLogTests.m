// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACAbstractLogInternal.h"
#import "MSACDevice.h"
#import "MSACDistributionStartSessionLog.h"
#import "MSACTestFrameworks.h"

@interface MSACDistributionStartSessionLogTests : XCTestCase

@property(nonatomic) MSACDistributionStartSessionLog *startSessionLog;

@end

@implementation MSACDistributionStartSessionLogTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
  self.startSessionLog = [[MSACDistributionStartSessionLog alloc] init];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - Tests

- (void)testSerializingEventToDictionaryWorks {

  // If
  MSACDevice *device = [MSACDevice new];
  NSString *sessionId = @"1234567890";
  NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:42];

  self.startSessionLog.device = device;
  self.startSessionLog.timestamp = timestamp;
  self.startSessionLog.sid = sessionId;

  // When
  NSMutableDictionary *actual = [self.startSessionLog serializeToDictionary];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"device"], notNilValue());
  assertThat(actual[@"sid"], equalTo(sessionId));
  assertThat(actual[@"type"], equalTo(@"distributionStartSession"));
  assertThat(actual[@"device"], notNilValue());
  assertThat(actual[@"timestamp"], equalTo(@"1970-01-01T00:00:42.000Z"));
}

- (void)testNSCodingSerializationAndDeserializationWorks {

  // If
  MSACDevice *device = [MSACDevice new];
  NSString *sessionId = @"1234567890";
  NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:42];

  self.startSessionLog.device = device;
  self.startSessionLog.timestamp = timestamp;
  self.startSessionLog.sid = sessionId;

  // When
  NSData *serializedEvent = [NSKeyedArchiver archivedDataWithRootObject:self.startSessionLog];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];

  // Then
  assertThat(actual, notNilValue());
  MSACDistributionStartSessionLog *actualLog = actual;
  assertThat(actualLog.device, notNilValue());
  assertThat(actualLog.timestamp, equalTo(timestamp));
  assertThat(actualLog.type, equalTo(@"distributionStartSession"));
  assertThat(actualLog.sid, equalTo(sessionId));
  XCTAssertTrue([self.startSessionLog isEqual:actualLog]);
}

- (void)testIsValid {

  // If
  self.startSessionLog.device = OCMClassMock([MSACDevice class]);
  OCMStub([self.startSessionLog.device isValid]).andReturn(YES);

  // Then
  XCTAssertFalse([self.startSessionLog isValid]);

  // When
  self.startSessionLog.sid = @"1234567890";

  // Then
  XCTAssertFalse([self.startSessionLog isValid]);

  // When
  self.startSessionLog.timestamp = [NSDate dateWithTimeIntervalSince1970:42];

  // Then
  XCTAssertTrue([self.startSessionLog isValid]);
}

- (void)testIsNotEqualToNil {

  // Then
  XCTAssertFalse([self.startSessionLog isEqual:nil]);
}

@end
