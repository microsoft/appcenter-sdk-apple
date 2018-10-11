#import "MSBooleanTypedProperty.h"
#import "MSTestFrameworks.h"

@interface MSTypedPropertyTests : XCTestCase

@end

@implementation MSTypedPropertyTests

- (void)testNSCodingSerializationAndDeserialization {

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

- (void)testSerializingTypedPropertyToDictionary {

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

@end
