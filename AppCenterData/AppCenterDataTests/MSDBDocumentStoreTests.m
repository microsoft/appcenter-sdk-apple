// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <sqlite3.h>

#import "MSDBDocumentStorePrivate.h"
#import "MSDBStoragePrivate.h"
#import "MSData.h"
#import "MSDataError.h"
#import "MSDataErrors.h"
#import "MSDictionaryDocument.h"
#import "MSDocumentUtils.h"
#import "MSDocumentWrapperInternal.h"
#import "MSPaginatedDocuments.h"
#import "MSPendingOperation.h"
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
  self.appToken = [[MSTokenResult alloc] initWithPartition:kMSDataAppDocumentsPartition
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

- (void)testListAppDocumentsInfiniteTTL {

  // If
  NSString *documentId = @"12829";
  NSString *eTag = @"398";
  NSString *jsonString = @"{\"key\": \"value\"}";
  NSString *pendingOperation = kMSPendingOperationReplace;
  [self addJsonStringToTable:jsonString
                        eTag:eTag
                   partition:self.appToken.partition
                  documentId:documentId
            pendingOperation:pendingOperation
              expirationTime:kMSDataTimeToLiveInfinite
              documentNumber:@0];

  // deleted document shouldn't be returned by list
  NSString *pendingDeleteOperation = kMSPendingOperationDelete;
  NSString *documentId2 = @"deleted-doc";
  [self addJsonStringToTable:jsonString
                        eTag:eTag
                   partition:self.appToken.partition
                  documentId:documentId2
            pendingOperation:pendingDeleteOperation
              expirationTime:kMSDataTimeToLiveInfinite
              documentNumber:@1];

  // When
  MSPaginatedDocuments *paginated = [self.sut listWithToken:self.appToken
                                                  partition:self.appToken.partition
                                               documentType:[MSDictionaryDocument class]
                                                baseOptions:nil];

  // Then
  XCTAssertNotNil(paginated);
  XCTAssertNotNil(paginated.currentPage);
  XCTAssertNil(paginated.currentPage.error);
  XCTAssertNotNil(paginated.currentPage.items);
  XCTAssertEqual(1, paginated.currentPage.items.count);
  MSDocumentWrapper *retrievedDocumentWrapper = (MSDocumentWrapper *)paginated.currentPage.items[0];
  NSDictionary *retrievedContentDictionary = ((MSDictionaryDocument *)(paginated.currentPage.items[0].deserializedValue)).dictionary;
  XCTAssertTrue(retrievedDocumentWrapper.fromDeviceCache);
  XCTAssertEqualObjects(retrievedContentDictionary[@"key"], @"value");
  XCTAssertEqualObjects(retrievedDocumentWrapper.partition, self.appToken.partition);
  XCTAssertEqualObjects(retrievedDocumentWrapper.documentId, documentId);
  XCTAssertEqualObjects(retrievedDocumentWrapper.pendingOperation, pendingOperation);
  XCTAssertTrue(retrievedDocumentWrapper.fromDeviceCache);
}

- (void)testListWithExpiredAppDocument {

  // If
  NSString *documentId = @"12829";
  NSString *eTag = @"398";
  NSString *jsonString = @"{\"key\": \"value\"}";
  NSString *pendingOperation = kMSPendingOperationReplace;
  [self addJsonStringToTable:jsonString
                        eTag:eTag
                   partition:self.appToken.partition
                  documentId:documentId
            pendingOperation:pendingOperation
              expirationTime:0];

  // When
  MSPaginatedDocuments *paginated = [self.sut listWithToken:self.appToken
                                                  partition:self.appToken.partition
                                               documentType:[MSDictionaryDocument class]
                                                baseOptions:nil];

  // Then
  XCTAssertNotNil(paginated);
  XCTAssertNotNil(paginated.currentPage);
  XCTAssertNil(paginated.currentPage.error);
  XCTAssertNotNil(paginated.currentPage.items);
  XCTAssertEqual(0, paginated.currentPage.items.count);
  OCMVerify([self.sut deleteWithToken:self.appToken documentId:documentId]);
}

- (void)testReadAppDocumentFromLocalDatabase {

  // If
  NSString *documentId = @"12829";
  NSString *eTag = @"398";
  NSString *jsonString = @"{\"key\": \"value\"}";
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
  NSString *jsonString = @"{\"key\": \"value\"}";
  [self addJsonStringToTable:jsonString
                        eTag:eTag
                   partition:self.appToken.partition
                  documentId:documentId
            pendingOperation:@""
              expirationTime:kMSDataTimeToLiveInfinite];

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
  NSString *jsonString = @"{\"key\": \"value\"}";
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
  XCTAssertEqualObjects(documentWrapper.error.domain, kMSACDataErrorDomain);
  XCTAssertEqual(documentWrapper.error.code, MSACDataErrorLocalDocumentExpired);
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
  XCTAssertEqualObjects(documentWrapper.error.domain, kMSACDataErrorDomain);
  XCTAssertEqual(documentWrapper.error.code, MSACDataErrorDocumentNotFound);
  XCTAssertEqualObjects(documentWrapper.documentId, documentId);
}

- (void)testUpsertReplacesCorrectlyInAppStorage {

  // If
  MSDocumentWrapper *expectedDocumentWrapper = [MSDocumentUtils documentWrapperFromData:[self jsonFixture:@"validTestAppDocument"]
                                                                           documentType:[MSDictionaryDocument class]
                                                                              partition:kMSDataAppDocumentsPartition
                                                                             documentId:@"standalonedocument1"
                                                                        fromDeviceCache:YES];

  // When
  // Upsert twice to ensure that replacement is correct.
  [self.sut upsertWithToken:self.appToken
            documentWrapper:expectedDocumentWrapper
                  operation:@"REPLACE"
           deviceTimeToLive:kMSDataTimeToLiveInfinite];

  // If
  // Mock the document wrapper to appear to have a different eTag now.
  MSDocumentWrapper *mockDocumentWrapper = OCMPartialMock(expectedDocumentWrapper);
  NSString *expectedEtag = @"the new etag";
  OCMStub(mockDocumentWrapper.eTag).andReturn(expectedEtag);

  // When
  [self.sut upsertWithToken:self.appToken
            documentWrapper:expectedDocumentWrapper
                  operation:@"REPLACE"
           deviceTimeToLive:kMSDataTimeToLiveInfinite];

  // Then
  // Ensure that there is exactly one entry in the cache with the given document ID and partition name.
  NSString *tableName = [MSDBDocumentStore tableNameForPartition:self.appToken.partition];
  NSString *queryMask = [NSString stringWithFormat:@"SELECT * FROM \"%@\" WHERE \"%@\" = \"?\" AND \"%@\" = \"?\"", tableName,
                                                   kMSDocumentIdColumnName, kMSPartitionColumnName];
  NSArray *values = {expectedDocumentWrapper.documentId, self.appToken.partition};
  NSArray<NSArray *> *result = [self.dbStorage executeSelectionQuery:queryMask withValues:values];
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
  MSDocumentWrapper *expectedDocumentWrapper = [MSDocumentUtils documentWrapperFromData:[self jsonFixture:@"validTestAppDocument"]
                                                                           documentType:[MSDictionaryDocument class]
                                                                              partition:kMSDataAppDocumentsPartition
                                                                             documentId:@"standalonedocument1"
                                                                        fromDeviceCache:YES];

  // Mock NSDate to "freeze" time.
  NSTimeInterval timeSinceReferenceDate = NSDate.timeIntervalSinceReferenceDate;
  NSDate *referenceDate = [NSDate dateWithTimeIntervalSince1970:timeSinceReferenceDate];
  id nsdateMock = OCMClassMock([NSDate class]);
  OCMStub(ClassMethod([nsdateMock timeIntervalSinceReferenceDate])).andReturn(timeSinceReferenceDate);
  OCMStub(ClassMethod([nsdateMock date])).andReturn(referenceDate);

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
  [nsdateMock stopMocking];
}

- (void)testUpsertAppDocumentWithNoTTL {

  // If
  MSDocumentWrapper *documentWrapper = [MSDocumentUtils documentWrapperFromData:[self jsonFixture:@"validTestAppDocument"]
                                                                   documentType:[MSDictionaryDocument class]
                                                                      partition:kMSDataAppDocumentsPartition
                                                                     documentId:@"standalonedocument1"
                                                                fromDeviceCache:YES];

  // When
  BOOL result = [self.sut upsertWithToken:self.appToken
                          documentWrapper:documentWrapper
                                operation:@"CREATE"
                         deviceTimeToLive:kMSDataTimeToLiveInfinite];
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
  XCTAssertEqual(expirationTime, kMSDataTimeToLiveInfinite);
}

- (void)testUpsertWontChangeLastUpdatedDate {

  // If
  long lastUpdateDateLong = (long)[[NSDate date] timeIntervalSince1970];
  NSDate *lastUpdateDate = [NSDate dateWithTimeIntervalSince1970:lastUpdateDateLong];
  MSDocumentWrapper *documentWrapper = [[MSDocumentWrapper alloc] initWithDeserializedValue:[MSDictionaryDocument alloc]
                                                                                  jsonValue:@"{\"key\" : \"value\"}"
                                                                                  partition:kMSDataAppDocumentsPartition
                                                                                 documentId:@"documentId"
                                                                                       eTag:@"myEtag"
                                                                            lastUpdatedDate:lastUpdateDate
                                                                           pendingOperation:kMSPendingOperationCreate
                                                                            fromDeviceCache:YES];
  // When
  BOOL result = [self.sut upsertWithToken:self.appToken
                          documentWrapper:documentWrapper
                                operation:documentWrapper.pendingOperation
                         deviceTimeToLive:kMSDataTimeToLiveInfinite];
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
  XCTAssertEqualObjects(expectedDocumentWrapper.lastUpdatedDate, documentWrapper.lastUpdatedDate);
}

- (void)testUpsertWithNilLastUpdatedDate {

  // If
  MSDocumentWrapper *documentWrapper = [[MSDocumentWrapper alloc] initWithDeserializedValue:[MSDictionaryDocument alloc]
                                                                                  jsonValue:@"{\"key\" : \"value\"}"
                                                                                  partition:kMSDataAppDocumentsPartition
                                                                                 documentId:@"documentId"
                                                                                       eTag:@"myEtag"
                                                                            lastUpdatedDate:nil
                                                                           pendingOperation:kMSPendingOperationCreate
                                                                            fromDeviceCache:YES];
  // When
  BOOL result = [self.sut upsertWithToken:self.appToken
                          documentWrapper:documentWrapper
                                operation:documentWrapper.pendingOperation
                         deviceTimeToLive:kMSDataTimeToLiveInfinite];
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
  XCTAssertNil(expectedDocumentWrapper.lastUpdatedDate);
}

- (void)testUpsertWithNilEtag {

  // If
  long lastUpdateDateLong = (long)[[NSDate date] timeIntervalSince1970];
  NSDate *lastUpdateDate = [NSDate dateWithTimeIntervalSince1970:lastUpdateDateLong];
  MSDocumentWrapper *documentWrapper = [[MSDocumentWrapper alloc] initWithDeserializedValue:[MSDictionaryDocument alloc]
                                                                                  jsonValue:@"{\"key\" : \"value\"}"
                                                                                  partition:kMSDataAppDocumentsPartition
                                                                                 documentId:@"documentId"
                                                                                       eTag:nil
                                                                            lastUpdatedDate:lastUpdateDate
                                                                           pendingOperation:kMSPendingOperationCreate
                                                                            fromDeviceCache:YES];
  // When
  BOOL result = [self.sut upsertWithToken:self.appToken
                          documentWrapper:documentWrapper
                                operation:documentWrapper.pendingOperation
                         deviceTimeToLive:kMSDataTimeToLiveInfinite];
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
  XCTAssertNil(expectedDocumentWrapper.eTag);
  XCTAssertEqualObjects(expectedDocumentWrapper.lastUpdatedDate, documentWrapper.lastUpdatedDate);
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
  MSDocumentWrapper *documentWrapper = [MSDocumentUtils documentWrapperFromData:[self jsonFixture:@"validTestAppDocument"]
                                                                   documentType:[MSDictionaryDocument class]
                                                                      partition:@"user-123"
                                                                     documentId:@"standalonedocument1"
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
  MSDocumentWrapper *documentWrapper = [MSDocumentUtils documentWrapperFromData:[self jsonFixture:@"validTestUserDocument"]
                                                                   documentType:[MSDictionaryDocument class]
                                                                      partition:@"user-123"
                                                                     documentId:@"standalonedocument1"
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

- (void)testResetDatabase {

  // If
  NSString *expectedAccountId = @"Test-account-id";
  NSString *tableName = [NSString stringWithFormat:kMSUserDocumentTableNameFormat, expectedAccountId];
  [self.sut createUserStorageWithAccountId:expectedAccountId];
  OCMVerify([self.dbStorage createTable:tableName columnsSchema:[MSDBDocumentStore columnsSchema]]);
  XCTAssertTrue([self tableExists:tableName]);
  XCTAssertTrue([self tableExists:kMSAppDocumentTableName]);

  // When
  [self.sut resetDatabase];

  // Then
  XCTAssertTrue([self.dbStorage.dbFileURL checkResourceIsReachableAndReturnError:nil]);
  XCTAssertFalse([self tableExists:tableName]);
  XCTAssertTrue([self tableExists:kMSAppDocumentTableName]);
}

- (void)testNoPendingOperations {

  // If DB is empty

  // Then
  XCTAssertEqual([[self.sut pendingOperationsWithToken:self.appToken] count], 0);
}

- (void)testGetPendingOperations {

  // If
  NSString *documentId1 = @"doc_id_1";
  NSString *eTag = @"123456789";
  NSString *jsonString = @"{\"key\": \"value\"}";
  NSString *pendingOperation = kMSPendingOperationReplace;
  [self addJsonStringToTable:jsonString
                        eTag:eTag
                   partition:self.appToken.partition
                  documentId:documentId1
            pendingOperation:pendingOperation
              expirationTime:(long)[[NSDate dateWithTimeIntervalSinceNow:1000000] timeIntervalSince1970]];
  NSString *documentId2 = @"doc_id_2";
  [self addJsonStringToTable:jsonString
                        eTag:eTag
                   partition:self.appToken.partition
                  documentId:documentId2
            pendingOperation:nil
              expirationTime:(long)[[NSDate dateWithTimeIntervalSinceNow:1000000] timeIntervalSince1970]];

  // When
  NSArray<MSPendingOperation *> *pendingOperations = [self.sut pendingOperationsWithToken:self.appToken];

  // Then
  XCTAssertEqual([pendingOperations count], 1);
  XCTAssertTrue([pendingOperations[0].documentId isEqualToString:documentId1]);
}

- (void)testGetExpiredPendingOperations {

  // If
  NSString *documentId1 = @"doc_id_1";
  NSString *eTag = @"123456789";
  NSString *jsonString = @"{ \"document\": {\"key\": \"value\"}}";
  NSString *pendingOperation = kMSPendingOperationReplace;
  [self addJsonStringToTable:jsonString
                        eTag:eTag
                   partition:self.appToken.partition
                  documentId:documentId1
            pendingOperation:pendingOperation
              expirationTime:(long)[[NSDate dateWithTimeIntervalSinceNow:-1000] timeIntervalSince1970]];

  // When
  NSArray<MSPendingOperation *> *pendingOperations = [self.sut pendingOperationsWithToken:self.appToken];

  // Then
  XCTAssertEqual([pendingOperations count], 0);
}

- (void)addJsonStringToTable:(NSString *)jsonString
                        eTag:(NSString *)eTag
                   partition:(NSString *)partition
                  documentId:(NSString *)documentId
            pendingOperation:(NSString *)pendingOperation
              expirationTime:(long)expirationTime {
  [self addJsonStringToTable:jsonString
                        eTag:eTag
                   partition:partition
                  documentId:documentId
            pendingOperation:pendingOperation
              expirationTime:expirationTime
              documentNumber:@0];
}

- (void)addJsonStringToTable:(NSString *)jsonString
                        eTag:(NSString *)eTag
                   partition:(NSString *)partition
                  documentId:(NSString *)documentId
            pendingOperation:(NSString *)pendingOperation
              expirationTime:(long)expirationTime
              documentNumber:(NSNumber *)documentNumber {
  sqlite3 *db = [self openDatabase:kMSDBDocumentFileName];
  long operationTimeString = NSTimeIntervalSince1970;
  NSString *insertQuery =
      [NSString stringWithFormat:@"INSERT INTO \"%@\" (\"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\") "
                                 @"VALUES ('%@', '%@', '%@', '%@', '%@', %ld, '%ld', '%@')",
                                 kMSAppDocumentTableName, kMSIdColumnName, kMSPartitionColumnName, kMSETagColumnName, kMSDocumentColumnName,
                                 kMSDocumentIdColumnName, kMSExpirationTimeColumnName, kMSOperationTimeColumnName,
                                 kMSPendingOperationColumnName, documentNumber, partition, eTag, jsonString, documentId,
                                 (long)expirationTime, operationTimeString, pendingOperation];
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
  NSArray<NSArray *> *result =
      [self.dbStorage executeSelectionQuery:@"SELECT COUNT(*) FROM \"sqlite_master\" WHERE \"type\"='table' AND \"name\"='%@';"
                                 withValues:tableName];
  return [(NSNumber *)result[0][0] boolValue];
}

- (NSArray<NSString *> *)expectedUniqueColumnsConstraint {
  return @[ kMSPartitionColumnName, kMSDocumentIdColumnName ];
}

- (long)expirationTimeWithToken:(MSTokenResult *)token documentId:(NSString *)documentId {
  NSString *tableName = [MSDBDocumentStore tableNameForPartition:token.partition];
  NSArray *values = {documentId, token.partition};
  NSArray<NSArray *> *result =
      [self.dbStorage executeSelectionQuery:[NSString stringWithFormat:@"SELECT \"%@\" FROM \"%@\" WHERE \"%@\" = \"?\" AND \"%@\" = \"?\"",
                                                                       kMSExpirationTimeColumnName, tableName, kMSDocumentIdColumnName,
                                                                       kMSPartitionColumnName]
                                 withValues:values];
  return [((NSNumber *)result[0][0]) longValue];
}

@end
