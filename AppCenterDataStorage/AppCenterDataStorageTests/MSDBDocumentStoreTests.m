// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDBDocumentStorePrivate.h"
#import "MSDBStoragePrivate.h"
#import "MSDataStore.h"
#import "MSDocumentUtils.h"
#import "MSReadOptions.h"
#import "MSTestDocument.h"
#import "MSTestFrameworks.h"

@interface MSDBDocumentStoreTests : XCTestCase

@property(nonatomic) MSDBDocumentStore *sut;

@end

@implementation MSDBDocumentStoreTests

- (void)setUp {
  [super setUp];
  self.sut = [MSDBDocumentStore new];
}

- (void)tearDown {
  [super tearDown];
  [self.sut.dbStorage dropTable:kMSAppDocumentTableName];
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
  OCMVerify([dbStorageMock createTable:tableName columnsSchema:[MSDBDocumentStore columnsSchema]]);
}

- (void)testDeletionOfUserLevelTable {

  // If
  NSString *expectedAccountId = @"Test-account-id";
  NSString *userTableName = [NSString stringWithFormat:kMSUserDocumentTableNameFormat, expectedAccountId];

  // When
  id dbStorageMock = OCMClassMock([MSDBStorage class]);
  self.sut.dbStorage = dbStorageMock;
  [self.sut deleteUserStorageWithAccountId:expectedAccountId];

  // Then
  OCMVerify([dbStorageMock dropTable:userTableName]);
}

- (void)testUpsertWithPartition {

  // If
  MSDocumentWrapper *documentWrapper = [MSDocumentUtils documentWrapperFromData:[MSTestDocument getDocumentFixture:@"validTestDocument"]
                                                                   documentType:[MSTestDocument class]];

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
  BOOL result = [self.sut deleteWithPartition:MSDataStoreUserDocumentsPartition documentId:@"some-document-id"];

  // Then, should succeed but be a no-op
  XCTAssertTrue(result);
}

- (void)testDeleteWithPartitionForExistingDocument {

  // If
  MSDocumentWrapper *documentWrapper = [MSDocumentUtils documentWrapperFromData:[MSTestDocument getDocumentFixture:@"validTestDocument"]
                                                                   documentType:[MSTestDocument class]];
  [self.sut upsertWithPartition:MSDataStoreAppDocumentsPartition
                documentWrapper:documentWrapper
                      operation:@"CREATE"
                        options:[[MSReadOptions alloc] initWithDeviceTimeToLive:1]];

  // When
  BOOL result = [self.sut deleteWithPartition:MSDataStoreUserDocumentsPartition documentId:documentWrapper.documentId];

  // Then
  XCTAssertTrue(result);
}

@end
