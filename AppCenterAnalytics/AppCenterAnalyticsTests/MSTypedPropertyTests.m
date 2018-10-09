#import "MSTypedProperty.h"
#import "MSTestFrameworks.h"

@interface MSTypedPropertyTests : XCTestCase

@end

@implementation MSTypedPropertyTests

- (void)testNSCodingSerializationAndDeserializationWorks {

  // If
  NSString *propertyType = @"propertyType";
  NSString *propertyName = @"propertyName";
  MSTypedProperty *sut = [MSTypedProperty new];
  sut.type = propertyType;
  sut.name = propertyName;

  // When
  NSData *serializedProperty = [NSKeyedArchiver archivedDataWithRootObject:sut];
  MSTypedProperty *actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedProperty];

  // Then
  XCTAssertNotNil(actual);
  XCTAssertTrue([actual isKindOfClass:[MSTypedProperty class]]);
  XCTAssertEqualObjects(actual.name, propertyName);
  XCTAssertEqualObjects(actual.type, propertyType);
}

- (void)testSerializingTypedPropertyToDictionaryWorks {

  // If
  NSString *propertyType = @"propertyType";
  NSString *propertyName = @"propertyName";
  MSTypedProperty *sut = [MSTypedProperty new];
  sut.type = propertyType;
  sut.name = propertyName;

  // When
  NSMutableDictionary *actual = [sut serializeToDictionary];

  // Then
  XCTAssertEqualObjects(actual[@"type"], sut.type);
  XCTAssertEqualObjects(actual[@"name"], sut.name);
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

@end
