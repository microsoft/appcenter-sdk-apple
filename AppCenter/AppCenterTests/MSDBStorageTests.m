#import "MSDBStoragePrivate.h"
#import "MSTestFrameworks.h"
#import "MSUtility+File.h"

static NSString *const kMSTestDBFileName = @"Test.sqlite";
static NSString *const kMSTestTableName = @"table";
static NSString *const kMSTestPositionColName = @"position";
static NSString *const kMSTestPersonColName = @"person";
static NSString *const kMSTestHungrinessColName = @"hungriness";
static NSString *const kMSTestMealColName = @"meal";

@interface MSDBStorageTests : XCTestCase

@property(nonatomic) MSDBStorage *sut;
@property(nonatomic) MSDBSchema *schema;

@end

@implementation MSDBStorageTests

- (void)setUp {
  [super setUp];
  self.schema = @{
    kMSTestTableName : @[
      @{
        kMSTestPositionColName : @[
          kMSSQLiteTypeInteger, kMSSQLiteConstraintPrimaryKey,
          kMSSQLiteConstraintAutoincrement
        ]
      },
      @{
        kMSTestPersonColName :
            @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]
      },
      @{kMSTestHungrinessColName : @[ kMSSQLiteTypeInteger ]}, @{
        kMSTestMealColName :
            @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]
      }
    ]
  };
  self.sut = [[MSDBStorage alloc] initWithSchema:self.schema
                                         version:0
                                        filename:kMSTestDBFileName];
}

- (void)tearDown {
  [self.sut deleteDatabase];
  [super tearDown];
}

- (void)testInitWithSchema {

  // If
  [self.sut deleteDatabase];
  NSString *testTableName = @"test_table", *testColumnName = @"test_column",
           *testColumn2Name = @"test_column2";
  NSString *expectedResult = [NSString
      stringWithFormat:@"CREATE TABLE \"%@\" (\"%@\" %@ %@ %@, \"%@\" %@ %@)",
                       testTableName, testColumnName, kMSSQLiteTypeInteger,
                       kMSSQLiteConstraintPrimaryKey,
                       kMSSQLiteConstraintAutoincrement, testColumn2Name,
                       kMSSQLiteTypeText, kMSSQLiteConstraintNotNull];
  MSDBSchema *testSchema = @{
    testTableName : @[
      @{
        testColumnName : @[
          kMSSQLiteTypeInteger, kMSSQLiteConstraintPrimaryKey,
          kMSSQLiteConstraintAutoincrement
        ]
      },
      @{testColumn2Name : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]}
    ]
  };
  id result;

  // When
  self.sut = [[MSDBStorage alloc] initWithSchema:testSchema
                                         version:0
                                        filename:kMSTestDBFileName];
  result = [self queryTable:testTableName];

  // Then
  assertThat(result, is(expectedResult));

  // If
  [self.sut deleteDatabase];
  NSString *testTableName2 = @"test2_table", *testColumnName2 = @"test2_column";
  testSchema = @{
    testTableName : @[
      @{
        testColumnName : @[
          kMSSQLiteTypeInteger, kMSSQLiteConstraintPrimaryKey,
          kMSSQLiteConstraintAutoincrement
        ]
      },
      @{testColumn2Name : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]}
    ],
    testTableName2 : @[ @{
      testColumnName2 : @[ kMSSQLiteTypeInteger, kMSSQLiteConstraintNotNull ]
    } ]
  };
  NSString *expectedResult2 = [NSString
      stringWithFormat:@"CREATE TABLE \"%@\" (\"%@\" %@ %@)", testTableName2,
                       testColumnName2, kMSSQLiteTypeInteger,
                       kMSSQLiteConstraintNotNull];
  id result2;

  // When
  self.sut = [[MSDBStorage alloc] initWithSchema:testSchema
                                         version:0
                                        filename:kMSTestDBFileName];
  result = [self queryTable:testTableName];
  result2 = [self queryTable:testTableName2];

  // Then
  assertThat(result, is(expectedResult));
  assertThat(result2, is(expectedResult2));
}

