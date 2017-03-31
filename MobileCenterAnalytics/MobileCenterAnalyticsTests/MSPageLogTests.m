#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSPageLog.h"

@interface MSPageLogTests : XCTestCase

@property(nonatomic) MSPageLog *sut;

@end

@implementation MSPageLogTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
  self.sut = [MSPageLog new];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - Tests

- (void)testSerializingPageToDictionaryWorks {

  // If
  NSString *typeName = @"page";
  NSString *pageName = @"pageName";
  MSDevice *device = [MSDevice new];
  NSString *sessionId = @"1234567890";
  NSDictionary *properties = @{ @"Key" : @"Value" };
  long long createTime = (long long)[MSUtility nowInMilliseconds];
  NSNumber *tOffset = [NSNumber numberWithLongLong:createTime];

  self.sut.name = pageName;
  self.sut.device = device;
  self.sut.toffset = tOffset;
  self.sut.sid = sessionId;
  self.sut.properties = properties;

  // When
  NSMutableDictionary *actual = [self.sut serializeToDictionary];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"name"], equalTo(pageName));
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
  NSString *typeName = @"page";
  NSString *pageName = @"pageName";
  MSDevice *device = [MSDevice new];
  NSString *sessionId = @"1234567890";
  NSNumber *tOffset = @(3);
  NSDictionary *properties = @{ @"Key" : @"Value" };

  self.sut.name = pageName;
  self.sut.device = device;
  self.sut.toffset = tOffset;
  self.sut.sid = sessionId;
  self.sut.properties = properties;

  // When
  NSData *serializedEvent = [NSKeyedArchiver archivedDataWithRootObject:self.sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([MSPageLog class]));

  MSPageLog *actualPage = actual;
  assertThat(actualPage.name, equalTo(pageName));
  assertThat(actualPage.device, notNilValue());
  assertThat(actualPage.toffset, equalTo(tOffset));
  assertThat(actualPage.type, equalTo(typeName));
  assertThat(actualPage.sid, equalTo(sessionId));
  assertThat(actualPage.properties, equalTo(properties));
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
  self.sut.name = @"pageName";

  // Then
  XCTAssertTrue([self.sut isValid]);
}

@end
