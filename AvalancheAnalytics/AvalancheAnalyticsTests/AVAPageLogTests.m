#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>

#import "AVAPageLog.h"

@interface AVAPageLogTests : XCTestCase

@property (nonatomic, strong) AVAPageLog *sut;

@end

@implementation AVAPageLogTests

@synthesize sut = _sut;

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
  _sut = [AVAPageLog new];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - Tests

- (void)testSerializingPageToDictionaryWorks {
  
  // If
  NSString *typeName = @"page";
  NSString *pageName = @"pageName";
  AVADeviceLog *device = [AVADeviceLog new];
  NSString *sessionId = @"1234567890";
  NSNumber *tOffset = @(3);
  NSDictionary *properties = @{@"Key": @"Value"};
  
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
  assertThat(actual[@"toffset"], equalTo(tOffset));
  assertThat(actual[@"type"], equalTo(typeName));
  assertThat(actual[@"properties"], equalTo(properties));
}

- (void)testNSCodingSerializationAndDeserializationWorks {
  
  // If
  NSString *typeName = @"page";
  NSString *pageName = @"pageName";
  AVADeviceLog *device = [AVADeviceLog new];
  NSString *sessionId = @"1234567890";
  NSNumber *tOffset = @(3);
  NSDictionary *properties = @{@"Key": @"Value"};
  
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
  assertThat(actual, instanceOf([AVAPageLog class]));
  
  AVAPageLog *actualPage = actual;
  assertThat(actualPage.name, equalTo(pageName));
  assertThat(actualPage.device, notNilValue());
  assertThat(actualPage.toffset, equalTo(tOffset));
  assertThat(actualPage.type, equalTo(typeName));
  assertThat(actualPage.sid, equalTo(sessionId));
  assertThat(actualPage.properties, equalTo(properties));
}

@end
