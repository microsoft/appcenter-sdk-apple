#import "MSAbstractLogInternal.h"
#import "MSAbstractLogPrivate.h"
#import "MSDevice.h"
#import "MSTestFrameworks.h"

@interface MSAbstractLogTests : XCTestCase

@property(nonatomic, strong) MSAbstractLog *sut;

@end

@implementation MSAbstractLogTests

@synthesize sut = _sut;

#pragma mark - Setup

- (void)setUp {
  [super setUp];
  self.sut = [MSAbstractLog new];
}

#pragma mark - Tests

- (void)testSerializingToDictionaryWorks {

  // If
  self.sut.type = @"fake";
  self.sut.timestamp = [NSDate dateWithTimeIntervalSince1970:0];
  self.sut.sid = @"FAKE-SESSION-ID";
  self.sut.distributionGroupId = @"FAKE-GROUP-ID";
  self.sut.device = [MSDevice new];

  // When
  NSMutableDictionary *actual = [self.sut serializeToDictionary];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"type"], equalTo(@"fake"));
  assertThat(actual[@"timestamp"], equalTo(@"1970-01-01T00:00:00.000Z"));
  assertThat(actual[@"sid"], equalTo(@"FAKE-SESSION-ID"));
  assertThat(actual[@"distributionGroupId"], equalTo(@"FAKE-GROUP-ID"));
  assertThat(actual[@"device"], equalTo(@{}));
}

- (void)testNSCodingSerializationAndDeserializationWorks {

  // If
  NSString *type = @"fake";
  NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:0];
  NSString *sid = @"FAKE-SESSION-ID";
  NSString *distributionGroupId = @"FAKE-GROUP-ID";
  MSDevice *device = [MSDevice new];

  self.sut.type = type;
  self.sut.timestamp = timestamp;
  self.sut.sid = sid;
  self.sut.distributionGroupId = distributionGroupId;
  self.sut.device = device;

  // When
  NSData *serializedLog = [NSKeyedArchiver archivedDataWithRootObject:self.sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedLog];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([MSAbstractLog class]));

  MSAbstractLog *actualLog = actual;
  assertThat(actualLog.type, equalTo(type));
  assertThat(actualLog.timestamp, equalTo(timestamp));
  assertThat(actualLog.sid, equalTo(sid));
  assertThat(actualLog.distributionGroupId, equalTo(distributionGroupId));
  assertThat(actualLog.device, equalTo(device));
}

- (void)testIsValid {

  // If
  id device = OCMClassMock([MSDevice class]);
  OCMStub([device isValid]).andReturn(YES);
  self.sut.type = @"fake";
  self.sut.timestamp = [NSDate dateWithTimeIntervalSince1970:42];
  self.sut.device = device;

  // Then
  XCTAssertTrue([self.sut isValid]);

  // When
  self.sut.type = nil;
  self.sut.timestamp = [NSDate dateWithTimeIntervalSince1970:42];
  self.sut.device = device;

  // Then
  XCTAssertFalse([self.sut isValid]);

  // When
  self.sut.type = @"fake";
  self.sut.timestamp = nil;
  self.sut.device = device;

  // Then
  XCTAssertFalse([self.sut isValid]);

  // When
  self.sut.type = @"fake";
  self.sut.timestamp = [NSDate dateWithTimeIntervalSince1970:42];
  self.sut.device = nil;

  // Then
  XCTAssertFalse([self.sut isValid]);
}

- (void)testIsEqual {

  // If
  NSString *type = @"fake";
  NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:0];
  NSString *sid = @"FAKE-SESSION-ID";
  NSString *distributionGroupId = @"FAKE-GROUP-ID";
  MSDevice *device = [MSDevice new];

  self.sut.type = type;
  self.sut.timestamp = timestamp;
  self.sut.sid = sid;
  self.sut.distributionGroupId = distributionGroupId;
  self.sut.device = device;

  // When
  NSData *serializedEvent =
      [NSKeyedArchiver archivedDataWithRootObject:self.sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];
  MSAbstractLog *actualLog = actual;

  // Then
  XCTAssertTrue([self.sut isEqual:actualLog]);

  // When
  self.sut.type = @"new-fake";

  // Then
  XCTAssertFalse([self.sut isEqual:actualLog]);

  // When
  self.sut.type = @"fake";
  self.sut.distributionGroupId = @"FAKE-NEW-GROUP-ID";

  // Then
  XCTAssertFalse([self.sut isEqual:actualLog]);
}

- (void)testSerializingToJsonWorks {

  // If
  self.sut.type = @"fake";
  self.sut.timestamp = [NSDate dateWithTimeIntervalSince1970:0];
  self.sut.sid = @"FAKE-SESSION-ID";
  self.sut.distributionGroupId = @"FAKE-GROUP-ID";
  self.sut.device = [MSDevice new];

  // When
  NSString *actual = [self.sut serializeLogWithPrettyPrinting:false];
  NSData *actualData = [actual dataUsingEncoding:NSUTF8StringEncoding];
  id actualDict =
      [NSJSONSerialization JSONObjectWithData:actualData options:0 error:nil];

  // Then
  assertThat(actualDict, instanceOf([NSDictionary class]));
  assertThat([actualDict objectForKey:@"type"], equalTo(@"fake"));
  assertThat([actualDict objectForKey:@"timestamp"],
             equalTo(@"1970-01-01T00:00:00.000Z"));
  assertThat([actualDict objectForKey:@"sid"], equalTo(@"FAKE-SESSION-ID"));
  assertThat([actualDict objectForKey:@"distributionGroupId"],
             equalTo(@"FAKE-GROUP-ID"));
  assertThat([actualDict objectForKey:@"device"], equalTo(@{}));
}

- (void)testTransmissionTargetsWork {

  // If
  NSString *transmissionTargetToken1 = @"t1";
  NSString *transmissionTargetToken = @"t2";

  // When
  [self.sut addTransmissionTargetToken:transmissionTargetToken1];
  [self.sut addTransmissionTargetToken:transmissionTargetToken1];
  [self.sut addTransmissionTargetToken:transmissionTargetToken];
  NSSet *transmissionTargets = [self.sut transmissionTargetTokens];

  // Then
  XCTAssertEqual([transmissionTargets count], (uint)2);
  XCTAssertTrue([transmissionTargets containsObject:transmissionTargetToken1]);
  XCTAssertTrue([transmissionTargets containsObject:transmissionTargetToken]);
}

- (void)testToCommonSchemaLogs {

  // IF
  self.sut.transmissionTargetTokens = nil;

  // When
  NSArray<MSCommonSchemaLog *> *csLogs = [self.sut toCommonSchemaLogs];

  // Then
  XCTAssertNil(csLogs);

  // IF
  self.sut.transmissionTargetTokens = [@[] mutableCopy];

  // When
  csLogs = [self.sut toCommonSchemaLogs];

  // Then
  XCTAssertNil(csLogs);

  // IF
  NSArray *expectedIKeys = @[ @"o:iKey1", @"o:iKey2" ];
  self.sut.transmissionTargetTokens =
      [NSSet setWithArray:@[ @"iKey1-dummytoken", @"iKey2-dummytoken" ]];
  // When
  csLogs = [self.sut toCommonSchemaLogs];

  // Then
  XCTAssertTrue([expectedIKeys containsObject:csLogs[0].iKey]);
  XCTAssertTrue([expectedIKeys containsObject:csLogs[1].iKey]);
}

@end
