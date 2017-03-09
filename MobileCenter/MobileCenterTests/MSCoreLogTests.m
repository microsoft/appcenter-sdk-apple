#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSCoreLog.h"
#import "MobileCenter+Internal.h"

@interface MSCoreLogTests : XCTestCase

@property(nonatomic, strong) MSCoreLog *sut;

@end

@implementation MSCoreLogTests

@synthesize sut = _sut;

#pragma mark - Setup

- (void)setUp {
  [super setUp];
  self.sut = [MSCoreLog new];
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
  assertThat(actual, instanceOf([MSCoreLog class]));

  MSCoreLog *log = actual;
  NSArray *actualServices = log.services;
  XCTAssertEqual(actualServices.count, services.count);
  for(NSUInteger i = 0; i < actualServices.count; ++i) {
    assertThat(actualServices[i], equalTo(services[i]));
  }
}

@end
