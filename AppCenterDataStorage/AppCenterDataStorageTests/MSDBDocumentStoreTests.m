// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <sqlite3.h>

#import "MSDBDocumentStorePrivate.h"
#import "MSDBStoragePrivate.h"
#import "MSDataSourceError.h"
#import "MSDataStoreErrors.h"
#import "MSDocumentWrapper.h"
#import "MSMockDocument.h"
#import "MSReadOptions.h"
#import "MSTestFrameworks.h"
#import "MSTokenExchange.h"
#import "MSUtility+Date.h"
#import "MSUtility+File.h"
#import "MSWriteOptions.h"

@interface MSDBDocumentStoreTests : XCTestCase

@property(nonatomic) id dbStorageMock;
@property(nonatomic, nullable) MSDBDocumentStore *sut;

@end

@implementation MSDBDocumentStoreTests

- (void)setUp {
  [super setUp];
  [MSUtility deleteItemForPathComponent:kMSDBDocumentFileName];
  self.sut = [MSDBDocumentStore new];
}

- (void)tearDown {
  [MSUtility deleteItemForPathComponent:kMSDBDocumentFileName];
  [super tearDown];
}

- (void)testReadUserDocumentFromLocalDatabase {

  // If
  NSString *documentId = @"12829";
  NSString *partitionKey = @"user";
  NSString *accountId = @"dabe069b-ee80-4ca6-8657-9128a4600958";
  NSString *eTag = @"398";
  NSString *fullPartition = [NSString stringWithFormat:@"%@-%@", partitionKey, accountId];
  NSString *jsonString = @"{ \"document\": {\"key\": \"value\"}}";
  [self addJsonStringToTable:jsonString
                        eTag:eTag
                   partition:fullPartition
                  documentId:documentId
              expirationTime:[NSDate dateWithTimeIntervalSinceNow:1000000]];

  // When
  MSDocumentWrapper *documentWrapper = [self.sut readWithPartition:fullPartition
                                                        documentId:documentId
                                                      documentType:[MSMockDocument class]
                                                       readOptions:[MSReadOptions new]];

  // Then
  XCTAssertNotNil(documentWrapper);
  XCTAssertNil(documentWrapper.error);
  NSDictionary *retrievedContentDictionary = ((MSMockDocument *)(documentWrapper.deserializedValue)).contentDictionary;
  XCTAssertEqualObjects(retrievedContentDictionary[@"key"], @"value");
  XCTAssertEqualObjects(documentWrapper.partition, fullPartition);
  XCTAssertEqualObjects(documentWrapper.documentId, documentId);
}

- (void)testReadUserDocumentFromLocalDatabaseWithDeserializationError {

  // If
  NSString *documentId = @"12829";
  NSString *partitionKey = @"user";
  NSString *accountId = @"dabe069b-ee80-4ca6-8657-9128a4600958";
  NSString *eTag = @"398";
  NSString *fullPartition = [NSString stringWithFormat:@"%@-%@", partitionKey, accountId];
  NSString *jsonString = @"{";
  [self addJsonStringToTable:jsonString
                        eTag:eTag
                   partition:fullPartition
                  documentId:documentId
              expirationTime:[NSDate dateWithTimeIntervalSinceNow:1000000]];

  // When
  MSDocumentWrapper *documentWrapper = [self.sut readWithPartition:fullPartition
                                                        documentId:documentId
                                                      documentType:[MSMockDocument class]
                                                       readOptions:[MSReadOptions new]];

  // Then
  XCTAssertNotNil(documentWrapper);
  XCTAssertNotNil(documentWrapper.error);
  XCTAssertEqualObjects(documentWrapper.documentId, documentId);
}

