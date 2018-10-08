#import <Foundation/Foundation.h>

#import "MSCustomPropertiesLog.h"
#import "MSDevice.h"
#import "MSTestFrameworks.h"

@interface MSCustomPropertiesLogTests : XCTestCase

@property(nonatomic, strong) MSCustomPropertiesLog *sut;

@end

@implementation MSCustomPropertiesLogTests

@synthesize sut = _sut;

#pragma mark - Setup

- (void)setUp {
  [super setUp];
  self.sut = [MSCustomPropertiesLog new];
}

#pragma mark - Tests

- (void)testSerializingToDictionaryWorks {

  // If
  NSString *string = @"test";
  NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
  NSNumber *number = @0;
  NSNumber *boolean = @NO;
  NSDictionary<NSString *, NSObject *> *properties =
      @{ @"t1" : string,
         @"t2" : date,
         @"t3" : number,
         @"t4" : boolean,
         @"t5" : [NSNull null],
         @"t6" : [NSData new] };
  self.sut.properties = properties;

  // When
  NSMutableDictionary *actual = [self.sut serializeToDictionary];

  // Then
  assertThat(actual, notNilValue());
  NSArray *actualProperties = actual[@"properties"];
  assertThat(actualProperties, hasCountOf(5));
  NSArray *needProperties = @[
    @{ @"name" : @"t1",
       @"type" : @"string",
       @"value" : string },
    @{ @"name" : @"t2",
       @"type" : @"dateTime",
       @"value" : @"1970-01-01T00:00:00.000Z" },
    @{ @"name" : @"t3",
       @"type" : @"number",
       @"value" : number },
    @{ @"name" : @"t4",
       @"type" : @"boolean",
       @"value" : boolean },
    @{ @"name" : @"t5",
       @"type" : @"clear" }
  ];
  actualProperties = [actualProperties sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ]];
  assertThat(actualProperties, equalTo(needProperties));
}

- (void)testNSCodingSerializationAndDeserializationWorks {

  // If
  NSString *string = @"test";
  NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
  NSNumber *number = @0;
  BOOL boolean = NO;
  NSDictionary<NSString *, NSObject *> *properties =
      @{ @"t1" : string,
         @"t2" : date,
         @"t3" : number,
         @"t4" : @(boolean),
         @"t5" : [NSNull null] };
  self.sut.properties = properties;

  // When
  NSData *serializedLog = [NSKeyedArchiver archivedDataWithRootObject:self.sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedLog];

  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([MSCustomPropertiesLog class]));
  XCTAssertTrue([self.sut isEqual:actual]);

  MSCustomPropertiesLog *log = actual;
  NSDictionary<NSString *, NSObject *> *actualProperties = log.properties;
  XCTAssertEqual(actualProperties.count, properties.count);
  for (NSString *key in actualProperties) {
    NSObject *actualValue = [actualProperties objectForKey:key];
    NSObject *value = [properties objectForKey:key];
    assertThat(actualValue, equalTo(value));
  }
}

- (void)testIsValid {

  // If
  self.sut.device = OCMClassMock([MSDevice class]);
  OCMStub([self.sut.device isValid]).andReturn(YES);
  self.sut.timestamp = [NSDate dateWithTimeIntervalSince1970:42];
  self.sut.sid = @"1234567890";

  // When
  self.sut.properties = nil;

  // Then
  XCTAssertFalse([self.sut isValid]);

  // When
  self.sut.properties = @{};

  // Then
  XCTAssertFalse([self.sut isValid]);

  // When
  self.sut.properties = @{ @"test" : @42 };

  // Then
  XCTAssertTrue([self.sut isValid]);
}

@end