- (void)testTableExists {
  [self.sut executeQueryUsingBlock:^int(void *db) {

    // When
    BOOL tableExists =
        [MSDBStorage tableExists:kMSTestTableName inOpenedDatabase:db];

    // Then
    assertThatBool(tableExists, isTrue());

    // If
    NSString *query =
        [NSString stringWithFormat:@"DROP TABLE \"%@\"", kMSTestTableName];
    [MSDBStorage executeNonSelectionQuery:query inOpenedDatabase:db];

    // When
    tableExists =
        [MSDBStorage tableExists:kMSTestTableName inOpenedDatabase:db];

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
  (void)[dbStorage initWithSchema:self.schema
                          version:1
                         filename:kMSTestDBFileName];

  // Then
  OCMVerifyAll(dbStorage);

  // If
  // Migrate shouldn't be called in a new database.
  [dbStorage deleteDatabase];
  OCMReject([[dbStorage ignoringNonObjectArgs]
      migrateDatabase:[OCMArg anyPointer]
          fromVersion:0]);

  // When
  (void)[dbStorage initWithSchema:self.schema
                          version:2
                         filename:kMSTestDBFileName];

  // Then
  OCMVerifyAll(dbStorage);
}

- (void)testExecuteQuery {

  // If
  NSString *expectedPerson = @"Hungry Guy";
  NSNumber *expectedHungriness = @(99);
  NSString *expectedMeal = @"Big burger";
  NSString *query =
      [NSString stringWithFormat:@"INSERT INTO \"%@\" (\"%@\", \"%@\", \"%@\") "
                                 @"VALUES ('%@', %@, '%@')",
                                 kMSTestTableName, kMSTestPersonColName,
                                 kMSTestHungrinessColName, kMSTestMealColName,
                                 expectedPerson, expectedHungriness.stringValue,
                                 expectedMeal];
  BOOL result;
  NSArray *entry;

  // When
  result = [self.sut executeNonSelectionQuery:query];

  // Then
  assertThatBool(result, isTrue());

  // If
  query = [NSString stringWithFormat:@"SELECT * FROM \"%@\"", kMSTestTableName];

  // When
  entry = [self.sut executeSelectionQuery:query];

  // Then
  assertThat(
      entry,
      is(@[ @[ @(1), expectedPerson, expectedHungriness, expectedMeal ] ]));

  // If
  expectedMeal = @"Gigantic burger";
  query = [NSString
      stringWithFormat:@"UPDATE \"%@\" SET \"%@\" = '%@' WHERE \"%@\" = %d",
                       kMSTestTableName, kMSTestMealColName, expectedMeal,
                       kMSTestPositionColName, 1];

  // When
  result = [self.sut executeNonSelectionQuery:query];

  // Then
  assertThatBool(result, isTrue());

  // If
  query = [NSString stringWithFormat:@"SELECT * FROM \"%@\"", kMSTestTableName];

  // When
  entry = [self.sut executeSelectionQuery:query];

  // Then
  assertThat(
      entry,
      is(@[ @[ @(1), expectedPerson, expectedHungriness, expectedMeal ] ]));

  // If
  query =
      [NSString stringWithFormat:@"DELETE FROM \"%@\" WHERE \"%@\" = %d;",
                                 kMSTestTableName, kMSTestPositionColName, 1];

  // When
  result = [self.sut executeNonSelectionQuery:query];

  // Then
  assertThatBool(result, isTrue());

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
  id result = [self.sut
      executeSelectionQuery:[NSString stringWithFormat:@"SELECT * FROM \"%@\"",
                                                       kMSTestTableName]];

  // Then
  assertThat(expectedGuys, is(result));
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
  NSString *query =
      [NSString stringWithFormat:@"INSERT INTO \"%@\" (\"%@\", \"%@\", \"%@\") "
                                 @"VALUES ('%@', %@, '%@')",
                                 kMSTestTableName, kMSTestPersonColName,
                                 kMSTestHungrinessColName, kMSTestMealColName,
                                 expectedPerson, expectedHungriness.stringValue,
                                 expectedMeal];
  [self.sut executeNonSelectionQuery:query];

  // When
  count = [self.sut countEntriesForTable:kMSTestTableName condition:nil];

  // Then
  assertThatUnsignedInteger(count, equalToInt(1));

  // If
  expectedPerson = @"Hungry Man";
  expectedMeal = @"Huge raclette";
  query =
      [NSString stringWithFormat:@"INSERT INTO \"%@\" (\"%@\", \"%@\", \"%@\") "
                                 @"VALUES ('%@', %@, '%@')",
                                 kMSTestTableName, kMSTestPersonColName,
                                 kMSTestHungrinessColName, kMSTestMealColName,
                                 expectedPerson, expectedHungriness.stringValue,
                                 expectedMeal];
  [self.sut executeNonSelectionQuery:query];

  // When
  count = [self.sut countEntriesForTable:kMSTestTableName condition:nil];

  // Then
  assertThatUnsignedInteger(count, equalToInt(2));

  // When
  count = [self.sut
      countEntriesForTable:kMSTestTableName
                 condition:[NSString stringWithFormat:@"\"%@\" = '%@'",
                                                      kMSTestMealColName,
                                                      expectedMeal]];

  // Then
  assertThatUnsignedInteger(count, equalToInt(1));
}

#pragma mark - Private

- (NSArray *)addGuysToTheTableWithCount:(short)guysCount {
  NSString *insertQuery;
  NSMutableArray *guys = [NSMutableArray new];
  for (short i = 1; i <= guysCount; i++) {
    [guys addObject:@[
      @(i), [NSString stringWithFormat:@"%@%d", kMSTestPersonColName, i],
      @(arc4random_uniform(100)),
      [NSString stringWithFormat:@"%@%d", kMSTestMealColName, i]
    ]];
    insertQuery = [NSString
        stringWithFormat:
            @"INSERT INTO '%@' ('%@', '%@', '%@') VALUES ('%@', '%@', '%@')",
            kMSTestTableName, kMSTestPersonColName, kMSTestHungrinessColName,
            kMSTestMealColName, [guys lastObject][1],
            [[guys lastObject][2] stringValue], [guys lastObject][3]];
    [self.sut executeNonSelectionQuery:insertQuery];
  }
  return guys;
}

- (NSString *)queryTable:(NSString *)tableName {
  return [self.sut
      executeSelectionQuery:
          [NSString
              stringWithFormat:@"SELECT sql FROM sqlite_master WHERE name='%@'",
                               tableName]][0][0];
}

@end
