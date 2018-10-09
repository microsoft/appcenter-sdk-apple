#import "MSBooleanTypedProperty.h"
#import "MSDateTimeTypedProperty.h"
#import "MSDoubleTypedProperty.h"
#import "MSEventProperties.h"
#import "MSEventPropertiesInternal.h"
#import "MSLongTypedProperty.h"
#import "MSSessionTrackerPrivate.h"
#import "MSStringTypedProperty.h"
#import "MSTestFrameworks.h"

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
  MSBooleanTypedProperty *property = (MSBooleanTypedProperty*)sut.properties[key];
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
  MSLongTypedProperty *property = (MSLongTypedProperty*)sut.properties[key];
  XCTAssertEqual(property.name, key);
  XCTAssertEqual(property.value, value);
}

- (void)testSetDoubleForKey {

  // If
  MSEventProperties *sut = [MSEventProperties new];
  double value = 10.43;
  NSString *key = @"key";

  // When
  [sut setDouble:value forKey:key];

  // Then
  MSDoubleTypedProperty *property = (MSDoubleTypedProperty*)sut.properties[key];
  XCTAssertEqual(property.name, key);
  XCTAssertEqual(property.value, value);
}

- (void)testSetStringForKey {

  // If
  MSEventProperties *sut = [MSEventProperties new];
  NSString *value = @"value";
  NSString *key = @"key";

  // When
  [sut setString:value forKey:key];

  // Then
  MSStringTypedProperty *property = (MSStringTypedProperty*)sut.properties[key];
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
  MSDateTimeTypedProperty *property = (MSDateTimeTypedProperty*)sut.properties[key];
  XCTAssertEqual(property.name, key);
  XCTAssertEqual(property.value, value);
}

- (void)testAppCenterCopyHas20PropertiesWhenSelfHasMoreThan20 {

  // If
  MSEventProperties *sut = [MSEventProperties new];

  // When
  for (int i = 0; i < 25; i++) {
    [sut setBool:YES forKey:[NSString stringWithFormat:@"%i", i]];
  }
  MSEventProperties *appCenterCopy = [sut createValidCopyForAppCenter];

  // Then
  XCTAssertEqual([appCenterCopy.properties count], 20);
}

- (void)testEventPropertiesHaveValidPropertiesForAppCenterWhenSutIsCopiedForAppCenter {

  // If
  MSEventProperties *sut = [MSEventProperties new];
  MSTypedProperty *property = OCMPartialMock([MSTypedProperty new]);
  MSTypedProperty *validPropertyCopy = [MSTypedProperty new];
  OCMStub([property createValidCopyForAppCenter]).andReturn(validPropertyCopy);
  NSString *propertyKey = @"key";
  sut.properties[propertyKey] = property;

  // When
  MSEventProperties *validProperties = [sut createValidCopyForAppCenter];

  // Then
  XCTAssertEqual([validProperties.properties count], [sut.properties count]);
  XCTAssertEqual(validProperties.properties[propertyKey], validPropertyCopy);
}

@end
