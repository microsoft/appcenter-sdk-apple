#import "MSBooleanTypedProperty.h"
#import "MSDateTimeTypedProperty.h"
#import "MSDoubleTypedProperty.h"
#import "MSEventProperties.h"
#import "MSEventPropertiesInternal.h"
#import "MSLongTypedProperty.h"
#import "MSStringTypedProperty.h"
#import "MSTestFrameworks.h"
#import "MSUtility+Date.h"

@interface MSEventPropertiesTests : XCTestCase

@end

@implementation MSEventPropertiesTests

- (void)testInitWithStringDictionaryWhenStringDictionaryHasValues {

  // If
  NSDictionary *stringProperties = @{ @"key1" : @"val1", @"key2" : @"val2" };

  // When
  MSEventProperties *sut = [[MSEventProperties alloc] initWithStringDictionary:stringProperties];

  // Then
  XCTAssertEqual([sut.properties count], 2);
  for (NSString *propertyKey in stringProperties) {
    XCTAssertTrue([sut.properties[propertyKey] isKindOfClass:[MSStringTypedProperty class]]);
    XCTAssertEqualObjects(stringProperties[propertyKey], ((MSStringTypedProperty *)sut.properties[propertyKey]).value);
    XCTAssertEqualObjects(propertyKey, sut.properties[propertyKey].name);
  }
}

- (void)testSetBoolForKey {

  // If
  MSEventProperties *sut = [MSEventProperties new];
  BOOL value = YES;
  NSString *key = @"key";

  // When
  [sut setBool:value forKey:key];

  // Then
  MSBooleanTypedProperty *property = (MSBooleanTypedProperty *)sut.properties[key];
  XCTAssertEqual(property.name, key);
  XCTAssertEqual(property.value, value);
}

- (void)testSetInt64ForKey {

  // If
  MSEventProperties *sut = [MSEventProperties new];
  int64_t value = 10;
  NSString *key = @"key";

  // When
  [sut setInt64:value forKey:key];

  // Then
  MSLongTypedProperty *property = (MSLongTypedProperty *)sut.properties[key];
  XCTAssertEqual(property.name, key);
  XCTAssertEqual(property.value, value);
}

- (void)testSetDoubleForKey {

  // If
  MSEventProperties *sut = [MSEventProperties new];
  double value = 10.43e3;
  NSString *key = @"key";

  // When
  [sut setDouble:value forKey:key];

  // Then
  MSDoubleTypedProperty *property = (MSDoubleTypedProperty *)sut.properties[key];
  XCTAssertEqual(property.name, key);
  XCTAssertEqual(property.value, value);
}

- (void)testSetDoubleForKeyWhenValueIsInfinity {

  // If
  MSEventProperties *sut = [MSEventProperties new];

  // When
  [sut setDouble:INFINITY forKey:@"key"];

  // Then
  XCTAssertEqual([sut.properties count], 0);

  // When
  [sut setDouble:-INFINITY forKey:@"key"];

  // Then
  XCTAssertEqual([sut.properties count], 0);
}

- (void)testSetDoubleForKeyWhenValueIsNaN {

  // If
  MSEventProperties *sut = [MSEventProperties new];

  // When
  [sut setDouble:NAN forKey:@"key"];

  // Then
  XCTAssertEqual([sut.properties count], 0);
}

- (void)testSetStringForKey {

  // If
  MSEventProperties *sut = [MSEventProperties new];
  NSString *value = @"value";
  NSString *key = @"key";

  // When
  [sut setString:value forKey:key];

  // Then
  MSStringTypedProperty *property = (MSStringTypedProperty *)sut.properties[key];
  XCTAssertEqual(property.name, key);
  XCTAssertEqual(property.value, value);
}

- (void)testSetDateForKey {

  // If
  MSEventProperties *sut = [MSEventProperties new];
  NSDate *value = [NSDate new];
  NSString *key = @"key";

  // When
  [sut setDate:value forKey:key];

  // Then
  MSDateTimeTypedProperty *property = (MSDateTimeTypedProperty *)sut.properties[key];
  XCTAssertEqual(property.name, key);
  XCTAssertEqual(property.value, value);
}

