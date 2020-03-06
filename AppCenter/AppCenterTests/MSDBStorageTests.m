// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <sqlite3.h>

#import "MSDBStoragePrivate.h"
#import "MSStorageBindableArray.h"
#import "MSStorageTestUtil.h"
#import "MSTestFrameworks.h"
#import "MSUtility+Date.h"
#import "MSUtility+File.h"

#define DOCUMENTS [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]

static NSString *const kMSTestTableName = @"table";
static NSString *const kMSTestPositionColName = @"position";
static NSString *const kMSTestPersonColName = @"person";
static NSString *const kMSTestHungrinessColName = @"hungriness";
static NSString *const kMSTestMealColName = @"meal";
static NSString *const kMSTestDBFileName = @"Test.sqlite";

// 40 KiB (10 pages by 4 KiB).
static const long kMSTestStorageSizeMinimumUpperLimitInBytes = 40 * 1024;

@interface MSDBStorageTests : XCTestCase

@property(nonatomic) MSDBStorage *sut;
@property(nonatomic) MSDBSchema *schema;
@property(nonatomic) MSStorageTestUtil *storageTestUtil;

@end

@implementation MSDBStorageTests

- (void)setUp {
  [super setUp];
  self.schema = @{
    kMSTestTableName : @[
      @{kMSTestPositionColName : @[ kMSSQLiteTypeInteger, kMSSQLiteConstraintPrimaryKey, kMSSQLiteConstraintAutoincrement ]},
      @{kMSTestPersonColName : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]}, @{kMSTestHungrinessColName : @[ kMSSQLiteTypeInteger ]},
      @{kMSTestMealColName : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]}
    ]
  };
  self.storageTestUtil = [[MSStorageTestUtil alloc] initWithDbFileName:kMSTestDBFileName];
  [self.storageTestUtil deleteDatabase];
  self.sut = [[MSDBStorage alloc] initWithSchema:self.schema version:0 filename:kMSTestDBFileName];
}

- (void)tearDown {
  [self.storageTestUtil deleteDatabase];
  [super tearDown];
}

- (void)testInitWithSchema {

  // If
  NSString *testTableName = @"test_table", *testColumnName = @"test_column", *testColumn2Name = @"test_column2";
  NSString *expectedResult =
      [NSString stringWithFormat:@"CREATE TABLE \"%@\" (\"%@\" %@ %@ %@, \"%@\" %@ %@)", testTableName, testColumnName,
                                 kMSSQLiteTypeInteger, kMSSQLiteConstraintPrimaryKey, kMSSQLiteConstraintAutoincrement, testColumn2Name,
                                 kMSSQLiteTypeText, kMSSQLiteConstraintNotNull];
  MSDBSchema *testSchema = @{
    testTableName : @[
      @{testColumnName : @[ kMSSQLiteTypeInteger, kMSSQLiteConstraintPrimaryKey, kMSSQLiteConstraintAutoincrement ]},
      @{testColumn2Name : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]}
    ]
  };
  id result;

  // When
  self.sut = [[MSDBStorage alloc] initWithSchema:testSchema version:0 filename:kMSTestDBFileName];
  result = [self queryTable:testTableName];

  // Then
  assertThat(result, is(expectedResult));

  // If
  [self.storageTestUtil deleteDatabase];
  NSString *testTableName2 = @"test2_table", *testColumnName2 = @"test2_column";
  testSchema = @{
    testTableName : @[
      @{testColumnName : @[ kMSSQLiteTypeInteger, kMSSQLiteConstraintPrimaryKey, kMSSQLiteConstraintAutoincrement ]},
      @{testColumn2Name : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]}
    ],
    testTableName2 : @[ @{testColumnName2 : @[ kMSSQLiteTypeInteger, kMSSQLiteConstraintNotNull ]} ]
  };
  NSString *expectedResult2 = [NSString stringWithFormat:@"CREATE TABLE \"%@\" (\"%@\" %@ %@)", testTableName2, testColumnName2,
                                                         kMSSQLiteTypeInteger, kMSSQLiteConstraintNotNull];
  id result2;

  // When
  self.sut = [[MSDBStorage alloc] initWithSchema:testSchema version:0 filename:kMSTestDBFileName];
  result = [self queryTable:testTableName];
  result2 = [self queryTable:testTableName2];

  // Then
  assertThat(result, is(expectedResult));
  assertThat(result2, is(expectedResult2));
}