- (void)testReadExpiredUserDocument {

  // If
  NSString *documentId = @"12829";
  NSString *partitionKey = @"user";
  NSString *accountId = @"dabe069b-ee80-4ca6-8657-9128a4600958";
  NSString *eTag = @"398";
  NSString *fullPartition = [NSString stringWithFormat:@"%@-%@", partitionKey, accountId];
  NSString *jsonString = @"{ \"document\": {\"key\": \"value\"}}";
  [self addJsonStringToTable:jsonString
                        eTag:eTag
                   partition:fullPartition
                  documentId:documentId
              expirationTime:[NSDate dateWithTimeIntervalSinceNow:-1000000]];

  // When
  MSDocumentWrapper *documentWrapper = [self.sut readWithPartition:fullPartition
                                                        documentId:documentId
                                                      documentType:[MSMockDocument class]
                                                       readOptions:[MSReadOptions new]];

  // Then
  XCTAssertNotNil(documentWrapper);
  XCTAssertNotNil(documentWrapper.error);
  XCTAssertEqualObjects(documentWrapper.error.error.domain, kMSACDataStoreErrorDomain);
  XCTAssertEqual(documentWrapper.error.error.code, MSACDataStoreErrorLocalDocumentExpired);
  XCTAssertEqualObjects(documentWrapper.documentId, documentId);
  OCMVerify([self.sut deleteDocumentWithPartition:fullPartition documentId:documentId]);
}

- (void)testReadUserDocumentFromLocalDatabaseNotFound {

  // If
  NSString *documentId = @"12829";
  NSString *partitionKey = @"user";
  MSMockDocument *document = [MSMockDocument new];
  NSString *accountId = @"dabe069b-ee80-4ca6-8657-9128a4600958";
  document.contentDictionary = @{@"key" : @"value"};
  MSDBDocumentStore *sut = [MSDBDocumentStore new];
  [sut createUserStorageWithAccountId:accountId];
  NSString *fullPartition = [NSString stringWithFormat:@"%@-%@", partitionKey, accountId];

  // When
  MSDocumentWrapper *documentWrapper = [sut readWithPartition:fullPartition
                                                   documentId:documentId
                                                 documentType:[document class]
                                                  readOptions:[MSReadOptions new]];

  // Then
  XCTAssertNotNil(documentWrapper);
  XCTAssertNotNil(documentWrapper.error);
  XCTAssertEqualObjects(documentWrapper.error.error.domain, kMSACDataStoreErrorDomain);
  XCTAssertEqual(documentWrapper.error.error.code, MSACDataStoreErrorLocalDocumentNotFound);
  XCTAssertEqualObjects(documentWrapper.documentId, documentId);
}

- (void)testCreateOfApplicationLevelTable {

  // If
  NSUInteger expectedSchemaVersion = 1;
  MSDBSchema *expectedSchema = @{kMSAppDocumentTableName : [self expectedColumnSchema]};
  NSDictionary *expectedColumnIndexes = @{
    kMSAppDocumentTableName : @{
      kMSIdColumnName : @(0),
      kMSPartitionColumnName : @(1),
      kMSDocumentIdColumnName : @(2),
      kMSDocumentColumnName : @(3),
      kMSETagColumnName : @(4),
      kMSExpirationTimeColumnName : @(5),
      kMSDownloadTimeColumnName : @(6),
      kMSOperationTimeColumnName : @(7),
      kMSPendingDownloadColumnName : @(8)
    }
  };
  OCMStub([MSDBStorage columnsIndexes:expectedSchema]).andReturn(expectedColumnIndexes);

  // When
  self.sut = [MSDBDocumentStore new];

  // Then
  OCMVerify([self.sut.dbStorage initWithSchema:expectedSchema version:expectedSchemaVersion filename:kMSDBDocumentFileName]);
  OCMVerify([MSDBStorage columnsIndexes:expectedSchema]);
  XCTAssertEqual([expectedColumnIndexes[kMSAppDocumentTableName][kMSIdColumnName] integerValue], self.sut.idColumnIndex);
  XCTAssertEqual([expectedColumnIndexes[kMSAppDocumentTableName][kMSPartitionColumnName] integerValue], self.sut.partitionColumnIndex);
  XCTAssertEqual([expectedColumnIndexes[kMSAppDocumentTableName][kMSDocumentIdColumnName] integerValue], self.sut.documentIdColumnIndex);
  XCTAssertEqual([expectedColumnIndexes[kMSAppDocumentTableName][kMSDocumentColumnName] integerValue], self.sut.documentColumnIndex);
  XCTAssertEqual([expectedColumnIndexes[kMSAppDocumentTableName][kMSETagColumnName] integerValue], self.sut.eTagColumnIndex);
  XCTAssertEqual([expectedColumnIndexes[kMSAppDocumentTableName][kMSExpirationTimeColumnName] integerValue],
                 self.sut.expirationTimeColumnIndex);
  XCTAssertEqual([expectedColumnIndexes[kMSAppDocumentTableName][kMSDownloadTimeColumnName] integerValue],
                 self.sut.downloadTimeColumnIndex);
  XCTAssertEqual([expectedColumnIndexes[kMSAppDocumentTableName][kMSOperationTimeColumnName] integerValue],
                 self.sut.operationTimeColumnIndex);
  XCTAssertEqual([expectedColumnIndexes[kMSAppDocumentTableName][kMSPendingDownloadColumnName] integerValue],
                 self.sut.pendingOperationColumnIndex);
}

