// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <sqlite3.h>

#import "MSDBDocumentStorePrivate.h"
#import "MSDBStoragePrivate.h"

#import "MSDataSourceError.h"
#import "MSDataStore.h"
#import "MSDataStoreErrors.h"
#import "MSDictionaryDocument.h"
#import "MSDocumentUtils.h"
#import "MSDocumentWrapperInternal.h"
#import "MSMockDocument.h"
#import "MSReadOptions.h"
#import "MSTestFrameworks.h"
#import "MSTokenExchange.h"
#import "MSUtility+Date.h"
#import "MSUtility+File.h"
#import "MSWriteOptions.h"
#import "NSObject+MSTestFixture.h"

@interface MSDBDocumentStoreTests : XCTestCase

@property(nonatomic, strong) MSDBStorage *dbStorage;
@property(nonatomic, strong) MSDBDocumentStore *sut;
@property(nonnull, strong) MSDBSchema *schema;

@end

@implementation MSDBDocumentStoreTests

- (void)setUp {
  [super setUp];
  [MSUtility deleteItemForPathComponent:kMSDBDocumentFileName];
  self.schema = [MSDBDocumentStore documentTableSchema];
  self.dbStorage = [[MSDBStorage alloc] initWithSchema:self.schema version:0 filename:kMSDBDocumentFileName];
  self.sut = [[MSDBDocumentStore alloc] initWithDbStorage:self.dbStorage schema:self.schema];
}

- (void)tearDown {
  [MSUtility deleteItemForPathComponent:kMSDBDocumentFileName];
  [super tearDown];
  [self.sut.dbStorage dropTable:kMSAppDocumentTableName];
}

- (void)testReadUserDocumentFromLocalDatabase {

  // If
  NSString *documentId = @"12829";
  NSString *partitionKey = @"user";
  NSString *accountId = @"dabe069b-ee80-4ca6-8657-9128a4600958";
  NSString *eTag = @"398";
  NSString *fullPartition = [NSString stringWithFormat:@"%@-%@", partitionKey, accountId];
  NSString *jsonString = @"{ \"document\": {\"key\": \"value\"}}";
  NSString *pendingOperation = kMSPendingOperationReplace;
  [self addJsonStringToTable:jsonString
                        eTag:eTag
                   partition:fullPartition
                  documentId:documentId
            pendingOperation:pendingOperation
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
  XCTAssertEqualObjects(documentWrapper.pendingOperation, pendingOperation);
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
            pendingOperation:@""
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
            pendingOperation:@""
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
  [self.sut createUserStorageWithAccountId:accountId];
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

- (void)testCreationOfApplicationLevelTable {

  // If
  MSDBSchema *expectedSchema = @{kMSAppDocumentTableName : [MSDBDocumentStore columnsSchema]};
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
      kMSPendingOperationColumnName : @(8)
    }
  };
  OCMStub([MSDBStorage columnsIndexes:expectedSchema]).andReturn(expectedColumnIndexes);

  // When, Then
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
  XCTAssertEqual([expectedColumnIndexes[kMSAppDocumentTableName][kMSPendingOperationColumnName] integerValue],
                 self.sut.pendingOperationColumnIndex);
}

- (void)testCreationOfUserLevelTable {

  // If
  NSString *expectedAccountId = @"Test-account-id";
  NSString *tableName = [NSString stringWithFormat:kMSUserDocumentTableNameFormat, expectedAccountId];

  // When
  id dbStorageMock = OCMClassMock([MSDBStorage class]);
  self.sut.dbStorage = dbStorageMock;
  [self.sut createUserStorageWithAccountId:expectedAccountId];

  // Then
  OCMVerify([self.dbStorage createTable:tableName
                          columnsSchema:[self expectedColumnSchema]
                uniqueColumnsConstraint:[self expectedUniqueColumnsConstraint]]);
}

- (void)testDeletionOfUserLevelTable {

  // If
  NSString *expectedAccountId = @"Test-account-id";
  NSString *userTableName = [NSString stringWithFormat:kMSUserDocumentTableNameFormat, expectedAccountId];

  // When
  [self.sut deleteUserStorageWithAccountId:expectedAccountId];

  // Then
  OCMVerify([self.dbStorage dropTable:userTableName]);
}