- (void)testSqliteConfigurationErrorAfterInit {

  // when
  int configResult = [MSDBStorage configureSQLite];

  // Then
  assertThatInt(configResult, equalToInt(SQLITE_MISUSE));
}

- (void)testTableExists {
  [self.sut executeQueryUsingBlock:^int(void *db) {
    // When
    BOOL tableExists = [MSDBStorage tableExists:kMSTestTableName inOpenedDatabase:db];

    // Then
    assertThatBool(tableExists, isTrue());

    // If
    NSString *query = [NSString stringWithFormat:@"DROP TABLE \"%@\"", kMSTestTableName];
    [MSDBStorage executeNonSelectionQuery:query inOpenedDatabase:db withValues:nil];

    // When
    tableExists = [MSDBStorage tableExists:kMSTestTableName inOpenedDatabase:db];

    // Then
    assertThatBool(tableExists, isFalse());

    return 0;
  }];
}

- (void)testVersion {
  [self.sut executeQueryUsingBlock:^int(void *db) {
    int result = 0;

    // When
    NSUInteger version = [MSDBStorage versionInOpenedDatabase:db result:&result];

    // Then
    assertThatUnsignedInteger(version, equalToUnsignedInt(0));

    // When
    [MSDBStorage setVersion:1 inOpenedDatabase:db];
    version = [MSDBStorage versionInOpenedDatabase:db result:&result];

    // Then
    assertThatUnsignedInteger(version, equalToUnsignedInt(1));

    return 0;
  }];

  // After re-open.
  [self.sut executeQueryUsingBlock:^int(void *db) {
    // When
    int result = 0;
    NSUInteger version = [MSDBStorage versionInOpenedDatabase:db result:&result];

    // Then
    assertThatUnsignedInteger(version, equalToUnsignedInt(1));

    return 0;
  }];
}

- (void)testMigration {

  // If
  id dbStorage = OCMPartialMock(self.sut);
  OCMExpect([dbStorage migrateDatabase:[OCMArg anyPointer] fromVersion:0]);

  // When
  (void)[dbStorage initWithSchema:self.schema version:1 filename:kMSTestDBFileName];

  // Then
  OCMVerifyAll(dbStorage);

  // If
  // Migrate shouldn't be called in a new database.
  [self.storageTestUtil deleteDatabase];
  OCMReject([[dbStorage ignoringNonObjectArgs] migrateDatabase:[OCMArg anyPointer] fromVersion:0]);

  // When
  (void)[dbStorage initWithSchema:self.schema version:2 filename:kMSTestDBFileName];

  // Then
  OCMVerifyAll(dbStorage);
}

- (void)testGetMaxPageCountInOpenedDatabaseReturnsZeroWhenQueryFails {

  // If
  // Query returns empty array.
  id dbStorageMock = OCMClassMock([MSDBStorage class]);
  sqlite3 *db = [self.storageTestUtil openDatabase];
  NSMutableArray<NSMutableArray *> *entries = [NSMutableArray<NSMutableArray *> new];
  OCMStub([dbStorageMock executeSelectionQuery:[OCMArg any] inOpenedDatabase:db withValues:OCMOCK_ANY]).andReturn(entries);

  // When
  long counter = [MSDBStorage getMaxPageCountInOpenedDatabase:db];

  // Then
  assertThatLong(counter, equalToLong(0));

  // If
  // Query returns an array with empty array.
  [entries addObject:[NSMutableArray new]];
  OCMStub([dbStorageMock executeSelectionQuery:[OCMArg any] inOpenedDatabase:db withValues:OCMOCK_ANY]).andReturn(entries);

  // When
  counter = [MSDBStorage getMaxPageCountInOpenedDatabase:db];

  // Then
  assertThatLong(counter, equalToLong(0));
}