- (void)testCreationOfUserLevelTable {

  // If
  NSString *expectedAccountId = @"Test-account-id";
  NSString *tableName = [NSString stringWithFormat:kMSUserDocumentTableNameFormat, expectedAccountId];
  // When
  [self.sut createUserStorageWithAccountId:expectedAccountId];

  // Then
  OCMVerify([self.dbStorageMock createTable:tableName columnsSchema:[self expectedColumnSchema]]);
}

- (void)testDeletionOfUserLevelTable {

  // If
  NSString *expectedAccountId = @"Test-account-id";
  NSString *userTableName = [NSString stringWithFormat:kMSUserDocumentTableNameFormat, expectedAccountId];

  // When
  [self.sut deleteUserStorageWithAccountId:expectedAccountId];

  // Then
  OCMVerify([self.dbStorageMock dropTable:userTableName]);
}

- (MSDBColumnsSchema *)expectedColumnSchema {

  // TODO create composite key for partition and the document id
  return @[
    @{kMSIdColumnName : @[ kMSSQLiteTypeInteger, kMSSQLiteConstraintPrimaryKey, kMSSQLiteConstraintAutoincrement ]},
    @{kMSPartitionColumnName : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]},
    @{kMSDocumentIdColumnName : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]}, @{kMSDocumentColumnName : @[ kMSSQLiteTypeText ]},
    @{kMSETagColumnName : @[ kMSSQLiteTypeText ]}, @{kMSExpirationTimeColumnName : @[ kMSSQLiteTypeInteger ]},
    @{kMSDownloadTimeColumnName : @[ kMSSQLiteTypeInteger ]}, @{kMSOperationTimeColumnName : @[ kMSSQLiteTypeInteger ]},
    @{kMSPendingDownloadColumnName : @[ kMSSQLiteTypeText ]}
  ];
}

// These are temporary methods due to create method not exist.
- (void)addJsonStringToTable:(NSString *)jsonString
                        eTag:(NSString *)eTag
                   partition:(NSString *)partition
                  documentId:(NSString *)documentId
              expirationTime:(NSDate *)expirationTime {
  sqlite3 *db = [self openDatabase:kMSDBDocumentFileName];
  NSString *expirationTimeString = [MSUtility dateToISO8601:expirationTime];
  NSString *insertQuery = [NSString
      stringWithFormat:@"INSERT INTO '%@' ('%@', '%@', '%@', '%@', '%@', '%@', '%@') VALUES ('%@', '%@', '%@', '%@', '%@', '%@', '%@')",
                       kMSAppDocumentTableName, kMSIdColumnName, kMSPartitionColumnName, kMSETagColumnName, kMSDocumentColumnName,
                       kMSDocumentIdColumnName, kMSExpirationTimeColumnName, kMSOperationTimeColumnName, @0, partition, eTag, jsonString,
                       documentId, expirationTimeString, [NSDate date]];
  char *error;
  sqlite3_exec(db, [insertQuery UTF8String], NULL, NULL, &error);
  sqlite3_close(db);
}

- (sqlite3 *)openDatabase:(NSString *)path {
  sqlite3 *db = NULL;
  NSURL *dbURL = [MSUtility createFileAtPathComponent:path withData:nil atomically:NO forceOverwrite:NO];
  sqlite3_open_v2([[dbURL absoluteString] UTF8String], &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_URI, NULL);
  return db;
}

@end
