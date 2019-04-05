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

@end

@implementation MSDBDocumentStoreTests

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

  // When
  MSDBDocumentStore *sut = [MSDBDocumentStore new];

  // Then
  OCMVerify([MSDBStorage columnsIndexes:expectedSchema]);
  XCTAssertEqual([expectedColumnIndexes[kMSAppDocumentTableName][kMSIdColumnName] integerValue], sut.idColumnIndex);
  XCTAssertEqual([expectedColumnIndexes[kMSAppDocumentTableName][kMSPartitionColumnName] integerValue], sut.partitionColumnIndex);
  XCTAssertEqual([expectedColumnIndexes[kMSAppDocumentTableName][kMSDocumentIdColumnName] integerValue], sut.documentIdColumnIndex);
  XCTAssertEqual([expectedColumnIndexes[kMSAppDocumentTableName][kMSDocumentColumnName] integerValue], sut.documentColumnIndex);
  XCTAssertEqual([expectedColumnIndexes[kMSAppDocumentTableName][kMSETagColumnName] integerValue], sut.eTagColumnIndex);
  XCTAssertEqual([expectedColumnIndexes[kMSAppDocumentTableName][kMSExpirationTimeColumnName] integerValue], sut.expirationTimeColumnIndex);
  XCTAssertEqual([expectedColumnIndexes[kMSAppDocumentTableName][kMSDownloadTimeColumnName] integerValue], sut.downloadTimeColumnIndex);
  XCTAssertEqual([expectedColumnIndexes[kMSAppDocumentTableName][kMSOperationTimeColumnName] integerValue], sut.operationTimeColumnIndex);
  XCTAssertEqual([expectedColumnIndexes[kMSAppDocumentTableName][kMSPendingOperationColumnName] integerValue],
                 sut.pendingOperationColumnIndex);
}

- (void)testCreationOfUserLevelTable {

  // If
  NSString *expectedAccountId = @"Test-account-id";
  NSString *tableName = [NSString stringWithFormat:kMSUserDocumentTableNameFormat, expectedAccountId];

  // When
  id dbStorageMock = OCMClassMock([MSDBStorage class]);
  MSDBDocumentStore *sut = [MSDBDocumentStore new];
  sut.dbStorage = dbStorageMock;
  [sut createUserStorageWithAccountId:expectedAccountId];

  // Then
  OCMVerify([dbStorageMock createTable:tableName columnsSchema:[MSDBDocumentStore columnsSchema]]);
}

- (void)testDeletionOfUserLevelTable {

  // If
  NSString *expectedAccountId = @"Test-account-id";
  NSString *userTableName = [NSString stringWithFormat:kMSUserDocumentTableNameFormat, expectedAccountId];

  // When
  id dbStorageMock = OCMClassMock([MSDBStorage class]);
  MSDBDocumentStore *sut = [MSDBDocumentStore new];
  sut.dbStorage = dbStorageMock;
  [sut deleteUserStorageWithAccountId:expectedAccountId];

  // Then
  OCMVerify([dbStorageMock dropTable:userTableName]);
}

- (void)testUpsertWithPartition {

  // If
  MSDocumentWrapper *documentWrapper = [MSDocumentUtils documentWrapperFromData:[MSTestDocument getDocumentFixture:@"validTestDocument"]
                                                                   documentType:[MSTestDocument class]];

  // When
  MSDBDocumentStore *sut = [MSDBDocumentStore new];
  BOOL result = [sut upsertWithPartition:MSDataStoreAppDocumentsPartition
                         documentWrapper:documentWrapper
                               operation:@"CREATE"
                                 options:[[MSReadOptions alloc] initWithDeviceTimeToLive:1]];

  // Then
  XCTAssertTrue(result);
  // TODO: also validate with read when we have it.
}

- (void)testDeleteWithPartitionForNonExistentDocument {

  // If, When
  MSDBDocumentStore *sut = [MSDBDocumentStore new];
  BOOL result = [sut deleteWithPartition:MSDataStoreUserDocumentsPartition documentId:@"documentid"];

  // Then
  XCTAssertFalse(result);
}

- (void)testDeleteWithPartitionForExistingDocument {

  // If
  MSDocumentWrapper *documentWrapper = [MSDocumentUtils documentWrapperFromData:[MSTestDocument getDocumentFixture:@"validTestDocument"]
                                                                   documentType:[MSTestDocument class]];
  MSDBDocumentStore *sut = [MSDBDocumentStore new];
  [sut upsertWithPartition:MSDataStoreAppDocumentsPartition
           documentWrapper:documentWrapper
                 operation:@"CREATE"
                   options:[[MSReadOptions alloc] initWithDeviceTimeToLive:1]];

  // When
  BOOL result = [sut deleteWithPartition:MSDataStoreUserDocumentsPartition documentId:documentWrapper.documentId];

  // Then
  XCTAssertTrue(result);
}

@end
