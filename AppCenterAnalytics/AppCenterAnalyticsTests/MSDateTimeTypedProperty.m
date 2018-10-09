#import "MSDateTimeTypedProperty.h"
#import "MSConstants+Internal.h"
#import "MSTestFrameworks.h"

@interface MSDateTimeTypedPropertyTests : XCTestCase

@end

@implementation MSDateTimeTypedPropertyTests

- (void)testNSCodingSerializationAndDeserializationWorks {

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

- (void)testSerializeToDictionaryWorks {

  // If
  MSDateTimeTypedProperty *sut = [MSDateTimeTypedProperty new];
  sut.name =  @"propertyName";
  sut.value = [NSDate dateWithTimeIntervalSince1970:100000];

  // When
  NSDictionary *dictionary = [sut serializeToDictionary];

  // Then
  XCTAssertEqualObjects(dictionary[@"type"], sut.type);
  XCTAssertEqualObjects(dictionary[@"name"], sut.name);
  XCTAssertEqualObjects(dictionary[@"value"], sut.value);
}

- (void)testCreateValidCopyForAppCenterWorksWhenNameIsTooLong {

  // If
  MSDateTimeTypedProperty *sut = [MSDateTimeTypedProperty new];
  sut.name = [@"" stringByPaddingToLength:kMSMaxPropertyKeyLength + 2 withString:@"hi" startingAtIndex:0];
  sut.value = [NSDate dateWithTimeIntervalSince1970:100000];

  // When
  MSDateTimeTypedProperty *validCopy = [sut createValidCopyForAppCenter];

  // Then
  XCTAssertEqualObjects(validCopy.type, sut.type);
  XCTAssertEqualObjects(validCopy.name, [sut.name substringToIndex:kMSMaxPropertyKeyLength]);
  XCTAssertEqualObjects(validCopy.value, sut.value);
}

- (void)testPropertyTypeIsCorrectWhenPropertyIsInitialized {

  // If
  MSDateTimeTypedProperty *sut = [MSDateTimeTypedProperty new];

  // Then
  XCTAssertEqualObjects(sut.type, @"dateTime");
}

@end
