// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSData.h"
#import "MSDataConstants.h"
#import "MSDataError.h"
#import "MSDataErrors.h"
#import "MSDictionaryDocument.h"
#import "MSDocumentUtils.h"
#import "MSTestFrameworks.h"
#import "MSUtility+Date.h"
#import "NSObject+MSTestFixture.h"

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
  MSDocumentWrapper *document = [MSDocumentUtils documentWrapperFromDictionary:badReference
                                                                  documentType:[NSString class]
                                                               fromDeviceCache:NO];

  // Then
  XCTAssertNotNil(document);
  XCTAssertNotNil([document error]);
  XCTAssertNil([document documentId]);
  XCTAssertNil([document deserializedValue]);
  XCTAssertNil([document eTag]);
  XCTAssertNil([document lastUpdatedDate]);
  XCTAssertNil([document partition]);
  XCTAssertNil([document jsonValue]);
  XCTAssertFalse([document fromDeviceCache]);
}

- (void)testDocumentWrapperFromDictionaryWithDocument {

  // If
  NSMutableDictionary *dictionary = [NSMutableDictionary new];
  dictionary[@"id"] = @"document-id";
  dictionary[@"_etag"] = @"etag";
  dictionary[@"_ts"] = @0;
  dictionary[@"PartitionKey"] = @"readonly";

  // Invalid JSON
  dictionary[@"document"] = @{@"key" : [NSDate new]};

  // When
  MSDocumentWrapper *document = [MSDocumentUtils documentWrapperFromDictionary:dictionary documentType:[NSString class] fromDeviceCache:NO];

  // Then
  XCTAssertNotNil(document);
  XCTAssertNotNil([document error]);
  XCTAssertTrue([[document documentId] isEqualToString:@"document-id"]);
  XCTAssertNil([document deserializedValue]);
  XCTAssertTrue([[document eTag] isEqualToString:@"etag"]);
  XCTAssertNotNil([document lastUpdatedDate]);
  XCTAssertTrue([[document partition] isEqualToString:@"readonly"]);
  XCTAssertNil([document jsonValue]);
  XCTAssertFalse([document fromDeviceCache]);

  // If, document is a dictionary
  dictionary[@"document"] = [NSMutableDictionary new];
  dictionary[@"document"][@"property1"] = @"first property";
  dictionary[@"document"][@"property2"] = @123;

  // When
  document = [MSDocumentUtils documentWrapperFromDictionary:dictionary documentType:[MSDictionaryDocument class] fromDeviceCache:NO];
  NSDictionary *resultDictionary = [[document deserializedValue] serializeToDictionary];

  // Then
  XCTAssertNotNil(document);
  XCTAssertNil([document error]);
  XCTAssertTrue([[document documentId] isEqualToString:@"document-id"]);
  XCTAssertNotNil([document deserializedValue]);
  XCTAssertTrue([resultDictionary[@"property1"] isEqualToString:@"first property"]);
  XCTAssertTrue([resultDictionary[@"property2"] isEqualToNumber:@123]);
  XCTAssertTrue([[document eTag] isEqualToString:@"etag"]);
  XCTAssertNotNil([document lastUpdatedDate]);
  XCTAssertTrue([[document partition] isEqualToString:@"readonly"]);
  XCTAssertNotNil([document jsonValue]);
  XCTAssertFalse([document fromDeviceCache]);
}

- (void)testDocumentWrapperFromDictionaryWithUnserializable {
  // If
  NSMutableDictionary *documentDictionary = [NSMutableDictionary new];
  documentDictionary[@"shouldFail"] = [NSSet set];

  NSMutableDictionary *dictionary = [NSMutableDictionary new];
  dictionary[@"id"] = @"document-id";
  dictionary[@"_etag"] = @"etag";
  dictionary[@"_ts"] = @0;
  dictionary[@"PartitionKey"] = @"readonly";
  dictionary[@"document"] = documentDictionary;

  // When
  MSDocumentWrapper *document = [MSDocumentUtils documentWrapperFromDictionary:dictionary documentType:[NSString class] fromDeviceCache:NO];

  // Then
  XCTAssertNotNil(document);
  XCTAssertNotNil([document error]);
  XCTAssertEqual([document documentId], @"document-id");
}

- (void)testDocumentWrapperFromDictionaryWithDataError {

  // If
  NSString *eTag = @"etag";
  NSString *partition = @"partition";
  NSString *documentId = @"docId";
  NSString *pendingOperation = @"pendingOperation";
  NSMutableDictionary *documentDictionary = [NSMutableDictionary new];
  documentDictionary[@"shouldFail"] = [NSSet set];
  NSDictionary *dictionary = @{@"document" : documentDictionary};

  // When
  MSDocumentWrapper *document = [MSDocumentUtils documentWrapperFromDictionary:dictionary
                                                                  documentType:[NSString class]
                                                                          eTag:eTag
                                                               lastUpdatedDate:[NSDate date]
                                                                     partition:partition
                                                                    documentId:documentId
                                                              pendingOperation:pendingOperation
                                                               fromDeviceCache:NO];

  // Then
  XCTAssertNotNil(document);
  XCTAssertNotNil([document error]);
  XCTAssertTrue([[document error] isKindOfClass:[MSDataError class]]);
  XCTAssertNotNil([document error].innerError);
  XCTAssertEqual([document error].innerError.code, MSACDataErrorJSONSerializationFailed);
  XCTAssertEqualObjects(document.documentId, documentId);
  XCTAssertEqualObjects(document.partition, partition);
  XCTAssertEqualObjects(document.eTag, eTag);
  XCTAssertFalse(document.fromDeviceCache);
  XCTAssertNotNil(document.lastUpdatedDate);
}

