// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDoubleTypedProperty.h"
#import "MSTestFrameworks.h"
#import "MSUtility.h"

@interface MSDoubleTypedPropertyTests : XCTestCase

@end

@implementation MSDoubleTypedPropertyTests

- (void)testNSCodingSerializationAndDeserialization {

  // If
  MSDoubleTypedProperty *sut = [MSDoubleTypedProperty new];
  sut.type = @"type";
  sut.name = @"name";
  sut.value = 12.23432;

  // When
  NSData *serializedProperty = [MSUtility archiveKeyedData:sut];
  MSDoubleTypedProperty *actual = (MSDoubleTypedProperty *)[MSUtility unarchiveKeyedData:serializedProperty];

  // Then
  XCTAssertNotNil(actual);
  XCTAssertTrue([actual isKindOfClass:[MSDoubleTypedProperty class]]);
  XCTAssertEqualObjects(actual.name, sut.name);
  XCTAssertEqualObjects(actual.type, sut.type);
  XCTAssertEqual(actual.value, sut.value);
}

- (void)testSerializeToDictionary {

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

- (void)testPropertyTypeIsCorrectWhenPropertyIsInitialized {

  // If
  MSDoubleTypedProperty *sut = [MSDoubleTypedProperty new];

  // Then
  XCTAssertEqualObjects(sut.type, @"double");
}

@end
