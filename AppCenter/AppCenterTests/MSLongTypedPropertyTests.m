// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSLongTypedProperty.h"
#import "MSTestFrameworks.h"
#import "MSUtility.h"

@interface MSLongTypedPropertyTests : XCTestCase

@end

@implementation MSLongTypedPropertyTests

- (void)testNSCodingSerializationAndDeserialization {

  // If
  MSLongTypedProperty *sut = [MSLongTypedProperty new];
  sut.type = @"type";
  sut.name = @"name";
  sut.value = 12;

  // When
  NSData *serializedProperty = [MSUtility archiveKeyedData:sut];
  MSLongTypedProperty *actual = (MSLongTypedProperty *)[MSUtility unarchiveKeyedData:serializedProperty];

  // Then
  XCTAssertNotNil(actual);
  XCTAssertTrue([actual isKindOfClass:[MSLongTypedProperty class]]);
  XCTAssertEqualObjects(actual.name, sut.name);
  XCTAssertEqualObjects(actual.type, sut.type);
  XCTAssertEqual(actual.value, sut.value);
}

- (void)testSerializeToDictionary {

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

- (void)testPropertyTypeIsCorrectWhenPropertyIsInitialized {

  // If
  MSLongTypedProperty *sut = [MSLongTypedProperty new];

  // Then
  XCTAssertEqualObjects(sut.type, @"long");
}

@end