- (void)testGetPageCountInOpenedDatabaseReturnsZeroWhenQueryFails {

  // If
  // Query returns empty array.
  id dbStorageMock = OCMClassMock([MSDBStorage class]);
  sqlite3 *db = [self.storageTestUtil openDatabase];
  NSMutableArray<NSMutableArray *> *entries = [NSMutableArray<NSMutableArray *> new];
  OCMStub([dbStorageMock executeSelectionQuery:[OCMArg any] inOpenedDatabase:db withValues:OCMOCK_ANY]).andReturn(entries);

  // When
  long counter = [MSDBStorage getPageCountInOpenedDatabase:db];

  // Then
  assertThatLong(counter, equalToLong(0));

  // If
  // Query returns an array with empty array.
  [entries addObject:[NSMutableArray new]];
  OCMStub([dbStorageMock executeSelectionQuery:[OCMArg any] inOpenedDatabase:db withValues:OCMOCK_ANY]).andReturn(entries);

  // When
  counter = [MSDBStorage getPageCountInOpenedDatabase:db];

  // Then
  assertThatLong(counter, equalToLong(0));
}

- (void)testGetPageSizeInOpenedDatabaseReturnsZeroWhenQueryFails {

  // If
  // Query returns empty array.
  id dbStorageMock = OCMClassMock([MSDBStorage class]);
  sqlite3 *db = [self.storageTestUtil openDatabase];
  NSMutableArray<NSMutableArray *> *entries = [NSMutableArray<NSMutableArray *> new];
  OCMStub([dbStorageMock executeSelectionQuery:[OCMArg any] inOpenedDatabase:db withValues:OCMOCK_ANY]).andReturn(entries);

  // When
  long counter = [MSDBStorage getPageSizeInOpenedDatabase:db];

  // Then
  assertThatLong(counter, equalToLong(0));

  // If
  // Query returns an array with empty array.
  [entries addObject:[NSMutableArray new]];
  OCMStub([dbStorageMock executeSelectionQuery:[OCMArg any] inOpenedDatabase:db withValues:OCMOCK_ANY]).andReturn(entries);

  // When
  counter = [MSDBStorage getPageSizeInOpenedDatabase:db];

  // Then
  assertThatLong(counter, equalToLong(0));
}

- (void)testEnableAutoVacuumInOpenedDatabaseWhenQueryFails {

  // If
  // Query returns empty array.
  id dbStorageMock = OCMClassMock([MSDBStorage class]);
  sqlite3 *db = [self.storageTestUtil openDatabase];
  NSMutableArray<NSMutableArray *> *entries = [NSMutableArray<NSMutableArray *> new];
  OCMStub([dbStorageMock executeSelectionQuery:[OCMArg any] inOpenedDatabase:db withValues:OCMOCK_ANY]).andReturn(entries);
  OCMStub([dbStorageMock executeNonSelectionQuery:[OCMArg any] inOpenedDatabase:db withValues:OCMOCK_ANY]);

  // When
  [MSDBStorage enableAutoVacuumInOpenedDatabase:db];

  // Then
  OCMVerify([dbStorageMock executeSelectionQuery:[OCMArg any] inOpenedDatabase:db withValues:OCMOCK_ANY]);

  // If
  // Query returns an array with empty array.
  [entries addObject:[NSMutableArray new]];
  OCMStub([dbStorageMock executeSelectionQuery:[OCMArg any] inOpenedDatabase:db withValues:OCMOCK_ANY]).andReturn(entries);

  // When
  [MSDBStorage enableAutoVacuumInOpenedDatabase:db];

  // Then
  OCMVerify([dbStorageMock executeSelectionQuery:[OCMArg any] inOpenedDatabase:db withValues:OCMOCK_ANY]);
}

- (void)testCreateTableWhenTableExists {

  // Then
  XCTAssertTrue([self tableExists:kMSTestTableName]);

  // When
  BOOL tableExistsOrCreated = [self.sut createTable:kMSTestTableName columnsSchema:self.schema[kMSTestTableName]];

  // Then
  XCTAssertTrue(tableExistsOrCreated);
  XCTAssertTrue([self tableExists:kMSTestTableName]);
}

- (void)testCreateTableWhenTableDoesntExists {

  // If
  NSString *tableToCreate = @"NewTable";

  // When
  BOOL tableExistsOrCreated = [self.sut createTable:tableToCreate columnsSchema:self.schema[kMSTestTableName]];

  // Then
  XCTAssertTrue(tableExistsOrCreated);
  XCTAssertTrue([self tableExists:tableToCreate]);
}