- (void)testUpsertWithPartition {

  // If
  MSDocumentWrapper *documentWrapper = [MSDocumentUtils documentWrapperFromData:[self jsonFixture:@"validTestDocument"]
                                                                   documentType:[MSDictionaryDocument class]];

  // When
  BOOL result = [self.sut upsertWithPartition:MSDataStoreAppDocumentsPartition
                              documentWrapper:documentWrapper
                                    operation:@"CREATE"
                                      options:[[MSReadOptions alloc] initWithDeviceTimeToLive:1]];

  // Then
  XCTAssertTrue(result);
  // TODO: also validate with read when we have it.
}

- (void)testDeleteWithPartitionForNonExistentDocument {

  // If, When
  BOOL result = [self.sut deleteWithPartition:MSDataStoreAppDocumentsPartition documentId:@"some-document-id"];

  // Then, should succeed but be a no-op
  XCTAssertTrue(result);
}

- (void)testDeleteWithReadonlyPartitionForExistingDocument {

  // If
  MSDocumentWrapper *documentWrapper = [MSDocumentUtils documentWrapperFromData:[self jsonFixture:@"validTestDocument"]
                                                                   documentType:[MSDictionaryDocument class]];
  [self.sut upsertWithPartition:MSDataStoreAppDocumentsPartition
                documentWrapper:documentWrapper
                      operation:@"CREATE"
                        options:[[MSReadOptions alloc] initWithDeviceTimeToLive:1]];

  // When
  BOOL result = [self.sut deleteWithPartition:MSDataStoreAppDocumentsPartition documentId:documentWrapper.documentId];

  // Then
  XCTAssertTrue(result);
}

- (void)testDeleteWithUserPartitionForExistingDocument {
  
  // If
  MSDocumentWrapper *documentWrapper = [MSDocumentUtils documentWrapperFromData:[self jsonFixture:@"validTestDocument"]
                                                                   documentType:[MSDictionaryDocument class]];
  [self.sut upsertWithPartition:MSDataStoreUserDocumentsPartition
                documentWrapper:documentWrapper
                      operation:@"CREATE"
                        options:[[MSReadOptions alloc] initWithDeviceTimeToLive:1]];
  
  // When
  BOOL result = [self.sut deleteWithPartition:MSDataStoreAppDocumentsPartition documentId:documentWrapper.documentId];
  
  // Then
  XCTAssertTrue(result);
}

- (void)testDeletionOfAllTables {

  // If
  NSString *expectedAccountId = @"Test-account-id";
  NSString *tableName = [NSString stringWithFormat:kMSUserDocumentTableNameFormat, expectedAccountId];
  [self.sut createUserStorageWithAccountId:expectedAccountId];
  OCMVerify([self.dbStorage createTable:tableName columnsSchema:[self expectedColumnSchema]]);
  XCTAssertTrue([self tableExists:tableName]);

  // When
  [self.sut deleteAllTables];

  // Then
  XCTAssertFalse([self tableExists:tableName]);
}

- (void)addJsonStringToTable:(NSString *)jsonString
                        eTag:(NSString *)eTag
                   partition:(NSString *)partition
                  documentId:(NSString *)documentId
            pendingOperation:(NSString *)pendingOperation
              expirationTime:(NSDate *)expirationTime {
  sqlite3 *db = [self openDatabase:kMSDBDocumentFileName];
  NSString *expirationTimeString = [MSUtility dateToISO8601:expirationTime];
  NSString *operationTimeString = [MSUtility dateToISO8601:[NSDate date]];
  NSString *insertQuery = [NSString stringWithFormat:@"INSERT INTO \"%@\" (\"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\") "
                                                     @"VALUES ('%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@')",
                                                     kMSAppDocumentTableName, kMSIdColumnName, kMSPartitionColumnName, kMSETagColumnName,
                                                     kMSDocumentColumnName, kMSDocumentIdColumnName, kMSExpirationTimeColumnName,
                                                     kMSOperationTimeColumnName, kMSPendingOperationColumnName, @0, partition, eTag,
                                                     jsonString, documentId, expirationTimeString, operationTimeString, pendingOperation];
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

- (BOOL)tableExists:(NSString *)tableName {
  NSArray<NSArray *> *result = [self.dbStorage
      executeSelectionQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM \"sqlite_master\" WHERE \"type\"='table' AND \"name\"='%@';",
                                                       tableName]];
  return [(NSNumber *)result[0][0] boolValue];
}

- (NSArray<NSString *> *)expectedUniqueColumnsConstraint {
  return @[ kMSPartitionColumnName, kMSDocumentIdColumnName ];
}

@end
