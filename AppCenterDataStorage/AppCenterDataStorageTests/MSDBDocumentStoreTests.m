// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDBDocumentStorePrivate.h"
#import "MSTestFrameworks.h"
#import "MSMockDocument.h"
#import "MSReadOptions.h"
#import "MSWriteOptions.h"
#import "MSDocumentWrapper.h"
#import "MSUtility+File.h"

@interface MSDBDocumentStoreTests : XCTestCase

@end

@implementation MSDBDocumentStoreTests

- (void)setUp {
  [super setUp];
  [MSUtility deleteItemForPathComponent:kMSDBDocumentFileName];
}

- (void)tearDown {
  [MSUtility deleteItemForPathComponent:kMSDBDocumentFileName];
  [super tearDown];
}

- (void)testReadUserDocumentFromLocalDatabase {

  // If
  NSString *documentId = @"12829";
  NSString *partitionKey = @"partition1234123";
  MSMockDocument *document = [MSMockDocument new];
  NSString *accountId = @"account12";
  document.contentDictionary = @{@"key" : @"value"};
  NSString *eTag = @"";
  MSDBDocumentStore *sut = [MSDBDocumentStore new];
  [sut createUserStorageWithAccountId:accountId];
  MSDocumentWrapper *addedDocumentWrapper = [[MSDocumentWrapper alloc] initWithDeserializedValue:document partition:partitionKey documentId:documentId eTag:eTag lastUpdatedDate:[NSDate date]];
  NSString *expectedPartition = [NSString stringWithFormat:@"%@-%@", partitionKey, accountId];
  [sut createWithPartition:partitionKey document:addedDocumentWrapper writeOptions:[MSWriteOptions new]];

  // When
  MSDocumentWrapper *documentWrapper = [sut readWithPartition:partitionKey documentId:documentId documentType:[document class] readOptions:[MSReadOptions new]];

  // Then
  XCTAssertNotNil(documentWrapper);
  XCTAssertNil(documentWrapper.error);
  XCTAssertEqualObjects(documentWrapper.deserializedValue, document.contentDictionary);
  XCTAssertEqualObjects(documentWrapper.partition, expectedPartition);
  XCTAssertEqualObjects(documentWrapper.documentId, documentId);

}

@end