- (void)testDropTableWhenTableExists {

  // When
  BOOL tableDropped = [self.sut dropTable:kMSTestTableName];

  // Then
  XCTAssertTrue(tableDropped);
  XCTAssertFalse([self tableExists:kMSTestTableName]);
}

- (void)testDropDatabase {

  // If
  NSString *tableName1 = @"shortLivedTabled1";
  NSString *tableName2 = @"shortLivedTabled2";

  // When
  XCTAssertTrue([self.sut createTable:tableName1 columnsSchema:self.schema[kMSTestTableName]]);
  XCTAssertTrue([self tableExists:tableName1]);
  XCTAssertTrue([self.sut createTable:tableName2 columnsSchema:self.schema[kMSTestTableName]]);
  XCTAssertTrue([self tableExists:tableName2]);
  [self.sut dropDatabase];

  // Then
  XCTAssertFalse([self.sut.dbFileURL checkResourceIsReachableAndReturnError:nil]);
  XCTAssertFalse([self tableExists:tableName1]);
  XCTAssertFalse([self tableExists:tableName2]);
}

- (void)testDroppedTableWhenTableDoesNotExists {

  // If
  NSString *tableToDrop = @"NewTable";

  // When
  BOOL tableDropped = [self.sut dropTable:tableToDrop];

  // Then
  XCTAssertTrue(tableDropped);
  XCTAssertFalse([self tableExists:tableToDrop]);
}

- (void)testExecuteQuery {

  // If
  NSString *expectedPerson = @"Hungry Guy";
  NSNumber *expectedHungriness = @(99);
  NSString *expectedMeal = @"Big burger";
  NSString *query = [NSString stringWithFormat:@"INSERT INTO \"%@\" (\"%@\", \"%@\", \"%@\") "
                                               @"VALUES (?, ?, ?)",
                                               kMSTestTableName, kMSTestPersonColName, kMSTestHungrinessColName, kMSTestMealColName];
  MSStorageBindableArray *array = [MSStorageBindableArray new];
  [array addString:expectedPerson];
  [array addString:expectedHungriness.stringValue];
  [array addString:expectedMeal];
  int result;
  NSArray *entry;

  // When
  result = [self.sut executeNonSelectionQuery:query withValues:array];

  // Then
  assertThatInteger(result, equalToInt(SQLITE_OK));

  // If
  query = [NSString stringWithFormat:@"SELECT * FROM \"%@\"", kMSTestTableName];

  // When
  entry = [self.sut executeSelectionQuery:query withValues:nil];

  // Then
  assertThat(entry, is(@[ @[ @(1), expectedPerson, expectedHungriness, expectedMeal ] ]));

  // If
  expectedMeal = @"Gigantic burger";
  query = [NSString
      stringWithFormat:@"UPDATE \"%@\" SET \"%@\" = ? WHERE \"%@\" = ?", kMSTestTableName, kMSTestMealColName, kMSTestPositionColName];

  // When
  array = [MSStorageBindableArray new];
  [array addString:expectedMeal];
  [array addNumber:@(1)];
  result = [self.sut executeNonSelectionQuery:query withValues:array];

  // Then
  assertThatInteger(result, equalToInt(SQLITE_OK));

  // If
  query = [NSString stringWithFormat:@"SELECT * FROM \"%@\"", kMSTestTableName];

  // When
  entry = [self.sut executeSelectionQuery:query withValues:nil];

  // Then
  assertThat(entry, is(@[ @[ @(1), expectedPerson, expectedHungriness, expectedMeal ] ]));

  // If
  query = [NSString stringWithFormat:@"DELETE FROM \"%@\" WHERE \"%@\" = ?;", kMSTestTableName, kMSTestPositionColName];

  // When
  array = [MSStorageBindableArray new];
  [array addNumber:@(1)];
  result = [self.sut executeNonSelectionQuery:query withValues:array];

  // Then
  assertThatInteger(result, equalToInt(SQLITE_OK));

  // If
  query = [NSString stringWithFormat:@"SELECT * FROM \"%@\"", kMSTestTableName];

  // When
  entry = [self.sut executeSelectionQuery:query withValues:nil];

  // Then
  assertThat(entry, is(@[]));
}

