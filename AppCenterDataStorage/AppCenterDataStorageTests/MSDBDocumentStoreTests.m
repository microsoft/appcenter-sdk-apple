// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <sqlite3.h>

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
  NSString *eTag = @"398";
  MSDBDocumentStore *sut = [MSDBDocumentStore new];
  [sut createUserStorageWithAccountId:accountId];
  NSString *expectedPartition = [NSString stringWithFormat:@"%@-%@", partitionKey, accountId];
  [self addDocumentToTable:document eTag:eTag partition:expectedPartition documentId:documentId];

  // When
  MSDocumentWrapper *documentWrapper = [sut readWithPartition:partitionKey documentId:documentId documentType:[document class] readOptions:[MSReadOptions new]];

  // Then
  XCTAssertNotNil(documentWrapper);
  XCTAssertNil(documentWrapper.error);
  XCTAssertEqualObjects(documentWrapper.deserializedValue, document.contentDictionary);
  XCTAssertEqualObjects(documentWrapper.partition, expectedPartition);
  XCTAssertEqualObjects(documentWrapper.documentId, documentId);

}

- (void)addDocumentToTable:(id<MSSerializableDocument>) document eTag:(NSString *)eTag partition:(NSString *)partition documentId:(NSString *)documentId {
  NSDictionary *documentDict = [document serializeToDictionary];
  NSData *documentData = [NSKeyedArchiver archivedDataWithRootObject:documentDict];
  NSString *base64Data = [documentData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
  sqlite3 *db = [self openDatabase:kMSDBDocumentFileName];
  NSString *insertQuery = [NSString stringWithFormat:@"INSERT INTO '%@' ('%@', '%@', '%@', '%@', '%@') VALUES ('%@', '%@', '%@', '%@', '%@')", kMSAppDocumentTableName,
                           kMSIdColumnName, kMSPartitionColumnName, kMSETagColumnName, kMSDocumentColumnName, kMSDocumentIdColumnName, @0, partition, eTag, base64Data, documentId];
  sqlite3_exec(db, [insertQuery UTF8String], NULL, NULL, NULL);
  sqlite3_close(db);
}

- (sqlite3 *)openDatabase:(NSString *)path {
  sqlite3 *db = NULL;
  NSURL *dbURL = [MSUtility createFileAtPathComponent:path withData:nil atomically:NO forceOverwrite:NO];
  sqlite3_open_v2([[dbURL absoluteString] UTF8String], &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_URI, NULL);
  return db;
}

@end
