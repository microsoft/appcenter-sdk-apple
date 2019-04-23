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
@property(nonnull, strong) MSTokenResult *appToken;
@property(nonnull, strong) MSTokenResult *userToken;

@end

@implementation MSDBDocumentStoreTests

- (void)setUp {
  [super setUp];

  // Delete existing database.
  [MSUtility deleteItemForPathComponent:kMSDBDocumentFileName];

  // Init storage.
  self.dbStorage = [[MSDBStorage alloc] initWithVersion:0 filename:kMSDBDocumentFileName];
  self.sut = [[MSDBDocumentStore alloc] initWithDbStorage:self.dbStorage];

  // Init tokens.
  self.appToken = [[MSTokenResult alloc] initWithPartition:kMSDataStoreAppDocumentsPartition
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

- (void)testReadAppDocumentFromLocalDatabase {

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
              expirationTime:(long)[[NSDate dateWithTimeIntervalSinceNow:1000000] timeIntervalSince1970]];

  // When
  MSDocumentWrapper *documentWrapper = [self.sut readWithToken:self.appToken
                                                    documentId:documentId
                                                  documentType:[MSDictionaryDocument class]];

  // Then
  XCTAssertNotNil(documentWrapper);
  XCTAssertNil(documentWrapper.error);
  XCTAssertTrue(documentWrapper.fromDeviceCache);
  NSDictionary *retrievedContentDictionary = ((MSDictionaryDocument *)(documentWrapper.deserializedValue)).dictionary;
  XCTAssertEqualObjects(retrievedContentDictionary[@"key"], @"value");
  XCTAssertEqualObjects(documentWrapper.partition, self.appToken.partition);
  XCTAssertEqualObjects(documentWrapper.documentId, documentId);
  XCTAssertEqualObjects(documentWrapper.pendingOperation, pendingOperation);
  XCTAssertTrue(documentWrapper.fromDeviceCache);
}

- (void)testReadAppDocumentFromLocalDatabaseWithDeserializationError {

  // If
  NSString *documentId = @"12829";
  NSString *eTag = @"398";
  NSString *jsonString = @"{";
  [self addJsonStringToTable:jsonString
                        eTag:eTag
                   partition:self.appToken.partition
                  documentId:documentId
            pendingOperation:@""
              expirationTime:(long)[[NSDate dateWithTimeIntervalSinceNow:1000000] timeIntervalSince1970]];

  // When
  MSDocumentWrapper *documentWrapper = [self.sut readWithToken:self.appToken
                                                    documentId:documentId
                                                  documentType:[MSDictionaryDocument class]];

  // Then
  XCTAssertNotNil(documentWrapper);
  XCTAssertNotNil(documentWrapper.error);
  XCTAssertFalse(documentWrapper.fromDeviceCache);
  XCTAssertEqualObjects(documentWrapper.documentId, documentId);
}

- (void)testReadNoExpirationAppDocument {

  // If
  NSString *documentId = @"12829";
  NSString *eTag = @"398";
  NSString *jsonString = @"{ \"document\": {\"key\": \"value\"}}";
  [self addJsonStringToTable:jsonString
                        eTag:eTag
                   partition:self.appToken.partition
                  documentId:documentId
            pendingOperation:@""
              expirationTime:kMSDataStoreTimeToLiveInfinite];

  // When
  MSDocumentWrapper *documentWrapper = [self.sut readWithToken:self.appToken
                                                    documentId:documentId
                                                  documentType:[MSDictionaryDocument class]];

  // Then
  XCTAssertNotNil(documentWrapper);
  XCTAssertNil(documentWrapper.error);
  XCTAssertTrue(documentWrapper.fromDeviceCache);
  NSDictionary *retrievedContentDictionary = ((MSDictionaryDocument *)(documentWrapper.deserializedValue)).dictionary;
  XCTAssertEqualObjects(retrievedContentDictionary[@"key"], @"value");
}

- (void)testReadExpiredAppDocument {

  // If
  NSString *documentId = @"12829";
  NSString *eTag = @"398";
  NSString *jsonString = @"{ \"document\": {\"key\": \"value\"}}";
  [self addJsonStringToTable:jsonString
                        eTag:eTag
                   partition:self.appToken.partition
                  documentId:documentId
            pendingOperation:@""
              expirationTime:0];

  // When
  MSDocumentWrapper *documentWrapper = [self.sut readWithToken:self.appToken
                                                    documentId:documentId
                                                  documentType:[MSDictionaryDocument class]];

  // Then
  XCTAssertNotNil(documentWrapper);
  XCTAssertNotNil(documentWrapper.error);
  XCTAssertFalse(documentWrapper.fromDeviceCache);
  XCTAssertEqualObjects(documentWrapper.error.error.domain, kMSACDataStoreErrorDomain);
  XCTAssertEqual(documentWrapper.error.error.code, MSACDataStoreErrorLocalDocumentExpired);
  XCTAssertEqualObjects(documentWrapper.documentId, documentId);
  OCMVerify([self.sut deleteWithToken:self.appToken documentId:documentId]);
}

- (void)testReadUserDocumentFromLocalDatabaseNotFound {

  // If
  NSString *documentId = @"12829";
  MSDictionaryDocument *document = [[MSDictionaryDocument alloc] initFromDictionary:@{@"key" : @"value"}];
  MSDBDocumentStore *sut = [MSDBDocumentStore new];
  [self.sut createUserStorageWithAccountId:self.userToken.accountId];

  // When
  MSDocumentWrapper *documentWrapper = [sut readWithToken:self.userToken documentId:documentId documentType:[document class]];

  // Then
  XCTAssertNotNil(documentWrapper);
  XCTAssertNotNil(documentWrapper.error);
  XCTAssertFalse(documentWrapper.fromDeviceCache);
  XCTAssertEqualObjects(documentWrapper.error.error.domain, kMSACDataStoreErrorDomain);
  XCTAssertEqual(documentWrapper.error.error.code, MSACDataStoreErrorDocumentNotFound);
  XCTAssertEqualObjects(documentWrapper.documentId, documentId);
}

- (void)testUpsertReplacesCorrectlyInAppStorage {

  // If
  MSDocumentWrapper *expectedDocumentWrapper = [MSDocumentUtils documentWrapperFromData:[self jsonFixture:@"validTestDocument"]
                                                                           documentType:[MSDictionaryDocument class]
                                                                        fromDeviceCache:YES];

  // When
  // Upsert twice to ensure that replacement is correct.
  [self.sut upsertWithToken:self.appToken
            documentWrapper:expectedDocumentWrapper
                  operation:@"REPLACE"
           deviceTimeToLive:kMSDataStoreTimeToLiveInfinite];

  // If
  // Mock the document wrapper to appear to have a different eTag now.
  MSDocumentWrapper *mockDocumentWrapper = OCMPartialMock(expectedDocumentWrapper);
  NSString *expectedEtag = @"the new etag";
  OCMStub(mockDocumentWrapper.eTag).andReturn(expectedEtag);

  // When
  [self.sut upsertWithToken:self.appToken
            documentWrapper:expectedDocumentWrapper
                  operation:@"REPLACE"
           deviceTimeToLive:kMSDataStoreTimeToLiveInfinite];

  // Then
  // Ensure that there is exactly one entry in the cache with the given document ID and partition name.
  NSString *tableName = [MSDBDocumentStore tableNameForPartition:self.appToken.partition];
  NSArray<NSArray *> *result = [self.dbStorage
      executeSelectionQuery:[NSString stringWithFormat:@"SELECT * FROM \"%@\" WHERE \"%@\" = \"%@\" AND \"%@\" = \"%@\"", tableName,
                                                       kMSDocumentIdColumnName, expectedDocumentWrapper.documentId, kMSPartitionColumnName,
                                                       self.appToken.partition]];
  XCTAssertEqual(result.count, 1);
  XCTAssertEqualObjects(expectedEtag, result[0][self.sut.eTagColumnIndex]);
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

- (void)testUpsertAppDocumentWithValidTTL {

  // If
  int ttl = 1;
  MSDocumentWrapper *expectedDocumentWrapper = [MSDocumentUtils documentWrapperFromData:[self jsonFixture:@"validTestDocument"]
                                                                           documentType:[MSDictionaryDocument class]
                                                                        fromDeviceCache:YES];

  // Mock NSDate to "freeze" time.
  NSTimeInterval timeSinceReferenceDate = NSDate.timeIntervalSinceReferenceDate;
  id nsdateMock = OCMClassMock([NSDate class]);
  OCMStub(ClassMethod([nsdateMock timeIntervalSinceReferenceDate])).andReturn(timeSinceReferenceDate);

  // When
  BOOL result = [self.sut upsertWithToken:self.appToken documentWrapper:expectedDocumentWrapper operation:@"CREATE" deviceTimeToLive:ttl];
  MSDocumentWrapper *documentWrapper = [self.sut readWithToken:self.appToken
                                                    documentId:expectedDocumentWrapper.documentId
                                                  documentType:[MSDictionaryDocument class]];

  // Then
  XCTAssertTrue(result);
  XCTAssertNil(documentWrapper.error);
  XCTAssertTrue(documentWrapper.fromDeviceCache);
  XCTAssertNotNil(documentWrapper.deserializedValue);
  XCTAssertNotNil(documentWrapper.jsonValue);
  XCTAssertEqualObjects(documentWrapper.documentId, expectedDocumentWrapper.documentId);
  XCTAssertEqualObjects(documentWrapper.partition, expectedDocumentWrapper.partition);
  XCTAssertEqualObjects(documentWrapper.eTag, expectedDocumentWrapper.eTag);
  long expirationTime = [self expirationTimeWithToken:self.appToken documentId:expectedDocumentWrapper.documentId];
  XCTAssertEqual(expirationTime, (long)(ttl + NSTimeIntervalSince1970 + timeSinceReferenceDate));
}

- (void)testUpsertAppDocumentWithNoTTL {

  // If
  MSDocumentWrapper *documentWrapper = [MSDocumentUtils documentWrapperFromData:[self jsonFixture:@"validTestDocument"]
                                                                   documentType:[MSDictionaryDocument class]
                                                                fromDeviceCache:YES];

  // When
  BOOL result = [self.sut upsertWithToken:self.appToken
                          documentWrapper:documentWrapper
                                operation:@"CREATE"
                         deviceTimeToLive:kMSDataStoreTimeToLiveInfinite];
  MSDocumentWrapper *expectedDocumentWrapper = [self.sut readWithToken:self.appToken
                                                            documentId:documentWrapper.documentId
                                                          documentType:[MSDictionaryDocument class]];

  // Then
  XCTAssertTrue(result);
  XCTAssertNil(expectedDocumentWrapper.error);
  XCTAssertTrue(documentWrapper.fromDeviceCache);
  XCTAssertNotNil(expectedDocumentWrapper.deserializedValue);
  XCTAssertNotNil(expectedDocumentWrapper.jsonValue);
  XCTAssertEqualObjects(expectedDocumentWrapper.documentId, documentWrapper.documentId);
  XCTAssertEqualObjects(expectedDocumentWrapper.partition, documentWrapper.partition);
  XCTAssertEqualObjects(expectedDocumentWrapper.eTag, documentWrapper.eTag);
  long expirationTime = [self expirationTimeWithToken:self.appToken documentId:expectedDocumentWrapper.documentId];
  XCTAssertEqual(expirationTime, kMSDataStoreTimeToLiveInfinite);
}

- (void)testDeleteAppDocumentForNonExistentDocument {

  // If, When
  BOOL result = [self.sut deleteWithToken:self.appToken documentId:@"some-non-existing-document-id"];
  MSDocumentWrapper *expectedDocumentWrapper = [self.sut readWithToken:self.appToken
                                                            documentId:@"some-non-existing-document-id"
                                                          documentType:[MSDictionaryDocument class]];

  // Then, should succeed but be a no-op
  XCTAssertTrue(result);
  XCTAssertNotNil(expectedDocumentWrapper.error);
  XCTAssertFalse(expectedDocumentWrapper.fromDeviceCache);
}

- (void)testDeleteExistingAppDocument {

  // If
  MSDocumentWrapper *documentWrapper = [MSDocumentUtils documentWrapperFromData:[self jsonFixture:@"validTestDocument"]
                                                                   documentType:[MSDictionaryDocument class]
                                                                fromDeviceCache:YES];
  [self.sut upsertWithToken:self.appToken documentWrapper:documentWrapper operation:@"CREATE" deviceTimeToLive:1];
  MSDocumentWrapper *expectedDocumentWrapper = [self.sut readWithToken:self.appToken
                                                            documentId:documentWrapper.documentId
                                                          documentType:[MSDictionaryDocument class]];
  XCTAssertNil(expectedDocumentWrapper.error);
  XCTAssertTrue(expectedDocumentWrapper.fromDeviceCache);

  // When
  BOOL result = [self.sut deleteWithToken:self.appToken documentId:documentWrapper.documentId];
  expectedDocumentWrapper = [self.sut readWithToken:self.appToken
                                         documentId:documentWrapper.documentId
                                       documentType:[MSDictionaryDocument class]];

  // Then
  XCTAssertTrue(result);
  XCTAssertNotNil(expectedDocumentWrapper.error);
  XCTAssertFalse(expectedDocumentWrapper.fromDeviceCache);
}

- (void)testDeleteExistingUserDocument {

  // If
  MSDocumentWrapper *documentWrapper = [MSDocumentUtils documentWrapperFromData:[self jsonFixture:@"validTestDocument"]
                                                                   documentType:[MSDictionaryDocument class]
                                                                fromDeviceCache:YES];
  [self.sut createUserStorageWithAccountId:self.userToken.accountId];
  [self.sut upsertWithToken:self.userToken documentWrapper:documentWrapper operation:@"CREATE" deviceTimeToLive:1];
  MSDocumentWrapper *expectedDocumentWrapper = [self.sut readWithToken:self.userToken
                                                            documentId:documentWrapper.documentId
                                                          documentType:[MSDictionaryDocument class]];
  XCTAssertNil(expectedDocumentWrapper.error);
  XCTAssertTrue(documentWrapper.fromDeviceCache);

  // When
  BOOL result = [self.sut deleteWithToken:self.userToken documentId:documentWrapper.documentId];
  expectedDocumentWrapper = [self.sut readWithToken:self.userToken
                                         documentId:documentWrapper.documentId
                                       documentType:[MSDictionaryDocument class]];

  // Then
  XCTAssertTrue(result);
  XCTAssertNotNil(expectedDocumentWrapper.error);
  XCTAssertFalse(expectedDocumentWrapper.fromDeviceCache);
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
              expirationTime:(long)expirationTime {
  sqlite3 *db = [self openDatabase:kMSDBDocumentFileName];
  long operationTimeString = NSTimeIntervalSince1970;
  NSString *insertQuery = [NSString stringWithFormat:@"INSERT INTO \"%@\" (\"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\") "
                                                     @"VALUES ('%@', '%@', '%@', '%@', '%@', %ld, '%ld', '%@')",
                                                     kMSAppDocumentTableName, kMSIdColumnName, kMSPartitionColumnName, kMSETagColumnName,
                                                     kMSDocumentColumnName, kMSDocumentIdColumnName, kMSExpirationTimeColumnName,
                                                     kMSOperationTimeColumnName, kMSPendingOperationColumnName, @0, partition, eTag,
                                                     jsonString, documentId, (long)expirationTime, operationTimeString, pendingOperation];
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

- (long)expirationTimeWithToken:(MSTokenResult *)token documentId:(NSString *)documentId {
  NSString *tableName = [MSDBDocumentStore tableNameForPartition:token.partition];
  NSArray<NSArray *> *result = [self.dbStorage
      executeSelectionQuery:[NSString stringWithFormat:@"SELECT \"%@\" FROM \"%@\" WHERE \"%@\" = \"%@\" AND \"%@\" = \"%@\"",
                                                       kMSExpirationTimeColumnName, tableName, kMSDocumentIdColumnName, documentId,
                                                       kMSPartitionColumnName, token.partition]];
  return [((NSNumber *)result[0][0]) longValue];
}

@end
