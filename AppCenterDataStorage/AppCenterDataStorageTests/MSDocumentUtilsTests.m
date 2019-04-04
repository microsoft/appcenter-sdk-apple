// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDataSourceError.h"
#import "MSDataStorageConstants.h"
#import "MSDocumentUtils.h"
#import "MSTestDocument.h"
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

- (void)testDocumentWrapperFromDictionaryWithInvalidReference {

  // If
  NSString *badReference = @"bad reference";

  // When
  MSDocumentWrapper *document = [MSDocumentUtils documentWrapperFromDictionary:badReference documentType:[NSString class]];

  // Then
  XCTAssertNotNil(document);
  XCTAssertNotNil([document error]);
  XCTAssertNil([document documentId]);
  XCTAssertNil([document deserializedValue]);
  XCTAssertNil([document eTag]);
  XCTAssertNil([document lastUpdatedDate]);
  XCTAssertNil([document partition]);
  XCTAssertNil([document jsonValue]);
}

- (void)testDocumentWrapperFromDictionaryWithSystemPropertiesAndPartition {

  // If
  NSMutableDictionary *dictionary = [NSMutableDictionary new];
  dictionary[@"id"] = @"document-id";
  dictionary[@"_etag"] = @"etag";
  dictionary[@"_ts"] = @0;
  dictionary[@"PartitionKey"] = @"readonly";

  // When
  MSDocumentWrapper *document = [MSDocumentUtils documentWrapperFromDictionary:dictionary documentType:[NSString class]];

  // Then
  XCTAssertNotNil(document);
  XCTAssertNotNil([document error]);
  XCTAssertTrue([[document documentId] isEqualToString:@"document-id"]);
  XCTAssertNil([document deserializedValue]);
  XCTAssertTrue([[document eTag] isEqualToString:@"etag"]);
  XCTAssertNotNil([document lastUpdatedDate]);
  XCTAssertTrue([[document partition] isEqualToString:@"readonly"]);
  XCTAssertNotNil([document jsonValue]);

  // If, system property has incorrect type
  dictionary[@"_ts"] = @"some unexpected timestamp";

  // When
  document = [MSDocumentUtils documentWrapperFromDictionary:dictionary documentType:[NSString class]];

  // Then
  XCTAssertNotNil(document);
  XCTAssertNotNil([document error]);
  XCTAssertNil([document documentId]);
  XCTAssertNil([document deserializedValue]);
  XCTAssertNil([document eTag]);
  XCTAssertNil([document lastUpdatedDate]);
  XCTAssertNil([document partition]);
  XCTAssertNil([document jsonValue]);
}

- (void)testDocumentWrapperFromDictionaryWithDocument {

  // If
  NSMutableDictionary *dictionary = [NSMutableDictionary new];
  dictionary[@"id"] = @"document-id";
  dictionary[@"_etag"] = @"etag";
  dictionary[@"_ts"] = @0;
  dictionary[@"PartitionKey"] = @"readonly";
  dictionary[@"document"] = @"this should be a dictionary";

  // When
  MSDocumentWrapper *document = [MSDocumentUtils documentWrapperFromDictionary:dictionary documentType:[NSString class]];

  // Then
  XCTAssertNotNil(document);
  XCTAssertNotNil([document error]);
  XCTAssertTrue([[document documentId] isEqualToString:@"document-id"]);
  XCTAssertNil([document deserializedValue]);
  XCTAssertTrue([[document eTag] isEqualToString:@"etag"]);
  XCTAssertNotNil([document lastUpdatedDate]);
  XCTAssertTrue([[document partition] isEqualToString:@"readonly"]);
  XCTAssertNotNil([document jsonValue]);

  // If, document is a dictionary
  dictionary[@"document"] = [NSMutableDictionary new];
  dictionary[@"document"][@"property1"] = @"first property";
  dictionary[@"document"][@"property2"] = @123;

  // When
  document = [MSDocumentUtils documentWrapperFromDictionary:dictionary documentType:[MSTestDocument class]];

  // Then
  XCTAssertNotNil(document);
  XCTAssertNil([document error]);
  XCTAssertTrue([[document documentId] isEqualToString:@"document-id"]);
  XCTAssertNotNil([document deserializedValue]);
  XCTAssertTrue([[[document deserializedValue] property1] isEqualToString:@"first property"]);
  XCTAssertTrue([[[document deserializedValue] property2] isEqualToNumber:@123]);
  XCTAssertTrue([[document eTag] isEqualToString:@"etag"]);
  XCTAssertNotNil([document lastUpdatedDate]);
  XCTAssertTrue([[document partition] isEqualToString:@"readonly"]);
  XCTAssertNotNil([document jsonValue]);
}

- (void)testDocumentWrapperFromDataNull {

  // If
  NSData *data;

  // When
  MSDocumentWrapper *document = [MSDocumentUtils documentWrapperFromData:data documentType:[NSString class]];

  // Then
  XCTAssertNotNil(document);
  XCTAssertNotNil([document error]);
  XCTAssertNil([document documentId]);
  XCTAssertNil([document deserializedValue]);
  XCTAssertNil([document eTag]);
  XCTAssertNil([document lastUpdatedDate]);
  XCTAssertNil([document partition]);
  XCTAssertNil([document jsonValue]);
}

- (void)testDocumentWrapperFromDataFixture {

  // If
  NSData *data;

  // When
  MSDocumentWrapper *document = [MSDocumentUtils documentWrapperFromData:data documentType:[NSString class]];

  // Then
  XCTAssertNotNil(document);
  XCTAssertNotNil([document error]);
  XCTAssertNil([document documentId]);
  XCTAssertNil([document deserializedValue]);
  XCTAssertNil([document eTag]);
  XCTAssertNil([document lastUpdatedDate]);
  XCTAssertNil([document partition]);
  XCTAssertNil([document jsonValue]);

  // If, data is set to a valid document
  data = [MSTestDocument getDocumentFixture:@"validTestDocument"];

  // When
  document = [MSDocumentUtils documentWrapperFromData:data documentType:[MSTestDocument class]];

  // Then
  XCTAssertNotNil(document);
  XCTAssertNil([document error]);
  XCTAssertTrue([[document documentId] isEqualToString:@"standalonedocument1"]);
  XCTAssertNotNil([document deserializedValue]);
  XCTAssertTrue([[[document deserializedValue] property1] isEqualToString:@"property number 1"]);
  XCTAssertTrue([[[document deserializedValue] property2] isEqualToNumber:@123]);
  XCTAssertTrue([[document eTag] isEqualToString:@"etag value"]);
  XCTAssertNotNil([document lastUpdatedDate]);
  XCTAssertTrue([[document partition] isEqualToString:@"readonly"]);
  XCTAssertNotNil([document jsonValue]);
}

@end
