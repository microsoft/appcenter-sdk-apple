#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "MSDBStoragePrivate.h"
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
        kMSTestPositionColName :
            @[ kMSSQLiteTypeInteger, kMSSQLiteConstraintPrimaryKey, kMSSQLiteConstraintAutoincrement ]
      },
      @{kMSTestPersonColName : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]},
      @{kMSTestHungrinessColName : @[ kMSSQLiteTypeInteger ]},
      @{kMSTestMealColName : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]}
    ]
  };
  self.sut = [[MSDBStorage alloc] initWithSchema:self.schema filename:kMSTestDBFileName];
}

- (void)tearDown {
  [self.sut deleteDB];
  [super tearDown];
}

- (void)testInitWithSchema {

  // If
  [self.sut deleteDB];
  NSString *testTableName = @"test_table", *testColumnName = @"test_column", *testColumn2Name = @"test_column2";
  NSString *expectedResult =
      [NSString stringWithFormat:@"CREATE TABLE \"%@\" (\"%@\" %@ %@ %@, \"%@\" %@ %@)", testTableName, testColumnName,
                                 kMSSQLiteTypeInteger, kMSSQLiteConstraintPrimaryKey, kMSSQLiteConstraintAutoincrement,
                                 testColumn2Name, kMSSQLiteTypeText, kMSSQLiteConstraintNotNull];
  MSDBSchema *testSchema = @{
    testTableName : @[
      @{testColumnName : @[ kMSSQLiteTypeInteger, kMSSQLiteConstraintPrimaryKey, kMSSQLiteConstraintAutoincrement ]},
      @{testColumn2Name : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]}
    ]
  };
  id result;

  // When
  self.sut = [[MSDBStorage alloc] initWithSchema:testSchema filename:kMSTestDBFileName];
  result = [self.sut
      executeSelectionQuery:[NSString stringWithFormat:@"SELECT \"sql\" FROM \"sqlite_master\" WHERE \"name\"='%@'",
                                                       testTableName]];

  // Then
  assertThat(result[0][0], is(expectedResult));

  // If
  [self.sut deleteDB];
  NSString *testTableName2 = @"test2_table", *testColumnName2 = @"test2_column";
  testSchema = @{
    testTableName : @[
      @{testColumnName : @[ kMSSQLiteTypeInteger, kMSSQLiteConstraintPrimaryKey, kMSSQLiteConstraintAutoincrement ]},
      @{testColumn2Name : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]}
    ],
    testTableName2 : @[ @{testColumnName2 : @[ kMSSQLiteTypeInteger, kMSSQLiteConstraintNotNull ]} ]
  };
  NSString *expectedResult2 =
      [NSString stringWithFormat:@"CREATE TABLE \"%@\" (\"%@\" %@ %@)", testTableName2, testColumnName2,
                                 kMSSQLiteTypeInteger, kMSSQLiteConstraintNotNull];
  id result2;

  // When
  self.sut = [[MSDBStorage alloc] initWithSchema:testSchema filename:kMSTestDBFileName];
  result = [self.sut
      executeSelectionQuery:[NSString stringWithFormat:@"SELECT \"sql\" FROM \"sqlite_master\" WHERE \"name\"='%@'",
                                                       testTableName]];
  result2 = [self.sut
      executeSelectionQuery:[NSString stringWithFormat:@"SELECT sql FROM \"sqlite_master\" WHERE \"name\"='%@'",
                                                       testTableName2]];

  // Then
  assertThat(result[0][0], is(expectedResult));
  assertThat(result2[0][0], is(expectedResult2));
}

- (void)testTableExists {

  // If
  BOOL tableExists;

  // When
  tableExists = [self.sut tableExists:kMSTestTableName];

  // Then
  assertThatBool(tableExists, isTrue());

  // If
  NSString *query = [NSString stringWithFormat:@"DROP TABLE \"%@\"", kMSTestTableName];
  [self.sut executeNonSelectionQuery:query];

  // When
  tableExists = [self.sut tableExists:kMSTestTableName];

  // Then
  assertThatBool(tableExists, isFalse());
}

