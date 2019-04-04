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
#import "MSDBStoragePrivate.h"

@interface MSDBDocumentStoreTests : XCTestCase

@property(nonatomic) id dbStorageMock;
@property(nonatomic, nullable) MSDBDocumentStore *sut;

@end

@implementation MSDBDocumentStoreTests

- (void)setUp {
  [super setUp];
  [MSUtility deleteItemForPathComponent:kMSDBDocumentFileName];
  self.sut = [MSDBDocumentStore new];
  self.dbStorageMock = OCMClassMock([MSDBStorage class]);
  self.sut.dbStorage = self.dbStorageMock;
}

- (void)tearDown {
  [MSUtility deleteItemForPathComponent:kMSDBDocumentFileName];
  [self.dbStorageMock stopMocking];
  [super tearDown];
}

- (void)testReadUserDocumentFromLocalDatabase {

  // If
  NSString *documentId = @"12829";
  NSString *partitionKey = @"partition1234123";
  MSMockDocument *document = [MSMockDocument new];
  NSString *accountId = @"dabe069b-ee80-4ca6-8657-9128a4600958";
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

- (void)testCreateOfApplicationLevelTable {

  // If
  NSUInteger expectedSchemaVersion = 1;
  MSDBSchema *expectedSchema = @{kMSAppDocumentTableName : [self expectedTableSchema]};
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

- (void)testCreateOfUserLevelTable {

  // If
  NSString *expectedAccountId = @"Test-account-id";
  MSDBSchema *expectedSchema =
      @{[NSString stringWithFormat:kMSUserDocumentTableNameFormat, expectedAccountId] : [self expectedTableSchema]};

  // When
  [self.sut createUserStorageWithAccountId:expectedAccountId];

  // Then
  OCMVerify([self.dbStorageMock createTablesWithSchema:expectedSchema]);
}

- (void)testDeleteOfUserLevelTable {

  // If
  NSString *expectedAccountId = @"Test-account-id";
  NSString *userTableName = [NSString stringWithFormat:kMSUserDocumentTableNameFormat, expectedAccountId];

  // When
  [self.sut deleteUserStorageWithAccountId:expectedAccountId];

  // Then
  OCMVerify([self.dbStorageMock dropTable:userTableName]);
}

- (NSArray<NSDictionary<NSString *, NSArray<NSString *> *> *> *)expectedTableSchema {

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
@end
