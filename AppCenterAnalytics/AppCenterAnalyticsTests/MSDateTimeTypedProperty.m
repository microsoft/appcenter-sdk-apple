#import "MSDateTimeTypedProperty.h"
#import "MSTestFrameworks.h"
#import "MSUtility+Date.h"

@interface MSDateTimeTypedPropertyTests : XCTestCase

@end

@implementation MSDateTimeTypedPropertyTests

- (void)testNSCodingSerializationAndDeserialization {

  // If
  MSDateTimeTypedProperty *sut = [MSDateTimeTypedProperty new];
  sut.type = @"type";
  sut.name = @"name";
  sut.value = [NSDate dateWithTimeIntervalSince1970:100000];

  // When
  NSData *serializedProperty = [NSKeyedArchiver archivedDataWithRootObject:sut];
  MSDateTimeTypedProperty *actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedProperty];

  // Then
  XCTAssertNotNil(actual);
  XCTAssertTrue([actual isKindOfClass:[MSDateTimeTypedProperty class]]);
  XCTAssertEqualObjects(actual.name, sut.name);
  XCTAssertEqualObjects(actual.type, sut.type);
  XCTAssertEqualObjects(actual.value, sut.value);
}

- (void)testSerializeToDictionary {

  // If
  MSDateTimeTypedProperty *sut = [MSDateTimeTypedProperty new];
  sut.name =  @"propertyName";
  sut.value = [NSDate dateWithTimeIntervalSince1970:100000];

  // When
  NSDictionary *dictionary = [sut serializeToDictionary];

  // Then
  XCTAssertEqualObjects(dictionary[@"type"], sut.type);
  XCTAssertEqualObjects(dictionary[@"name"], sut.name);
  XCTAssertTrue([dictionary[@"value"] isKindOfClass:[NSString class]]);
  XCTAssertEqualObjects(dictionary[@"value"], [MSUtility dateToISO8601:sut.value]);
}

- (void) testPropertyTypeIsCorrectWhenPropertyIsInitialized {

    // If
    MSDateTimeTypedProperty *sut = [MSDateTimeTypedProperty new];

    // Then
    XCTAssertEqualObjects(sut.type, @"dateTime");
  }

@end
