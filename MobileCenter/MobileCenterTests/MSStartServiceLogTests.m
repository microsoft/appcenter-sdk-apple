#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSStartServiceLog.h"
#import "MobileCenter+Internal.h"

@interface MSStartServiceLogTests : XCTestCase

@property(nonatomic, strong) MSStartServiceLog *sut;

@end

@implementation MSStartServiceLogTests

@synthesize sut = _sut;

#pragma mark - Setup

- (void)setUp {
  [super setUp];
  self.sut = [MSStartServiceLog new];
}

#pragma mark - Tests

- (void)testSerializingEventToDictionaryWorks {

  // If
  NSArray<NSString*>* services = @[@"Service0", @"Service1", @"Service2"];
  self.sut.services = services;

  // When
  NSMutableDictionary *actual = [self.sut serializeToDictionary];

  // Then
  assertThat(actual, notNilValue());
  NSArray *actualServices = actual[@"services"];
  XCTAssertEqual(actualServices.count, services.count);
  for(NSUInteger i = 0; i < actualServices.count; ++i) {
    assertThat(actualServices[i], equalTo(services[i]));
  }
}

- (void)testNSCodingSerializationAndDeserializationWorks {

  // If
  NSArray<NSString*>* services = @[@"Service0", @"Service1", @"Service2"];
  self.sut.services = services;

  // When
  NSData *serializedLog = [NSKeyedArchiver archivedDataWithRootObject:self.sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedLog];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([MSStartServiceLog class]));

  MSStartServiceLog *log = actual;
  NSArray *actualServices = log.services;
  XCTAssertEqual(actualServices.count, services.count);
  for(NSUInteger i = 0; i < actualServices.count; ++i) {
    assertThat(actualServices[i], equalTo(services[i]));
  }
}

@end
