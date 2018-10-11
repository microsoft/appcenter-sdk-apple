#import "MSStringTypedProperty.h"
#import "MSTestFrameworks.h"

@interface MSStringTypedPropertyTests : XCTestCase

@end

@implementation MSStringTypedPropertyTests

- (void)testNSCodingSerializationAndDeserialization {

  // If
  MSStringTypedProperty *sut = [MSStringTypedProperty new];
  sut.type = @"type";
  sut.name = @"name";
  sut.value = @"value";

  // When
  NSData *serializedProperty = [NSKeyedArchiver archivedDataWithRootObject:sut];
  MSStringTypedProperty *actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedProperty];

  // Then
  XCTAssertNotNil(actual);
  XCTAssertTrue([actual isKindOfClass:[MSStringTypedProperty class]]);
  XCTAssertEqualObjects(actual.name, sut.name);
  XCTAssertEqualObjects(actual.type, sut.type);
  XCTAssertEqualObjects(actual.value, sut.value);
}

- (void)testSerializeToDictionary {

  // If
  MSStringTypedProperty *sut = [MSStringTypedProperty new];
  sut.name =  @"propertyName";
  sut.value = @"value";

  // When
  NSDictionary *dictionary = [sut serializeToDictionary];

  // Then
  XCTAssertEqualObjects(dictionary[@"type"], sut.type);
  XCTAssertEqualObjects(dictionary[@"name"], sut.name);
  XCTAssertEqualObjects(dictionary[@"value"], sut.value);
}


- (void)testPropertyTypeIsCorrectWhenPropertyIsInitialized {

  // If
  MSStringTypedProperty *sut = [MSStringTypedProperty new];

  // Then
  XCTAssertEqualObjects(sut.type, @"string");
}

@end
