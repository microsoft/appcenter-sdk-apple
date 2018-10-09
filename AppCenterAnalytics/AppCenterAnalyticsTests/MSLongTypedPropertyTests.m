#import "MSLongTypedProperty.h"
#import "MSConstants+Internal.h"
#import "MSTestFrameworks.h"

@interface MSLongTypedPropertyTests : XCTestCase

@end

@implementation MSLongTypedPropertyTests

- (void)testNSCodingSerializationAndDeserializationWorks {

  // If
  MSLongTypedProperty *sut = [MSLongTypedProperty new];
  sut.type = @"type";
  sut.name = @"name";
  sut.value = 12;

  // When
  NSData *serializedProperty = [NSKeyedArchiver archivedDataWithRootObject:sut];
  MSLongTypedProperty *actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedProperty];

  // Then
  XCTAssertNotNil(actual);
  XCTAssertTrue([actual isKindOfClass:[MSLongTypedProperty class]]);
  XCTAssertEqualObjects(actual.name, sut.name);
  XCTAssertEqualObjects(actual.type, sut.type);
  XCTAssertEqual(actual.value, sut.value);
}

- (void)testSerializeToDictionaryWorks {

  // If
  MSLongTypedProperty *sut = [MSLongTypedProperty new];
  sut.name =  @"propertyName";
  sut.value = 12;

  // When
  NSDictionary *dictionary = [sut serializeToDictionary];

  // Then
  XCTAssertEqualObjects(dictionary[@"type"], sut.type);
  XCTAssertEqualObjects(dictionary[@"name"], sut.name);
  XCTAssertEqual([dictionary[@"value"] longLongValue], sut.value);
}

- (void)testCreateValidCopyForAppCenterWorksWhenNameIsTooLong {

  // If
  MSLongTypedProperty *sut = [MSLongTypedProperty new];
  sut.name = [@"" stringByPaddingToLength:kMSMaxPropertyKeyLength + 2 withString:@"hi" startingAtIndex:0];
  sut.value = 12;

  // When
  MSLongTypedProperty *validCopy = [sut createValidCopyForAppCenter];

  // Then
  XCTAssertEqualObjects(validCopy.type, sut.type);
  XCTAssertEqualObjects(validCopy.name, [sut.name substringToIndex:kMSMaxPropertyKeyLength]);
  XCTAssertEqual(validCopy.value, sut.value);
}

- (void)testPropertyTypeIsCorrectWhenPropertyIsInitialized {

  // If
  MSLongTypedProperty *sut = [MSLongTypedProperty new];

  // Then
  XCTAssertEqualObjects(sut.type, @"long");
}

@end
