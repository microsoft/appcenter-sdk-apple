// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACStartSessionLog.h"
#import "MSACTestFrameworks.h"
#import "MSACUtility.h"
#import "MSACDateTimeTypedProperty.h"
#import "MSACDeviceHistoryInfo.h"
#import "MSACDoubleTypedProperty.h"
#import "MSACEventLog.h"
#import "MSACEventProperties.h"
#import "MSACLongTypedProperty.h"
#import "MSACPageLog.h"
#import "MSACStringTypedProperty.h"
#import "MSACTypedProperty.h"
#import "MSACBooleanTypedProperty.h"
#import "MSACSessionHistoryInfo.h"

@interface MSACStartSessionLogTests : XCTestCase

@property(nonatomic) MSACStartSessionLog *sut;

@end

@implementation MSACStartSessionLogTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
  self.sut = [MSACStartSessionLog new];
    NSArray *allowedClassesArray = @[[MSACSessionHistoryInfo class], [NSDate class], [MSACDevice class], [MSACAbstractLog class], [MSACEventLog class], [MSACPageLog class], [MSACEventProperties class], [MSACLogWithNameAndProperties class], [MSACBooleanTypedProperty class], [MSACDateTimeTypedProperty class], [MSACDoubleTypedProperty class], [MSACLongTypedProperty class], [MSACStringTypedProperty class], [MSACTypedProperty class], [MSACStartSessionLog class], [NSDictionary class], [MSACStartSessionLog class], [NSString class], [NSNumber class]];
            
    [MSACUtility addAllowedClasses: allowedClassesArray];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - Tests

- (void)testSerializingSessionToDictionaryWorks {

  // If
  MSACDevice *device = [MSACDevice new];
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
  MSACDevice *device = [MSACDevice new];
  NSString *typeName = @"startSession";
  NSString *sessionId = @"1234567890";
  NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:42];

  self.sut.device = device;
  self.sut.timestamp = timestamp;
  self.sut.sid = sessionId;

  // When
  NSData *serializedEvent = [MSACUtility archiveKeyedData:self.sut];
  id actual = [MSACUtility unarchiveKeyedData:serializedEvent];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([MSACStartSessionLog class]));

  MSACStartSessionLog *actualSession = actual;
  assertThat(actualSession.device, notNilValue());
  assertThat(actualSession.timestamp, equalTo(timestamp));
  assertThat(actualSession.type, equalTo(typeName));
  assertThat(actualSession.sid, equalTo(sessionId));
}

@end
