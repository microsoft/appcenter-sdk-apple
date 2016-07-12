#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>

#import "AVAEventLog.h"

@interface AVAEventLogTests : XCTestCase

@property (nonatomic, strong) AVAEventLog *sut;

@end

@implementation AVAEventLogTests

@synthesize sut = _sut;

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
  _sut = [AVAEventLog new];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - Tests

- (void)testSerializingEventToDictionaryWorks {

  // If
  NSString *eventId = [[NSUUID UUID] UUIDString];
  NSString *eventName = @"eventName";
  self.sut.eventId = eventId;
  self.sut.name = eventName;
  
  // When
  NSMutableDictionary *actual = [self.sut serializeToDictionary];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"id"], equalTo(eventId));
  assertThat(actual[@"name"], equalTo(eventName));
}

- (void)testNSCodingSerializationAndDeserializationWorks {
  
  // If
  NSString *eventId = [[NSUUID UUID] UUIDString];
  NSString *eventName = @"eventName";
  self.sut.eventId = eventId;
  self.sut.name = eventName;
  
  // When
  NSData *serializedEvent = [NSKeyedArchiver archivedDataWithRootObject:self.sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([AVAEventLog class]));
  
  AVAEventLog *actualEvent = actual;
  assertThat(actualEvent.name, equalTo(eventName));
  assertThat(actualEvent.eventId, equalTo(eventId));
}

@end
