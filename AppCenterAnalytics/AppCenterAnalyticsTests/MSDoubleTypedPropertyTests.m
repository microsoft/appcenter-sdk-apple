#import "MSDoubleTypedProperty.h"
#import "MSConstants+Internal.h"
#import "MSTestFrameworks.h"

@interface MSDoubleTypedPropertyTests : XCTestCase

@end

@implementation MSDoubleTypedPropertyTests

- (void)testNSCodingSerializationAndDeserializationWorks {

  // If
  MSDoubleTypedProperty *sut = [MSDoubleTypedProperty new];
  sut.type = @"type";
  sut.name = @"name";
  sut.value = 12.23432;

  // When
  NSData *serializedProperty = [NSKeyedArchiver archivedDataWithRootObject:sut];
  MSDoubleTypedProperty *actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedProperty];

  // Then
  XCTAssertNotNil(actual);
  XCTAssertTrue([actual isKindOfClass:[MSDoubleTypedProperty class]]);
  XCTAssertEqualObjects(actual.name, sut.name);
  XCTAssertEqualObjects(actual.type, sut.type);
  XCTAssertEqual(actual.value, sut.value);
}

- (void)testSerializeToDictionaryWorks {

  // If
  MSDoubleTypedProperty *sut = [MSDoubleTypedProperty new];
  sut.name =  @"propertyName";
  sut.value = 0.123;

  // When
  NSDictionary *dictionary = [sut serializeToDictionary];

  // Then
  XCTAssertEqualObjects(dictionary[@"type"], sut.type);
  XCTAssertEqualObjects(dictionary[@"name"], sut.name);
  XCTAssertEqual([dictionary[@"value"] doubleValue], sut.value);
}

- (void)testCreateValidCopyForAppCenterWorksWhenNameIsTooLong {

  // If
  MSDoubleTypedProperty *sut = [MSDoubleTypedProperty new];
  sut.name = [@"" stringByPaddingToLength:kMSMaxPropertyKeyLength + 2 withString:@"hi" startingAtIndex:0];
  sut.value = 12.23;

  // When
  MSDoubleTypedProperty *validCopy = [sut createValidCopyForAppCenter];

  // Then
  XCTAssertEqualObjects(validCopy.type, sut.type);
  XCTAssertEqualObjects(validCopy.name, [sut.name substringToIndex:kMSMaxPropertyKeyLength]);
  XCTAssertEqual(validCopy.value, sut.value);
}

- (void)testPropertyTypeIsCorrectWhenPropertyIsInitialized {

  // If
  MSDoubleTypedProperty *sut = [MSDoubleTypedProperty new];

  // Then
  XCTAssertEqualObjects(sut.type, @"double");
}

@end
