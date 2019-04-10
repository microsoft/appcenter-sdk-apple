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
#import "MSTokenResult.h"
#import "MSUtility+Date.h"
#import "MSUtility+File.h"
#import "MSWriteOptions.h"
#import "NSObject+MSTestFixture.h"

@interface MSDBDocumentStoreTests : XCTestCase

@property(nonatomic, strong) MSDBStorage *dbStorage;
@property(nonatomic, strong) MSDBDocumentStore *sut;
@property(nonnull, strong) MSDBSchema *schema;
@property(nonnull, strong) MSTokenResult *appToken;
@property(nonnull, strong) MSTokenResult *userToken;

@end

@implementation MSDBDocumentStoreTests

MSTokenResult *token1;

- (void)setUp {
  [super setUp];

  // Delete existing database.
  [MSUtility deleteItemForPathComponent:kMSDBDocumentFileName];

  // Init storage.
  self.schema = [MSDBDocumentStore documentTableSchema];
  self.dbStorage = [[MSDBStorage alloc] initWithSchema:self.schema version:0 filename:kMSDBDocumentFileName];
  self.sut = [[MSDBDocumentStore alloc] initWithDbStorage:self.dbStorage schema:self.schema];

  // Init tokens.
  self.appToken = [[MSTokenResult alloc] initWithPartition:MSDataStoreAppDocumentsPartition
                                                 dbAccount:@"account"
                                                    dbName:@"dbname"
                                          dbCollectionName:@"collection"
                                                     token:@"token"
                                                    status:@"Succeed"
                                                 expiresOn:@"yesterday"
                                                 accountId:nil];
  self.userToken = [[MSTokenResult alloc] initWithPartition:@"user-123"
                                                  dbAccount:@"account"
                                                     dbName:@"dbname"
                                           dbCollectionName:@"collection"
                                                      token:@"token"
                                                     status:@"Succeed"
                                                  expiresOn:@"yesterday"
                                                  accountId:@"123"];
}

- (void)tearDown {
  [super tearDown];

  // Delete existing database.
  [MSUtility deleteItemForPathComponent:kMSDBDocumentFileName];
}

- (void)testReadUserDocumentFromLocalDatabase {

  // If
  NSString *documentId = @"12829";
  NSString *eTag = @"398";
  NSString *jsonString = @"{ \"document\": {\"key\": \"value\"}}";
  NSString *pendingOperation = kMSPendingOperationReplace;
  [self addJsonStringToTable:jsonString
                        eTag:eTag
                   partition:self.appToken.partition
                  documentId:documentId
            pendingOperation:pendingOperation
              expirationTime:[NSDate dateWithTimeIntervalSinceNow:1000000]];

  // When
  MSDocumentWrapper *documentWrapper = [self.sut readWithToken:self.appToken
                                                    documentId:documentId
                                                  documentType:[MSMockDocument class]
                                                   readOptions:[MSReadOptions new]];

  // Then
  XCTAssertNotNil(documentWrapper);
  XCTAssertNil(documentWrapper.error);
  NSDictionary *retrievedContentDictionary = ((MSMockDocument *)(documentWrapper.deserializedValue)).contentDictionary;
  XCTAssertEqualObjects(retrievedContentDictionary[@"key"], @"value");
  XCTAssertEqualObjects(documentWrapper.partition, self.appToken.partition);
  XCTAssertEqualObjects(documentWrapper.documentId, documentId);
  XCTAssertEqualObjects(documentWrapper.pendingOperation, pendingOperation);
}