- (void)testDocumentWrapperFromDataNull {

  // If
  NSData *data;
  NSString *documentId = @"standalonedocument1";

  // When
  MSDocumentWrapper *document = [MSDocumentUtils documentWrapperFromData:data
                                                            documentType:[NSString class]
                                                               partition:kMSDataAppDocumentsPartition
                                                              documentId:documentId
                                                         fromDeviceCache:NO];

  // Then
  XCTAssertNotNil(document);
  XCTAssertNotNil([document error]);
  XCTAssertEqualObjects([document documentId], documentId);
  XCTAssertNil([document deserializedValue]);
  XCTAssertNil([document eTag]);
  XCTAssertNil([document lastUpdatedDate]);
  XCTAssertEqualObjects([document partition], kMSDataAppDocumentsPartition);
  XCTAssertNil([document jsonValue]);
  XCTAssertFalse([document fromDeviceCache]);
}

- (void)testDocumentWrapperFromDataDeserializationError {

  // If
  NSData *data = [self jsonFixture:@"invalidTestAppDocument"];
  NSString *documentId = @"standalonedocument1";
  XCTAssertNotNil(data);

  // When
  MSDocumentWrapper *document = [MSDocumentUtils documentWrapperFromData:data
                                                            documentType:[NSString class]
                                                               partition:kMSDataAppDocumentsPartition
                                                              documentId:documentId
                                                         fromDeviceCache:NO];

  // Then
  XCTAssertNotNil(document);
  XCTAssertNotNil([document error]);
  XCTAssertEqualObjects([document documentId], documentId);
  XCTAssertNil([document deserializedValue]);
  XCTAssertNil([document eTag]);
  XCTAssertNil([document lastUpdatedDate]);
  XCTAssertEqualObjects([document partition], kMSDataAppDocumentsPartition);
  XCTAssertNil([document jsonValue]);
}

- (void)testDocumentWrapperFromDocumentDataDeserializationError {

  // If
  NSData *data = [self jsonFixture:@"invalidTestAppDocument"];
  NSString *documentId = @"standalonedocument1";
  XCTAssertNotNil(data);

  // When
  MSDocumentWrapper *document = [MSDocumentUtils documentWrapperFromDocumentData:data
                                                                    documentType:[NSString class]
                                                                            eTag:@"etag"
                                                                 lastUpdatedDate:[NSDate date]
                                                                       partition:kMSDataAppDocumentsPartition
                                                                      documentId:documentId
                                                                pendingOperation:nil
                                                                 fromDeviceCache:NO];

  // Then
  XCTAssertNotNil(document);
  XCTAssertNotNil([document error]);
  XCTAssertEqualObjects([document documentId], documentId);
  XCTAssertNil([document deserializedValue]);
  XCTAssertEqualObjects([document eTag], @"etag");
  XCTAssertNil([document lastUpdatedDate]);
  XCTAssertEqualObjects([document partition], kMSDataAppDocumentsPartition);
  XCTAssertNil([document jsonValue]);
}

- (void)testDocumentWrapperFromDataFixture {

  // If
  NSData *data;
  NSString *documentId = @"standalonedocument1";

  // When
  MSDocumentWrapper *document = [MSDocumentUtils documentWrapperFromData:data
                                                            documentType:[NSString class]
                                                               partition:kMSDataAppDocumentsPartition
                                                              documentId:documentId
                                                         fromDeviceCache:YES];

  // Then
  XCTAssertNotNil(document);
  XCTAssertNotNil([document error]);
  XCTAssertEqualObjects([document documentId], documentId);
  XCTAssertNil([document deserializedValue]);
  XCTAssertNil([document eTag]);
  XCTAssertNil([document lastUpdatedDate]);
  XCTAssertEqualObjects([document partition], kMSDataAppDocumentsPartition);
  XCTAssertNil([document jsonValue]);
  XCTAssertFalse([document fromDeviceCache]); // An error case does not carry on the fromDeviceCache flag.

  // If, data is set to a valid document
  data = [self jsonFixture:@"validTestAppDocument"];

  // When
  document = [MSDocumentUtils documentWrapperFromData:data
                                         documentType:[MSDictionaryDocument class]
                                            partition:kMSDataAppDocumentsPartition
                                           documentId:documentId
                                      fromDeviceCache:YES];
  NSDictionary *resultDictionary = [[document deserializedValue] serializeToDictionary];

  // Then
  XCTAssertNotNil(document);
  XCTAssertNil([document error]);
  XCTAssertEqualObjects([document documentId], documentId);
  XCTAssertNotNil([document deserializedValue]);
  XCTAssertTrue([resultDictionary[@"property1"] isEqualToString:@"property number 1"]);
  XCTAssertTrue([resultDictionary[@"property2"] isEqualToNumber:@123]);
  XCTAssertTrue([[document eTag] isEqualToString:@"etag value"]);
  XCTAssertNotNil([document lastUpdatedDate]);
  XCTAssertEqualObjects([document partition], kMSDataAppDocumentsPartition);
  XCTAssertNotNil([document jsonValue]);
  XCTAssertTrue([document fromDeviceCache]);
}

- (void)testIsSerializableDocument {

  // If
  // NSProxy is not a NSObject, but it conforms to the NSObject protocol (light edge case testing).
  NSProxy *anotherRootObject = [NSProxy alloc];

  // When, Then
  XCTAssertFalse([MSDocumentUtils isSerializableDocument:[NSString class]]);
  XCTAssertFalse([MSDocumentUtils isSerializableDocument:object_getClass(anotherRootObject)]);
  XCTAssertTrue([MSDocumentUtils isSerializableDocument:[MSDictionaryDocument class]]);
}

@end
