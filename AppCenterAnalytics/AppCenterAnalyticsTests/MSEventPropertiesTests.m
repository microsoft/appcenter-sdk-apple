#import "MSConstants+Internal.h"
#import "MSEventProperties.h"
#import "MSEventPropertiesInternal.h"
#import "MSTestFrameworks.h"
#import "MSTypedProperty.h"

@interface MSEventPropertiesTests : XCTestCase

@end

@implementation MSEventPropertiesTests

- (void)testSetBoolForKey {

  // If
  MSEventProperties *sut = [MSEventProperties new];
  BOOL value = YES;
  NSString *key = @"key";

  // When
  [sut setBool:value forKey:key];

  // Then
  MSTypedProperty *property = sut.properties[key];
  XCTAssertEqualObjects(property.name, key);
  XCTAssertEqualObjects(property.value, @(value));
  XCTAssertEqualObjects(property.type, kMSPropertyTypeBoolean);
}

- (void)testSetInt64ForKey {

  // If
  MSEventProperties *sut = [MSEventProperties new];
  int64_t value = 10;
  NSString *key = @"key";
  NSString *type = @"long";

  // When
  [sut setInt64:value forKey:key];

  // Then
  MSTypedProperty *property = sut.properties[key];
  XCTAssertEqualObjects(property.name, key);
  XCTAssertEqualObjects(property.value, @(value));
  XCTAssertEqualObjects(property.type, type);
}

- (void)testSetDoubleForKey {

  // If
  MSEventProperties *sut = [MSEventProperties new];
  double value = 10.43;
  NSString *key = @"key";
  NSString *type = @"double";
  // When
  [sut setDouble:value forKey:key];

  // Then
  MSTypedProperty *property = sut.properties[key];
  XCTAssertEqualObjects(property.name, key);
  XCTAssertEqualObjects(property.value, @(value));
  XCTAssertEqualObjects(property.type, type);
}

- (void)testSetDoubleForKeyWhenValueIsInfinity {

  // If
  MSEventProperties *sut = [MSEventProperties new];

  // When
  [sut setDouble:INFINITY forKey:@"key"];

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
  MSTypedProperty *property = sut.properties[key];
  XCTAssertEqualObjects(property.name, key);
  XCTAssertEqualObjects(property.value, value);
  XCTAssertEqualObjects(property.type, kMSPropertyTypeString);
}

- (void)testSetDateForKey {

  // If
  MSEventProperties *sut = [MSEventProperties new];
  NSDate *value = [NSDate new];
  NSString *key = @"key";

  // When
  [sut setDate:value forKey:key];

  // Then
  MSTypedProperty *property = sut.properties[key];
  XCTAssertEqualObjects(property.name, key);
  XCTAssertEqualObjects(property.value, value);
  XCTAssertEqualObjects(property.type, kMSPropertyTypeDateTime);
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


- (void)testNSCodingSerializationAndDeserializationWorks {

  // If
  MSEventProperties *sut = [MSEventProperties new];
  [sut setString:@"stringVal" forKey:@"stringKey"];
  [sut setBool:YES forKey:@"boolKey"];
  [sut setDouble:1.4 forKey:@"doubleKey"];
  [sut setInt64:43 forKey:@"intKey"];
  [sut setDate:[NSDate new] forKey:@"dateKey"];

  // When
  NSData *serializedSut = [NSKeyedArchiver archivedDataWithRootObject:sut];
  MSEventProperties *deserializedSut = [NSKeyedUnarchiver unarchiveObjectWithData:serializedSut];

  // Then
  assertThat(deserializedSut, notNilValue());
  assertThat(deserializedSut, instanceOf([MSEventProperties class]));
  for (NSString *key in sut.properties) {
    MSTypedProperty *sutProperty = sut.properties[key];
    MSTypedProperty *deserializedSutProperty = deserializedSut.properties[key];
    XCTAssertEqualObjects(sutProperty.name, deserializedSutProperty.name);
    XCTAssertEqualObjects(sutProperty.type, deserializedSutProperty.type);
    XCTAssertEqualObjects(sutProperty.value, deserializedSutProperty.value);
  }
}
@end
