#import "MSStringTypedProperty.h"
#import "MSConstants+Internal.h"
#import "MSTestFrameworks.h"

@interface MSStringTypedPropertyTests : XCTestCase

@end

@implementation MSStringTypedPropertyTests

- (void)testNSCodingSerializationAndDeserializationWorks {

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

- (void)testSerializeToDictionaryWorks {

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

- (void)testCreateValidCopyForAppCenterWorksWhenNameIsTooLong {

  // If
  MSStringTypedProperty *sut = [MSStringTypedProperty new];
  sut.name = [@"" stringByPaddingToLength:kMSMaxPropertyKeyLength + 2 withString:@"hi" startingAtIndex:0];
  sut.value = @"value";

  // When
  MSStringTypedProperty *validCopy = [sut createValidCopyForAppCenter];

  // Then
  XCTAssertEqualObjects(validCopy.type, sut.type);
  XCTAssertEqualObjects(validCopy.name, [sut.name substringToIndex:kMSMaxPropertyKeyLength]);
  XCTAssertEqual(validCopy.value, sut.value);
}

- (void)testCreateValidCopyForAppCenterWorksWhenValueIsTooLong {

  // If
  MSStringTypedProperty *sut = [MSStringTypedProperty new];
  sut.name = @"name";
  sut.value = [@"" stringByPaddingToLength:kMSMaxPropertyValueLength + 2 withString:@"hi" startingAtIndex:0];

  // When
  MSStringTypedProperty *validCopy = [sut createValidCopyForAppCenter];

  // Then
  XCTAssertEqualObjects(validCopy.type, sut.type);
  XCTAssertEqualObjects(validCopy.name, sut.name);
  XCTAssertEqual(validCopy.value, [sut.value substringToIndex:kMSMaxPropertyValueLength]);
}

- (void)testPropertyTypeIsCorrectWhenPropertyIsInitialized {

  // If
  MSStringTypedProperty *sut = [MSStringTypedProperty new];

  // Then
  XCTAssertEqualObjects(sut.type, @"string");
}

@end
