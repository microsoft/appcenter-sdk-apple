// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDataStorageConstants.h"
#import "MSDocumentUtils.h"
#import "MSTestFrameworks.h"

@interface MSDocumentUtilsTests : XCTestCase

@end

@implementation MSDocumentUtilsTests

- (void)testDocumentPayloadWithDocumentIdReturnsCorrectDictionary {

  // If
  NSString *documentId = @"documentId";
  NSString *partition = @"partition";
  NSDictionary *document = @{@"documentKey" : @"documentValue"};

  // When
  NSDictionary *actualDic = [MSDocumentUtils documentPayloadWithDocumentId:documentId partition:partition document:document];

  // Then
  XCTAssertEqualObjects(actualDic[kMSDocument], document);
  XCTAssertEqualObjects(actualDic[kMSPartitionKey], partition);
  XCTAssertEqualObjects(actualDic[kMSIdKey], documentId);
}

- (void)testIsReferenceDictionaryWithKeyWithNilObject {

  // If, When, Then
  XCTAssertFalse([MSDocumentUtils isReferenceDictionaryWithKey:nil key:@"test" keyType:[NSString class]]);
}

- (void)testIsReferenceDictionaryWithKeyWithNonDictionary {

  // If
  NSString *someString = @"some string";

  // When, Then
  XCTAssertFalse([MSDocumentUtils isReferenceDictionaryWithKey:someString key:@"test" keyType:[NSString class]]);
}

- (void)testIsReferenceDictionaryWithDictionary {

  // If
  NSMutableDictionary *dictionary = [NSMutableDictionary new];
  dictionary[@"string"] = @"some string";
  dictionary[@"number"] = @42;
  dictionary[@"array"] = [NSArray new];

  // When, Then
  XCTAssertTrue([MSDocumentUtils isReferenceDictionaryWithKey:dictionary key:@"string" keyType:[NSString class]]);
  XCTAssertFalse([MSDocumentUtils isReferenceDictionaryWithKey:dictionary key:@"string" keyType:[NSNumber class]]);
  XCTAssertFalse([MSDocumentUtils isReferenceDictionaryWithKey:dictionary key:@"string" keyType:[NSArray class]]);
  XCTAssertFalse([MSDocumentUtils isReferenceDictionaryWithKey:dictionary key:@"number" keyType:[NSString class]]);
  XCTAssertTrue([MSDocumentUtils isReferenceDictionaryWithKey:dictionary key:@"number" keyType:[NSNumber class]]);
  XCTAssertFalse([MSDocumentUtils isReferenceDictionaryWithKey:dictionary key:@"number" keyType:[NSArray class]]);
  XCTAssertFalse([MSDocumentUtils isReferenceDictionaryWithKey:dictionary key:@"array" keyType:[NSString class]]);
  XCTAssertFalse([MSDocumentUtils isReferenceDictionaryWithKey:dictionary key:@"array" keyType:[NSNumber class]]);
  XCTAssertTrue([MSDocumentUtils isReferenceDictionaryWithKey:dictionary key:@"array" keyType:[NSArray class]]);
}

@end