- (void)testRetrieveMultipleEntries {

  // If
  id expectedGuys = [self addGuysToTheTableWithCount:20];

  // When
  id result = [self.sut executeSelectionQuery:[NSString stringWithFormat:@"SELECT * FROM \"%@\"", kMSTestTableName] withValues:nil];

  // Then
  assertThat(result, is(expectedGuys));
}

- (void)testCount {

  // If
  NSUInteger count;

  // When
  count = [self.sut countEntriesForTable:kMSTestTableName condition:nil withValues:nil];

  // Then
  assertThatUnsignedInteger(count, equalToInt(0));

  // If
  NSString *expectedPerson = @"Hungry Guy";
  NSNumber *expectedHungriness = @(99);
  NSString *expectedMeal = @"Big burger";
  NSString *query = [NSString stringWithFormat:@"INSERT INTO \"%@\" (\"%@\", \"%@\", \"%@\") "
                                               @"VALUES (?, ?, ?)",
                                               kMSTestTableName, kMSTestPersonColName, kMSTestHungrinessColName, kMSTestMealColName];
  MSStorageBindableArray *array = [MSStorageBindableArray new];
  [array addString:expectedPerson];
  [array addString:expectedHungriness.stringValue];
  [array addString:expectedMeal];
  [self.sut executeNonSelectionQuery:query withValues:array];

  // When
  count = [self.sut countEntriesForTable:kMSTestTableName condition:nil withValues:nil];

  // Then
  assertThatUnsignedInteger(count, equalToInt(1));

  // If
  expectedPerson = @"Hungry Man";
  expectedMeal = @"Huge raclette";
  query = [NSString stringWithFormat:@"INSERT INTO \"%@\" (\"%@\", \"%@\", \"%@\") "
                                     @"VALUES (?, ?, ?)",
                                     kMSTestTableName, kMSTestPersonColName, kMSTestHungrinessColName, kMSTestMealColName];
  array = [MSStorageBindableArray new];
  [array addString:expectedPerson];
  [array addString:expectedHungriness.stringValue];
  [array addString:expectedMeal];
  [self.sut executeNonSelectionQuery:query withValues:array];

  // When
  count = [self.sut countEntriesForTable:kMSTestTableName condition:nil withValues:nil];

  // Then
  assertThatUnsignedInteger(count, equalToInt(2));

  // When
  array = [MSStorageBindableArray new];
  [array addString:expectedMeal];
  count = [self.sut countEntriesForTable:kMSTestTableName
                               condition:[NSString stringWithFormat:@"\"%@\" = ?", kMSTestMealColName]
                              withValues:array];

  // Then
  assertThatUnsignedInteger(count, equalToInt(1));
}

#pragma mark - Set storage size

