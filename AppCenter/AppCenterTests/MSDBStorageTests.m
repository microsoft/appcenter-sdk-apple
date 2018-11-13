#import <sqlite3.h>

#import "MSDBStoragePrivate.h"
#import "MSStorageTestUtil.h"
#import "MSTestFrameworks.h"

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

- (void)testTableExists {
  [self.sut executeQueryUsingBlock:^int(void *db) {

    // When
    BOOL tableExists = [MSDBStorage tableExists:kMSTestTableName inOpenedDatabase:db];

    // Then
    assertThatBool(tableExists, isTrue());

    // If
    NSString *query = [NSString stringWithFormat:@"DROP TABLE \"%@\"", kMSTestTableName];
    [MSDBStorage executeNonSelectionQuery:query inOpenedDatabase:db];

    // When
    tableExists = [MSDBStorage tableExists:kMSTestTableName inOpenedDatabase:db];

    // Then
    assertThatBool(tableExists, isFalse());

    return 0;
  }];
}

- (void)testVersion {
  [self.sut executeQueryUsingBlock:^int(void *db) {

    // When
    NSUInteger version = [MSDBStorage versionInOpenedDatabase:db];

    // Then
    assertThatUnsignedInteger(version, equalToUnsignedInt(0));

    // When
    [MSDBStorage setVersion:1 inOpenedDatabase:db];
    version = [MSDBStorage versionInOpenedDatabase:db];

    // Then
    assertThatUnsignedInteger(version, equalToUnsignedInt(1));

    return 0;
  }];

  // After re-open.
  [self.sut executeQueryUsingBlock:^int(void *db) {

    // When
    NSUInteger version = [MSDBStorage versionInOpenedDatabase:db];

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

- (void)testExecuteQuery {

  // If
  NSString *expectedPerson = @"Hungry Guy";
  NSNumber *expectedHungriness = @(99);
  NSString *expectedMeal = @"Big burger";
  NSString *query = [NSString stringWithFormat:@"INSERT INTO \"%@\" (\"%@\", \"%@\", \"%@\") "
                                               @"VALUES ('%@', %@, '%@')",
                                               kMSTestTableName, kMSTestPersonColName, kMSTestHungrinessColName, kMSTestMealColName,
                                               expectedPerson, expectedHungriness.stringValue, expectedMeal];
  int result;
  NSArray *entry;

  // When
  result = [self.sut executeNonSelectionQuery:query];

  // Then
  assertThatInteger(result, equalToInt(SQLITE_OK));

  // If
  query = [NSString stringWithFormat:@"SELECT * FROM \"%@\"", kMSTestTableName];

  // When
  entry = [self.sut executeSelectionQuery:query];

  // Then
  assertThat(entry, is(@[ @[ @(1), expectedPerson, expectedHungriness, expectedMeal ] ]));

  // If
  expectedMeal = @"Gigantic burger";
  query = [NSString stringWithFormat:@"UPDATE \"%@\" SET \"%@\" = '%@' WHERE \"%@\" = %d", kMSTestTableName, kMSTestMealColName,
                                     expectedMeal, kMSTestPositionColName, 1];

  // When
  result = [self.sut executeNonSelectionQuery:query];

  // Then
  assertThatInteger(result, equalToInt(SQLITE_OK));

  // If
  query = [NSString stringWithFormat:@"SELECT * FROM \"%@\"", kMSTestTableName];

  // When
  entry = [self.sut executeSelectionQuery:query];

  // Then
  assertThat(entry, is(@[ @[ @(1), expectedPerson, expectedHungriness, expectedMeal ] ]));

  // If
  query = [NSString stringWithFormat:@"DELETE FROM \"%@\" WHERE \"%@\" = %d;", kMSTestTableName, kMSTestPositionColName, 1];

  // When
  result = [self.sut executeNonSelectionQuery:query];

  // Then
  assertThatInteger(result, equalToInt(SQLITE_OK));

  // If
  query = [NSString stringWithFormat:@"SELECT * FROM \"%@\"", kMSTestTableName];

  // When
  entry = [self.sut executeSelectionQuery:query];

  // Then
  assertThat(entry, is(@[]));
}

- (void)testRetrieveMultipleEntries {

  // If
  id expectedGuys = [self addGuysToTheTableWithCount:20];

  // When
  id result = [self.sut executeSelectionQuery:[NSString stringWithFormat:@"SELECT * FROM \"%@\"", kMSTestTableName]];

  // Then
  assertThat(result, is(expectedGuys));
}

- (void)testCount {

  // If
  NSUInteger count;

  // When
  count = [self.sut countEntriesForTable:kMSTestTableName condition:nil];

  // Then
  assertThatUnsignedInteger(count, equalToInt(0));

  // If
  NSString *expectedPerson = @"Hungry Guy";
  NSNumber *expectedHungriness = @(99);
  NSString *expectedMeal = @"Big burger";
  NSString *query = [NSString stringWithFormat:@"INSERT INTO \"%@\" (\"%@\", \"%@\", \"%@\") "
                                               @"VALUES ('%@', %@, '%@')",
                                               kMSTestTableName, kMSTestPersonColName, kMSTestHungrinessColName, kMSTestMealColName,
                                               expectedPerson, expectedHungriness.stringValue, expectedMeal];
  [self.sut executeNonSelectionQuery:query];

  // When
  count = [self.sut countEntriesForTable:kMSTestTableName condition:nil];

  // Then
  assertThatUnsignedInteger(count, equalToInt(1));

  // If
  expectedPerson = @"Hungry Man";
  expectedMeal = @"Huge raclette";
  query = [NSString stringWithFormat:@"INSERT INTO \"%@\" (\"%@\", \"%@\", \"%@\") "
                                     @"VALUES ('%@', %@, '%@')",
                                     kMSTestTableName, kMSTestPersonColName, kMSTestHungrinessColName, kMSTestMealColName, expectedPerson,
                                     expectedHungriness.stringValue, expectedMeal];
  [self.sut executeNonSelectionQuery:query];

  // When
  count = [self.sut countEntriesForTable:kMSTestTableName condition:nil];

  // Then
  assertThatUnsignedInteger(count, equalToInt(2));

  // When
  count = [self.sut countEntriesForTable:kMSTestTableName
                               condition:[NSString stringWithFormat:@"\"%@\" = '%@'", kMSTestMealColName, expectedMeal]];

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

              // Then
              XCTAssertTrue(success);
              [expectation fulfill];
            }];

  // Open DB to trigger completion handler.
  [self.sut executeQueryUsingBlock:^(__unused void *db) {
    return SQLITE_OK;
  }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *_Nullable error) {
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
  OCMReject([dbStorageMock executeNonSelectionQuery:@"VACUUM" inOpenedDatabase:[OCMArg anyPointer]]);

  // When
  self.sut = [[MSDBStorage alloc] initWithSchema:self.schema version:0 filename:kMSTestDBFileName];
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
  return [self.sut executeSelectionQuery:[NSString stringWithFormat:@"SELECT sql FROM sqlite_master WHERE name='%@'", tableName]][0][0];
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