- (void)testExecuteQuery {

  // If
  NSString *expectedPerson = @"Hungry Guy";
  NSNumber *expectedHungriness = @(99);
  NSString *expectedMeal = @"Big burger";
  NSString *query =
      [NSString stringWithFormat:@"INSERT INTO \"%@\" (\"%@\", \"%@\", \"%@\") VALUES ('%@', %@, '%@')",
                                 kMSTestTableName, kMSTestPersonColName, kMSTestHungrinessColName, kMSTestMealColName,
                                 expectedPerson, expectedHungriness.stringValue, expectedMeal];
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
  assertThat(entry, is(@[ @[ @(1), expectedPerson, expectedHungriness, expectedMeal ] ]));

  // If
  expectedMeal = @"Gigantic burger";
  query = [NSString stringWithFormat:@"UPDATE \"%@\" SET \"%@\" = '%@' WHERE \"%@\" = %d", kMSTestTableName,
                                     kMSTestMealColName, expectedMeal, kMSTestPositionColName, 1];

  // When
  result = [self.sut executeNonSelectionQuery:query];

  // Then
  assertThatBool(result, isTrue());

  // If
  query = [NSString stringWithFormat:@"SELECT * FROM \"%@\"", kMSTestTableName];

  // When
  entry = [self.sut executeSelectionQuery:query];

  // Then
  assertThat(entry, is(@[ @[ @(1), expectedPerson, expectedHungriness, expectedMeal ] ]));

  // If
  query =
      [NSString stringWithFormat:@"DELETE FROM \"%@\" WHERE \"%@\" = %d;", kMSTestTableName, kMSTestPositionColName, 1];

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
  id result = [self.sut executeSelectionQuery:[NSString stringWithFormat:@"SELECT * FROM \"%@\"", kMSTestTableName]];

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
      [NSString stringWithFormat:@"INSERT INTO \"%@\" (\"%@\", \"%@\", \"%@\") VALUES ('%@', %@, '%@')",
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
  query = [NSString stringWithFormat:@"INSERT INTO \"%@\" (\"%@\", \"%@\", \"%@\") VALUES ('%@', %@, '%@')",
                                     kMSTestTableName, kMSTestPersonColName, kMSTestHungrinessColName,
                                     kMSTestMealColName, expectedPerson, expectedHungriness.stringValue, expectedMeal];
  [self.sut executeNonSelectionQuery:query];

  // When
  count = [self.sut countEntriesForTable:kMSTestTableName condition:nil];

  // Then
  assertThatUnsignedInteger(count, equalToInt(2));

  // When
  count =
      [self.sut countEntriesForTable:kMSTestTableName
                           condition:[NSString stringWithFormat:@"\"%@\" = '%@'", kMSTestMealColName, expectedMeal]];

  // Then
  assertThatUnsignedInteger(count, equalToInt(1));
}

#pragma mark - Private

- (NSArray *)addGuysToTheTableWithCount:(short)guysCount {
  NSString *insertQuery;
  NSMutableArray *guys = [NSMutableArray new];
  for (short i = 1; i <= guysCount; i++) {
    [guys addObject:@[
      @(i), [NSString stringWithFormat:@"%@%d", kMSTestPersonColName, i], @(arc4random_uniform(100)),
      [NSString stringWithFormat:@"%@%d", kMSTestMealColName, i]
    ]];
    insertQuery =
        [NSString stringWithFormat:@"INSERT INTO '%@' ('%@', '%@', '%@') VALUES ('%@', '%@', '%@')", kMSTestTableName,
                                   kMSTestPersonColName, kMSTestHungrinessColName, kMSTestMealColName,
                                   [guys lastObject][1], [[guys lastObject][2] stringValue], [guys lastObject][3]];
    [self.sut executeNonSelectionQuery:insertQuery];
  }
  return guys;
}

@end
