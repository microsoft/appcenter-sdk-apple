#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "AVAStartSessionLog.h"


@interface AVAStartSessionLogTests : XCTestCase

@property (nonatomic, strong) AVAStartSessionLog *sut;

@end

@implementation AVAStartSessionLogTests

@synthesize sut = _sut;

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
  _sut = [AVAStartSessionLog new];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - Tests

- (void)testSerializingSessionToDictionaryWorks {
  
  // If
  AVADeviceLog *device = [AVADeviceLog new];
  NSString *typeName = @"startSession";
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
  AVADeviceLog *device = [AVADeviceLog new];
  NSString *typeName = @"startSession";
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
  assertThat(actual, instanceOf([AVAStartSessionLog class]));
  
  AVAStartSessionLog *actualSession = actual;
  assertThat(actualSession.device, notNilValue());
  assertThat(actualSession.toffset, equalTo(tOffset));
  assertThat(actualSession.type, equalTo(typeName));
  assertThat(actualSession.sid, equalTo(sessionId));
}

@end
