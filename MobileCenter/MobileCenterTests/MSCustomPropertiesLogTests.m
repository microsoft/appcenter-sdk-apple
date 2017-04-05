#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <XCTest/XCTest.h>

#import "MSCustomPropertiesLog.h"

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
  BOOL boolean = NO;
  NSDictionary<NSString *, NSObject *> *properties = @{@"t1": string,
                                                       @"t2": date,
                                                       @"t3": number,
                                                       @"t4": @(boolean),
                                                       @"t5": [NSNull null],
                                                       @"t6": [NSData new]};
  self.sut.properties = properties;
  
  // When
  NSMutableDictionary *actual = [self.sut serializeToDictionary];
  
  // Then
  assertThat(actual, notNilValue());
  NSArray *actualProperties = actual[@"properties"];
  assertThat(actualProperties, hasCountOf(5));
}

- (void)testNSCodingSerializationAndDeserializationWorks {
  
  // If
  NSString *string = @"test";
  NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
  NSNumber *number = @0;
  BOOL boolean = NO;
  NSDictionary<NSString *, NSObject *> *properties = @{@"t1": string,
                                                       @"t2": date,
                                                       @"t3": number,
                                                       @"t4": @(boolean),
                                                       @"t5": [NSNull null]};
  self.sut.properties = properties;
  
  // When
  NSData *serializedLog = [NSKeyedArchiver archivedDataWithRootObject:self.sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedLog];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([MSCustomPropertiesLog class]));
  
  MSCustomPropertiesLog *log = actual;
  NSDictionary<NSString *, NSObject *> *actualProperties = log.properties;
  XCTAssertEqual(actualProperties.count, properties.count);
  for (NSString *key in actualProperties) {
    NSObject *actualValue = [actualProperties objectForKey:key];
    NSObject *value = [properties objectForKey:key];
    assertThat(actualValue, equalTo(value));
  }
}

@end