- (void)testReadUserDocumentFromLocalDatabaseWithDeserializationError {

  // If
  NSString *documentId = @"12829";
  NSString *eTag = @"398";
  NSString *jsonString = @"{";
  [self addJsonStringToTable:jsonString
                        eTag:eTag
                   partition:self.userToken.partition
                  documentId:documentId
            pendingOperation:@""
              expirationTime:[NSDate dateWithTimeIntervalSinceNow:1000000]];

  // When
  MSDocumentWrapper *documentWrapper = [self.sut readWithToken:self.userToken
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
  NSString *eTag = @"398";
  NSString *jsonString = @"{ \"document\": {\"key\": \"value\"}}";
  [self addJsonStringToTable:jsonString
                        eTag:eTag
                   partition:self.appToken.partition
                  documentId:documentId
            pendingOperation:@""
              expirationTime:[NSDate dateWithTimeIntervalSinceNow:-1000000]];

  // When
  MSDocumentWrapper *documentWrapper = [self.sut readWithToken:self.appToken
                                                    documentId:documentId
                                                  documentType:[MSMockDocument class]
                                                   readOptions:[MSReadOptions new]];

  // Then
  XCTAssertNotNil(documentWrapper);
  XCTAssertNotNil(documentWrapper.error);
  XCTAssertEqualObjects(documentWrapper.error.error.domain, kMSACDataStoreErrorDomain);
  XCTAssertEqual(documentWrapper.error.error.code, MSACDataStoreErrorLocalDocumentExpired);
  XCTAssertEqualObjects(documentWrapper.documentId, documentId);
  OCMVerify([self.sut deleteWithToken:self.userToken documentId:documentId]);
}

- (void)testReadUserDocumentFromLocalDatabaseNotFound {

  // If
  NSString *documentId = @"12829";
  MSMockDocument *document = [MSMockDocument new];
  document.contentDictionary = @{@"key" : @"value"};
  MSDBDocumentStore *sut = [MSDBDocumentStore new];
  [self.sut createUserStorageWithAccountId:self.userToken.accountId];

  // When
  MSDocumentWrapper *documentWrapper = [sut readWithToken:self.userToken
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
                          columnsSchema:[MSDBDocumentStore columnsSchema]
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

- (void)testUpsertAppDocument {

  // If
  MSDocumentWrapper *documentWrapper = [MSDocumentUtils documentWrapperFromData:[self jsonFixture:@"validTestDocument"]
                                                                   documentType:[MSDictionaryDocument class]];
  MSReadOptions *readOptions = [[MSReadOptions alloc] initWithDeviceTimeToLive:1];

  // When
  BOOL result = [self.sut upsertWithToken:self.appToken documentWrapper:documentWrapper operation:@"CREATE" options:readOptions];
  MSDocumentWrapper *expectedDocumentWrapper = [self.sut readWithToken:self.appToken
                                                            documentId:documentWrapper.documentId
                                                          documentType:[MSDictionaryDocument class]
                                                           readOptions:readOptions];

  // Then
  XCTAssertTrue(result);
  XCTAssertNil(expectedDocumentWrapper.error);
  XCTAssertNotNil(expectedDocumentWrapper.deserializedValue);
  XCTAssertNotNil(expectedDocumentWrapper.jsonValue);
  XCTAssertEqualObjects(expectedDocumentWrapper.documentId, documentWrapper.documentId);
  XCTAssertEqualObjects(expectedDocumentWrapper.partition, documentWrapper.partition);
  XCTAssertEqualObjects(expectedDocumentWrapper.eTag, documentWrapper.eTag);

  // The expected document wrapper should have its last updated date set to now + read option (at insertion time). The fixture we use should
  // hence be in the past.
  XCTAssertTrue([expectedDocumentWrapper.lastUpdatedDate compare:documentWrapper.lastUpdatedDate] == NSOrderedDescending);
}

- (void)testDeleteAppDocumentForNonExistentDocument {

  // If, When
  BOOL result = [self.sut deleteWithToken:self.appToken documentId:@"some-non-existing-document-id"];
  MSDocumentWrapper *expectedDocumentWrapper = [self.sut readWithToken:self.appToken
                                                            documentId:@"some-non-existing-document-id"
                                                          documentType:[MSDictionaryDocument class]
                                                           readOptions:[[MSReadOptions alloc] initWithDeviceTimeToLive:1]];

  // Then, should succeed but be a no-op
  XCTAssertTrue(result);
  XCTAssertNotNil(expectedDocumentWrapper.error);
}

- (void)testDeleteExistingAppDocument {

  // If
  MSDocumentWrapper *documentWrapper = [MSDocumentUtils documentWrapperFromData:[self jsonFixture:@"validTestDocument"]
                                                                   documentType:[MSDictionaryDocument class]];
  [self.sut upsertWithToken:self.appToken
            documentWrapper:documentWrapper
                  operation:@"CREATE"
                    options:[[MSReadOptions alloc] initWithDeviceTimeToLive:1]];
  MSDocumentWrapper *expectedDocumentWrapper = [self.sut readWithToken:self.appToken
                                                            documentId:documentWrapper.documentId
                                                          documentType:[MSDictionaryDocument class]
                                                           readOptions:[[MSReadOptions alloc] initWithDeviceTimeToLive:1]];
  XCTAssertNil(expectedDocumentWrapper.error);

  // When
  BOOL result = [self.sut deleteWithToken:self.appToken documentId:documentWrapper.documentId];
  expectedDocumentWrapper = [self.sut readWithToken:self.appToken
                                         documentId:documentWrapper.documentId
                                       documentType:[MSDictionaryDocument class]
                                        readOptions:[[MSReadOptions alloc] initWithDeviceTimeToLive:1]];

  // Then
  XCTAssertTrue(result);
  XCTAssertNotNil(expectedDocumentWrapper.error);
}

- (void)testDeleteExistingUserDocument {

  // If
  MSDocumentWrapper *documentWrapper = [MSDocumentUtils documentWrapperFromData:[self jsonFixture:@"validTestDocument"]
                                                                   documentType:[MSDictionaryDocument class]];
  [self.sut createUserStorageWithAccountId:self.userToken.accountId];
  [self.sut upsertWithToken:self.userToken
            documentWrapper:documentWrapper
                  operation:@"CREATE"
                    options:[[MSReadOptions alloc] initWithDeviceTimeToLive:1]];
  MSDocumentWrapper *expectedDocumentWrapper = [self.sut readWithToken:self.userToken
                                                            documentId:documentWrapper.documentId
                                                          documentType:[MSDictionaryDocument class]
                                                           readOptions:[[MSReadOptions alloc] initWithDeviceTimeToLive:1]];
  XCTAssertNil(expectedDocumentWrapper.error);

  // When
  BOOL result = [self.sut deleteWithToken:self.userToken documentId:documentWrapper.documentId];
  expectedDocumentWrapper = [self.sut readWithToken:self.userToken
                                         documentId:documentWrapper.documentId
                                       documentType:[MSDictionaryDocument class]
                                        readOptions:[[MSReadOptions alloc] initWithDeviceTimeToLive:1]];

  // Then
  XCTAssertTrue(result);
  XCTAssertNotNil(expectedDocumentWrapper.error);
}

- (void)testDeletionOfAllTables {

  // If
  NSString *expectedAccountId = @"Test-account-id";
  NSString *tableName = [NSString stringWithFormat:kMSUserDocumentTableNameFormat, expectedAccountId];
  [self.sut createUserStorageWithAccountId:expectedAccountId];
  OCMVerify([self.dbStorage createTable:tableName columnsSchema:[MSDBDocumentStore columnsSchema]]);
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