- (void)testSetStorageSizeFailsWhenShrinkingDatabaseIsAttempted {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler invoked."];

  // Fill the database with data to reach the desired initial size.
  while ([self.storageTestUtil getDataLengthInBytes] < kMSTestStorageSizeMinimumUpperLimitInBytes) {
    [self addGuysToTheTableWithCount:1000];
  }
  long bytesOfData = [self.storageTestUtil getDataLengthInBytes];
  long shrunkenSizeInBytes = bytesOfData - 12 * 1024;

  // When
  __weak typeof(self) weakSelf = self;
  [weakSelf.sut setMaxStorageSize:shrunkenSizeInBytes
                completionHandler:^(BOOL success) {
                  // Then
                  XCTAssertFalse(success);
                  [expectation fulfill];
                }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testSetStorageSizePassesWhenSizeIsGreaterThanCurrentBytesOfActualData {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler invoked."];
  __block BOOL actualSuccess = NO;

  // Fill the database with data to reach the desired initial size.
  while ([self.storageTestUtil getDataLengthInBytes] < kMSTestStorageSizeMinimumUpperLimitInBytes) {
    [self addGuysToTheTableWithCount:1000];
  }
  long bytesOfData = [self.storageTestUtil getDataLengthInBytes];
  NSLog(@"bytes of data: %ld", bytesOfData);
  long expandedSizeInBytes = bytesOfData + 12 * 1024;

  // When
  [self.sut setMaxStorageSize:expandedSizeInBytes
            completionHandler:^(BOOL success) {
              actualSuccess = success;
              [expectation fulfill];
            }];

  // Open DB to trigger completion handler.
  [self.sut executeQueryUsingBlock:^(__unused void *db) {
    return SQLITE_OK;
  }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *_Nullable error) {
                                 // Then
                                 XCTAssertTrue(actualSuccess);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testMaximumPageCountDoesNotChangeWhenShrinkingDatabaseIsAttempted {

  // If
  const long initialMaxSize = self.sut.maxSizeInBytes;
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler invoked."];

  // Fill the database with data to reach the desired initial size.
  while ([self.storageTestUtil getDataLengthInBytes] < kMSTestStorageSizeMinimumUpperLimitInBytes) {
    [self addGuysToTheTableWithCount:1000];
  }
  long bytesOfData = [self.storageTestUtil getDataLengthInBytes];
  long shrunkenSizeInBytes = bytesOfData - 12 * 1024;

  // When
  __weak typeof(self) weakSelf = self;
  [weakSelf.sut setMaxStorageSize:shrunkenSizeInBytes
                completionHandler:^(__unused BOOL success) {
                  // Then
                  typeof(self) strongSelf = weakSelf;
                  XCTAssertEqual(initialMaxSize, strongSelf.sut.maxSizeInBytes);
                  [expectation fulfill];
                }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testCompletionHandlerCanBeNil {

  // When
  [self.sut setMaxStorageSize:4 * 1024 completionHandler:nil];
  [self addGuysToTheTableWithCount:100];

  // Then
  // Didn't crash.
}

- (void)testNewDatabaseIsAutoVacuumed {

  // Then
  XCTAssertTrue([self autoVacuumIsSetToFull]);
}

- (void)testNonAutoVacuumingDatabaseIsManuallyVacuumedAndAutoVacuumedWhenInitialized {

  // If

  // Reset database and ensure that auto_vacuum is disabled.
  [self.storageTestUtil deleteDatabase];
  sqlite3 *db = [self.storageTestUtil openDatabase];
  sqlite3_exec(db, "PRAGMA auto_vacuum = NONE; VACUUM", NULL, NULL, NULL);
  sqlite3_close(db);

  // When
  self.sut = [[MSDBStorage alloc] initWithSchema:self.schema version:0 filename:kMSTestDBFileName];

  // Then
  XCTAssertTrue([self autoVacuumIsSetToFull]);
}

- (void)testDatabaseThatIsAutoVacuumedNotManuallyVacuumedWhenInitialized {

  // If

  // Reset database and ensure that auto_vacuum is enabled.
  [self.storageTestUtil deleteDatabase];
  sqlite3 *db = [self.storageTestUtil openDatabase];
  sqlite3_exec(db, "PRAGMA auto_vacuum = FULL; VACUUM", NULL, NULL, NULL);
  sqlite3_close(db);
  id dbStorageMock = OCMClassMock([MSDBStorage class]);

  // Then
  OCMReject([dbStorageMock executeNonSelectionQuery:@"VACUUM" inOpenedDatabase:[OCMArg anyPointer] withValues:OCMOCK_ANY]);

  // When
  self.sut = [[MSDBStorage alloc] initWithSchema:self.schema version:0 filename:kMSTestDBFileName];
}

- (void)testDatabaseThatFileWasCorrupted {

  // If
  const char *validFileHeader = "SQLite format 3";
  NSURL *fileURL = [MSUtility fullURLForPathComponent:kMSTestDBFileName];
  NSData *data = [NSData dataWithContentsOfURL:fileURL];

  // Check that database file is valid.
  XCTAssertEqual(strcmp((const char *)data.bytes, validFileHeader), 0);

  // Corrupt the file.
  NSMutableData *mutabledata = [[NSData dataWithContentsOfURL:fileURL] mutableCopy];
  *((unsigned int *)mutabledata.mutableBytes) = 0xDEADBEEF;
  [mutabledata writeToURL:fileURL atomically:YES];

  // When
  self.sut = [[MSDBStorage alloc] initWithSchema:self.schema version:1 filename:kMSTestDBFileName];

  // Then
  // The database should be recreated.
  data = [NSData dataWithContentsOfURL:fileURL];
  XCTAssertEqual(strcmp((const char *)data.bytes, validFileHeader), 0);
}

- (void)testInitWithSchemaWithErrorResult {

  // If
  id mockMSDBStorage = OCMClassMock([MSDBStorage class]);
  OCMStub([mockMSDBStorage versionInOpenedDatabase:[OCMArg anyPointer] result:[OCMArg anyPointer]]).andDo(^(NSInvocation *invocation) {
    int *result;
    [invocation getArgument:&result atIndex:3];
    *result = SQLITE_ERROR;
  });
  OCMReject([mockMSDBStorage createTablesWithSchema:OCMOCK_ANY inOpenedDatabase:[OCMArg anyPointer]]);

  // When
  self.sut = [[MSDBStorage alloc] initWithSchema:self.schema version:1 filename:kMSTestDBFileName];

  // Then
  OCMVerifyAll(mockMSDBStorage);

  // Clear
  [mockMSDBStorage stopMocking];
}

- (void)testSetMaxPageCountReturnError {

  // If
  id mockMSDBStorage = OCMClassMock([MSDBStorage class]);
  OCMStub([mockMSDBStorage executeSelectionQuery:containsSubstring(@"PRAGMA max_page_count =")
                                inOpenedDatabase:[OCMArg anyPointer]
                                          result:[OCMArg setToValue:OCMOCK_VALUE((int){SQLITE_CORRUPT})]
                                      withValues:OCMOCK_ANY])
      .andReturn(@[]);

  // When
  self.sut = [[MSDBStorage alloc] initWithSchema:self.schema version:1 filename:kMSTestDBFileName];
  int result = [self.sut executeQueryUsingBlock:^int(void *_Nonnull __unused db) {
    return SQLITE_OK;
  }];

  // Then
  XCTAssertEqual(SQLITE_CORRUPT, result);

  // Clear
  [mockMSDBStorage stopMocking];
}

#pragma mark - Private

- (NSArray *)addGuysToTheTableWithCount:(short)guysCount {
  NSString *insertQuery;
  NSMutableArray *guys = [NSMutableArray new];
  sqlite3 *db = [self.storageTestUtil openDatabase];
  for (short i = 1; i <= guysCount; i++) {
    [guys addObject:@[
      @(i), [NSString stringWithFormat:@"%@%d", kMSTestPersonColName, i], @(arc4random_uniform(100)),
      [NSString stringWithFormat:@"%@%d", kMSTestMealColName, i]
    ]];
    insertQuery = [NSString stringWithFormat:@"INSERT INTO '%@' ('%@', '%@', '%@') VALUES ('%@', '%@', '%@')", kMSTestTableName,
                                             kMSTestPersonColName, kMSTestHungrinessColName, kMSTestMealColName, [guys lastObject][1],
                                             [[guys lastObject][2] stringValue], [guys lastObject][3]];
    sqlite3_exec(db, [insertQuery UTF8String], NULL, NULL, NULL);
  }
  sqlite3_close(db);
  return guys;
}

- (NSString *)queryTable:(NSString *)tableName {
  return [self.sut executeSelectionQuery:[NSString stringWithFormat:@"SELECT sql FROM sqlite_master WHERE name='%@'", tableName]
                              withValues:nil][0][0];
}

- (BOOL)tableExists:(NSString *)tableName {
  NSArray<NSArray *> *result = [self.sut
      executeSelectionQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM \"sqlite_master\" WHERE \"type\"='table' AND \"name\"='%@';",
                                                       tableName]
                 withValues:nil];
  return [(NSNumber *)result[0][0] boolValue];
}

- (BOOL)autoVacuumIsSetToFull {
  int autoVacuumFullState = 1;
  sqlite3 *db = [self.storageTestUtil openDatabase];
  sqlite3_stmt *statement = NULL;
  sqlite3_prepare_v2(db, "PRAGMA auto_vacuum", -1, &statement, NULL);
  sqlite3_step(statement);
  NSNumber *autoVacuum = @(sqlite3_column_int(statement, 0));
  sqlite3_finalize(statement);
  sqlite3_close(db);
  return [autoVacuum intValue] == autoVacuumFullState;
}
@end
