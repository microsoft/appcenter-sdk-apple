#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "SNMLogWithProperties.h"

@interface SNMLogWithPropertiesTests : XCTestCase

@property(nonatomic, strong) SNMLogWithProperties *sut;

@end

@implementation SNMLogWithPropertiesTests

@synthesize sut = _sut;

#pragma mark - Housekeeping

- (void)setUp {
  [super setUp];
  _sut = [SNMLogWithProperties new];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - Tests

- (void)testSerializingDeviceToDictionaryWorks {

  // If
  NSDictionary *properties = @{@"key1": @"value1", @"key2": @"value"};
  self.sut.properties = properties;

  // When
  NSMutableDictionary *actual = [self.sut serializeToDictionary];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"properties"], equalTo(properties));
}

- (void)testNSCodingSerializationAndDeserializationWorks {

  // If
  NSDictionary *properties = @{@"key1": @"value1", @"key2": @"value"};
  self.sut.properties = properties;

  // When
  NSData *serializedEvent = [NSKeyedArchiver archivedDataWithRootObject:self.sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([SNMLogWithProperties class]));

  SNMLogWithProperties *actualLogWithProperties = actual;
  assertThat(actualLogWithProperties.properties, equalTo(properties));
}

- (void)testIsEqual {
  // If
  NSDictionary *properties = @{@"key1": @"value1", @"key2": @"value"};
  self.sut.properties = properties;

  // When
  NSData *serializedEvent = [NSKeyedArchiver archivedDataWithRootObject:self.sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];
  SNMLogWithProperties *actualLogWithProperties = actual;

  // then
  XCTAssertTrue([self.sut.properties isEqual:actualLogWithProperties.properties]);
}

@end
