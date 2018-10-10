#import "MSTypedProperty.h"
#import "MSTestFrameworks.h"
#import "MSUtility+Date.h"

@interface MSTypedPropertyTests : XCTestCase

@end

@implementation MSTypedPropertyTests

- (void)testNSCodingSerializationAndDeserializationWorks {

  // If
  MSTypedProperty *sut = [MSTypedProperty new];
  sut.type = @"propertyType";
  sut.name = @"propertyName";
  sut.value = @"some value";

  // When
  NSData *serializedProperty = [NSKeyedArchiver archivedDataWithRootObject:sut];
  MSTypedProperty *actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedProperty];

  // Then
  XCTAssertNotNil(actual);
  XCTAssertTrue([actual isKindOfClass:[MSTypedProperty class]]);
  XCTAssertEqualObjects(actual.name, sut.name);
  XCTAssertEqualObjects(actual.type, sut.type);
  XCTAssertEqualObjects(actual.value, sut.value);
}

- (void)testSerializingTypedPropertyToDictionaryWorks {

  // If
  MSTypedProperty *sut = [MSTypedProperty new];
  sut.type =  @"propertyType";
  sut.name = @"propertyName";
  sut.value = @"some value";

  // When
  NSMutableDictionary *actual = [sut serializeToDictionary];

  // Then
  XCTAssertEqualObjects(actual[@"type"], sut.type);
  XCTAssertEqualObjects(actual[@"name"], sut.name);
  XCTAssertEqualObjects(actual[@"value"], sut.value);
}

- (void)testCreateStringPropertyUsesCorrectTypeValue {

  // If
  MSTypedProperty *sut = [MSTypedProperty stringTypedProperty];

  // Then
  XCTAssertEqualObjects(sut.type, @"string");
}

- (void)testCreateLongPropertyUsesCorrectTypeValue {

  // If
  MSTypedProperty *sut = [MSTypedProperty longTypedProperty];

  // Then
  XCTAssertEqualObjects(sut.type, @"long");
}

- (void)testCreateBooleanPropertyUsesCorrectTypeValue {

  // If
  MSTypedProperty *sut = [MSTypedProperty boolTypedProperty];

  // Then
  XCTAssertEqualObjects(sut.type, @"boolean");
}

- (void)testCreateDatePropertyUsesCorrectTypeValue {

  // If
  MSTypedProperty *sut = [MSTypedProperty dateTypedProperty];

  // Then
  XCTAssertEqualObjects(sut.type, @"dateTime");
}

- (void)testCreateDoublePropertyUsesCorrectTypeValue {

  // If
  MSTypedProperty *sut = [MSTypedProperty doubleTypedProperty];

  // Then
  XCTAssertEqualObjects(sut.type, @"double");
}

- (void)testDateIsSerializedAsStringWhenSerializingToDictionary {

  // If
  MSTypedProperty *sut = [MSTypedProperty new];
  sut.type =  @"dateTime";
  sut.name = @"propertyName";
  sut.value = [NSDate new];

  // When
  NSMutableDictionary *actual = [sut serializeToDictionary];

  // Then
  XCTAssertEqualObjects(actual[@"type"], sut.type);
  XCTAssertEqualObjects(actual[@"name"], sut.name);
  XCTAssertEqualObjects(actual[@"value"], [MSUtility dateToISO8601:(NSDate *)sut.value]);
}

@end