- (void)testSerializeToArray {

  // If
  MSEventProperties *sut = [MSEventProperties new];
  MSTypedProperty *property = OCMPartialMock([MSTypedProperty new]);
  NSDictionary *serializedProperty = [NSDictionary new];
  OCMStub([property serializeToDictionary]).andReturn(serializedProperty);
  NSString *propertyKey = @"key";
  sut.properties[propertyKey] = property;

  // When
  NSArray *propertiesArray = [sut serializeToArray];

  // Then
  XCTAssertEqual([propertiesArray count], 1);
  XCTAssertEqualObjects(propertiesArray[0], serializedProperty);
}

- (void)testNSCodingSerializationAndDeserialization {

  // If
  MSEventProperties *sut = [MSEventProperties new];
  [sut setString:@"stringVal" forKey:@"stringKey"];
  [sut setBool:YES forKey:@"boolKey"];
  [sut setDouble:1.4 forKey:@"doubleKey"];
  [sut setInt64:8589934592ll forKey:@"intKey"];
  [sut setDate:[NSDate new] forKey:@"dateKey"];

  // When
  NSData *serializedSut = [NSKeyedArchiver archivedDataWithRootObject:sut];
  MSEventProperties *deserializedSut = [NSKeyedUnarchiver unarchiveObjectWithData:serializedSut];

  // Then
  XCTAssertNotNil(deserializedSut);
  XCTAssertTrue([deserializedSut isKindOfClass:[MSEventProperties class]]);
  for (NSString *key in sut.properties) {
    MSTypedProperty *sutProperty = sut.properties[key];
    MSTypedProperty *deserializedSutProperty = deserializedSut.properties[key];
    XCTAssertEqualObjects(sutProperty.name, deserializedSutProperty.name);
    XCTAssertEqualObjects(sutProperty.type, deserializedSutProperty.type);
    if ([deserializedSutProperty isKindOfClass:[MSStringTypedProperty class]]) {
      MSStringTypedProperty *deserializedProperty = (MSStringTypedProperty *)deserializedSutProperty;
      MSStringTypedProperty *originalProperty = (MSStringTypedProperty *)sutProperty;
      XCTAssertEqualObjects(originalProperty.value, deserializedProperty.value);
    } else if ([deserializedSutProperty isKindOfClass:[MSBooleanTypedProperty class]]) {
      MSBooleanTypedProperty *deserializedProperty = (MSBooleanTypedProperty *)deserializedSutProperty;
      MSBooleanTypedProperty *originalProperty = (MSBooleanTypedProperty *)sutProperty;
      XCTAssertEqual(originalProperty.value, deserializedProperty.value);
    } else if ([deserializedSutProperty isKindOfClass:[MSLongTypedProperty class]]) {
      MSLongTypedProperty *deserializedProperty = (MSLongTypedProperty *)deserializedSutProperty;
      MSLongTypedProperty *originalProperty = (MSLongTypedProperty *)sutProperty;
      XCTAssertEqual(originalProperty.value, deserializedProperty.value);
    } else if ([deserializedSutProperty isKindOfClass:[MSDoubleTypedProperty class]]) {
      MSDoubleTypedProperty *deserializedProperty = (MSDoubleTypedProperty *)deserializedSutProperty;
      MSDoubleTypedProperty *originalProperty = (MSDoubleTypedProperty *)sutProperty;
      XCTAssertEqual(originalProperty.value, deserializedProperty.value);
    } else if ([deserializedSutProperty isKindOfClass:[MSDateTimeTypedProperty class]]) {
      MSDateTimeTypedProperty *deserializedProperty = (MSDateTimeTypedProperty *)deserializedSutProperty;
      MSDateTimeTypedProperty *originalProperty = (MSDateTimeTypedProperty *)sutProperty;
      NSString *originalDateString = [MSUtility dateToISO8601:originalProperty.value];
      NSString *deserializedDateString = [MSUtility dateToISO8601:deserializedProperty.value];
      XCTAssertEqualObjects(originalDateString, deserializedDateString);
    }
  }
}

- (void)testIsEmptyReturnsTrueWhenContainsNoProperties {

  // If
  MSEventProperties *sut = [MSEventProperties new];

  // When
  BOOL isEmpty = [sut isEmpty];

  // Then
  XCTAssertTrue(isEmpty);
}

- (void)testIsEmptyReturnsFalseWhenContainsProperties {

  // If
  MSEventProperties *sut = [MSEventProperties new];
  [sut setBool:YES forKey:@"key"];

  // When
  BOOL isEmpty = [sut isEmpty];

  // Then
  XCTAssertFalse(isEmpty);
}

@end
