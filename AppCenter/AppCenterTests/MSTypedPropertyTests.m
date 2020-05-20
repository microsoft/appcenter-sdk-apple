// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSBooleanTypedProperty.h"
#import "MSTestFrameworks.h"
#import "MSUtility.h"

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
  NSData *serializedProperty = [MSUtility archiveKeyedData:sut];
  MSTypedProperty *actual = (MSTypedProperty *)[MSUtility unarchiveKeyedData:serializedProperty];

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
