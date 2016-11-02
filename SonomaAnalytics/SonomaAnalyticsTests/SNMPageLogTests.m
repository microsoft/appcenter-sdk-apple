#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "SNMPageLog.h"

@interface SNMPageLogTests : XCTestCase

@property(nonatomic, strong) SNMPageLog *sut;

@end

@implementation SNMPageLogTests

@synthesize sut = _sut;

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
  _sut = [SNMPageLog new];
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
  NSTimeInterval createTime = [[NSDate date] timeIntervalSince1970];
  NSNumber *tOffset = @(createTime);

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
  NSTimeInterval seralizedToffset = [actual[@"toffset"] integerValue];
  NSTimeInterval actualToffset = [[NSDate date] timeIntervalSince1970] - createTime;
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
  assertThat(actual, instanceOf([SNMPageLog class]));

  SNMPageLog *actualPage = actual;
  assertThat(actualPage.name, equalTo(pageName));
  assertThat(actualPage.device, notNilValue());
  assertThat(actualPage.toffset, equalTo(tOffset));
  assertThat(actualPage.type, equalTo(typeName));
  assertThat(actualPage.sid, equalTo(sessionId));
  assertThat(actualPage.properties, equalTo(properties));
}

@end
