#import "MSBooleanTypedProperty.h"
#import "MSTestFrameworks.h"

@interface MSBooleanTypedPropertyTests : XCTestCase

@end

@implementation MSBooleanTypedPropertyTests

- (void)testSerializeToDictionary {

  // If
  MSBooleanTypedProperty *sut = [MSBooleanTypedProperty new];
  sut.name =  @"propertyName";
  sut.value = YES;

  // When
  NSDictionary *dictionary = [sut serializeToDictionary];

  // Then
  XCTAssertEqualObjects(dictionary[@"type"], sut.type);
  XCTAssertEqualObjects(dictionary[@"name"], sut.name);
  XCTAssertEqual([dictionary[@"value"] boolValue], sut.value);
}

- (void)testNSCodingSerializationAndDeserialization {

  // If
  MSBooleanTypedProperty *sut = [MSBooleanTypedProperty new];
  sut.type = @"type";
  sut.name = @"name";
  sut.value = YES;

  // When
  NSData *serializedProperty = [NSKeyedArchiver archivedDataWithRootObject:sut];
  MSBooleanTypedProperty *actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedProperty];

  // Then
  XCTAssertNotNil(actual);
  XCTAssertTrue([actual isKindOfClass:[MSBooleanTypedProperty class]]);
  XCTAssertEqualObjects(actual.name, sut.name);
  XCTAssertEqualObjects(actual.type, sut.type);
  XCTAssertEqual(actual.value, sut.value);
}

- (void)testPropertyTypeIsCorrectWhenPropertyIsInitialized {

  // If
  MSBooleanTypedProperty *sut = [MSBooleanTypedProperty new];

  // Then
  XCTAssertEqualObjects(sut.type, @"boolean");
}

@end
