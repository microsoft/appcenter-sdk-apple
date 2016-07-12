#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>

#import "AVAEndSessionLog.h"

@interface AVAEndSessionLogTests : XCTestCase

@property (nonatomic, strong) AVAEndSessionLog *sut;

@end

@implementation AVAEndSessionLogTests

@synthesize sut = _sut;

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
  _sut = [AVAEndSessionLog new];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - Tests

- (void)testSerializingSessionToDictionaryWorks {
  
  // If
  NSString *typeName = @"endSession";
  NSString *sessionId = @"1234567890";
  NSNumber *tOffset = @(3);
  
  self.sut.toffset = tOffset;
  self.sut.sid = sessionId;
  
  // When
  NSMutableDictionary *actual = [self.sut serializeToDictionary];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"toffset"], equalTo(tOffset));
  assertThat(actual[@"type"], equalTo(typeName));
}

- (void)testNSCodingSerializationAndDeserializationWorks {
  
  // If
  NSString *typeName = @"endSession";
  NSString *sessionId = @"1234567890";
  NSNumber *tOffset = @(3);
  
  self.sut.toffset = tOffset;
  self.sut.sid = sessionId;
  
  // When
  NSData *serializedEvent = [NSKeyedArchiver archivedDataWithRootObject:self.sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([AVAEndSessionLog class]));
  
  AVAEndSessionLog *actualSession = actual;
  assertThat(actualSession.toffset, equalTo(tOffset));
  assertThat(actualSession.type, equalTo(typeName));
  assertThat(actualSession.sid, equalTo(sessionId));
}

@end
