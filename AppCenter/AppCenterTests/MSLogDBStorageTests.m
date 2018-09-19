#import <sqlite3.h>
#import "MSAbstractLogInternal.h"
#import "MSDBStoragePrivate.h"
#import "MSLogDBStoragePrivate.h"
#import "MSStorageTestUtil.h"
#import "MSTestFrameworks.h"
#import "MSUtility.h"

static NSString *const kMSTestGroupId = @"TestGroupId";
static NSString *const kMSAnotherTestGroupId = @"AnotherGroupId";

// 40 KiB (10 pages).
static const long kMSTestStorageSizeMinimumUpperLimitInBytes = 10 * kMSDefaultPageSizeInBytes;

@interface MSLogDBStorageTests : XCTestCase

@property(nonatomic) MSLogDBStorage *sut;
@property(nonatomic) MSStorageTestUtil *storageTestUtil;

@end

@implementation MSLogDBStorageTests

#pragma mark - Setup
- (void)setUp {
  [super setUp];
  [self.sut deleteDatabase];
  self.sut = [[MSLogDBStorage alloc] initWithMinimumUpperSizeLimitInBytes:kMSTestStorageSizeMinimumUpperLimitInBytes];
  self.storageTestUtil = [[MSStorageTestUtil alloc] initWithDbFileName:kMSDBFileName];
}

- (void)tearDown {
  [self.sut deleteDatabase];
  [super tearDown];
}

- (void)testLoadTooManyLogs {

  // If
  NSUInteger expectedLogsCount = 5;
  NSMutableArray
      *expectedLogs = [[self generateAndSaveLogsWithCount:expectedLogsCount + 1 groupId:kMSTestGroupId] mutableCopy];
  [expectedLogs removeLastObject];

  // When
  BOOL moreLogsAvailable = [self.sut loadLogsWithGroupId:kMSTestGroupId
                                                   limit:expectedLogsCount
                                          withCompletion:^(NSArray<id <MSLog>> *_Nonnull logArray,
                                                           NSString *_Nonnull batchId) {

                                            // Then
                                            assertThat(batchId, notNilValue());
                                            assertThat(expectedLogs, is(logArray));
                                          }];
  XCTAssertTrue(moreLogsAvailable);
}

- (void)testLoadJustEnoughLogs {

  // If
  NSUInteger expectedLogsCount = 5;
  NSArray *expectedLogs = [self generateAndSaveLogsWithCount:expectedLogsCount groupId:kMSTestGroupId];

  // When
  BOOL moreLogsAvailable = [self.sut loadLogsWithGroupId:kMSTestGroupId
                                                   limit:expectedLogsCount
                                          withCompletion:^(NSArray<id <MSLog>> *_Nonnull logArray,
                                                           NSString *_Nonnull batchId) {

                                            // Then
                                            assertThat(batchId, notNilValue());
                                            assertThat(expectedLogs, is(logArray));
                                          }];
  XCTAssertFalse(moreLogsAvailable);
}

- (void)testLoadNotEnoughLogs {

  // If
  NSUInteger expectedLogsCount = 2;
  NSUInteger limit = 5;
  NSArray *expectedLogs = [self generateAndSaveLogsWithCount:expectedLogsCount groupId:kMSTestGroupId];

  // When
  BOOL moreLogsAvailable = [self.sut loadLogsWithGroupId:kMSTestGroupId
                                                   limit:limit
                                          withCompletion:^(NSArray<id <MSLog>> *_Nonnull logArray,
                                                           NSString *_Nonnull batchId) {

                                            // Then
                                            assertThat(batchId, notNilValue());
                                            assertThat(expectedLogs, is(logArray));
                                          }];
  XCTAssertFalse(moreLogsAvailable);
}

- (void)testLoadLogsWhilePendingBatchesFromSameGroupId {

  // If
  NSUInteger expectedLogsCount = 5;
  __block NSArray
      *expectedLogs = [[self generateAndSaveLogsWithCount:expectedLogsCount groupId:kMSTestGroupId] mutableCopy];
  __block NSArray *unexpectedLogs;
  __block NSString *unexpectedBatchId;

  // Load some logs to trigger a new batch.
  [self.sut loadLogsWithGroupId:kMSTestGroupId
                          limit:2
                 withCompletion:^(NSArray<id <MSLog>> *_Nonnull logArray, NSString *_Nonnull batchId) {

                   // Those values shouldn't be in the next batch.
                   unexpectedLogs = logArray;
                   unexpectedBatchId = batchId;
                 }];

  // When
  BOOL moreLogsAvailable = [self.sut loadLogsWithGroupId:kMSTestGroupId
                                                   limit:expectedLogsCount
                                          withCompletion:^(NSArray<id <MSLog>> *_Nonnull logArray,
                                                           NSString *_Nonnull batchId) {

                                            // Then
                                            // Logs from previous batch are not expected here.
                                            NSPredicate *predicate =
                                                [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)", unexpectedLogs];
                                            expectedLogs = [expectedLogs filteredArrayUsingPredicate:predicate];
                                            assertThat(batchId, notNilValue());
                                            assertThat(expectedLogs, is(logArray));
                                            assertThat(batchId, isNot(unexpectedBatchId));
                                          }];
  XCTAssertFalse(moreLogsAvailable);
}

- (void)testLoadLogsWhilePendingBatchesFromOtherGroupId {

  // If
  NSUInteger expectedLogsCount = 5;
  __block NSArray
      *expectedLogs = [[self generateAndSaveLogsWithCount:expectedLogsCount groupId:kMSTestGroupId] mutableCopy];
  __block NSArray *unexpectedLogs;
  __block NSString *unexpectedBatchId;

  // Load some logs to trigger a new batch from another group Id.
  [self.sut loadLogsWithGroupId:kMSAnotherTestGroupId
                          limit:2
                 withCompletion:^(NSArray<id <MSLog>> *_Nonnull logArray, NSString *_Nonnull batchId) {

                   // Those values shouldn't be in the next batch.
                   unexpectedLogs = logArray;
                   unexpectedBatchId = batchId;
                 }];

  // When
  BOOL moreLogsAvailable = [self.sut loadLogsWithGroupId:kMSTestGroupId
                                                   limit:expectedLogsCount
                                          withCompletion:^(NSArray<id <MSLog>> *_Nonnull logArray,
                                                           NSString *_Nonnull batchId) {

                                            // Then
                                            // Logs from previous batch are not expected here.
                                            NSPredicate *predicate =
                                                [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)", unexpectedLogs];
                                            expectedLogs = [expectedLogs filteredArrayUsingPredicate:predicate];
                                            assertThat(batchId, notNilValue());
                                            assertThat(expectedLogs, is(logArray));
                                            assertThat(batchId, isNot(unexpectedBatchId));
                                          }];
  XCTAssertFalse(moreLogsAvailable);
}

- (void)testLoadUnlimitedLogs {

  // If
  NSUInteger expectedLogsCount = 42;
  NSArray *expectedLogs = [self generateAndSaveLogsWithCount:expectedLogsCount groupId:kMSTestGroupId];

  // When
  NSArray *logs = [self.sut logsFromDBWithGroupId:kMSTestGroupId];

  // Then
  assertThat(expectedLogs, is(logs));
}

- (void)testDeleteLogsWithGroupId {

  // Test deletion with no batch.

  // If
  self.sut = [MSLogDBStorage new];
//  [self.sut.batches removeAllObjects];
  [self generateAndSaveLogsWithCount:5 groupId:kMSTestGroupId];

  // When
  [self.sut deleteLogsWithGroupId:kMSTestGroupId];

  // Then
  assertThatInteger([self.sut countEntriesForTable:kMSLogTableName condition:nil], equalToInteger(0));
  assertThatInteger(self.sut.batches.count, equalToInteger(0));

  // Test deletion with only the batch to delete.

  // If
  // Generate logs and create one batch by loading logs.
  [self generateAndSaveLogsWithCount:5 groupId:kMSTestGroupId];
  [self.sut loadLogsWithGroupId:kMSTestGroupId limit:2 withCompletion:nil];

  // When
  [self.sut deleteLogsWithGroupId:kMSTestGroupId];

  // Then
  assertThatInteger([self.sut countEntriesForTable:kMSLogTableName condition:nil], equalToInteger(0));
  assertThatInteger(self.sut.batches.count, equalToInteger(0));

  // Test deletion with more than one batch to delete.

  // If
  // Generate logs and create two batches by loading logs twice.
  [self generateAndSaveLogsWithCount:5 groupId:kMSTestGroupId];
  [self.sut loadLogsWithGroupId:kMSTestGroupId limit:2 withCompletion:nil];
  [self.sut loadLogsWithGroupId:kMSTestGroupId limit:2 withCompletion:nil];

  // When
  [self.sut deleteLogsWithGroupId:kMSTestGroupId];

  // Then
  assertThatInteger([self.sut countEntriesForTable:kMSLogTableName condition:nil], equalToInteger(0));
  assertThatInteger(self.sut.batches.count, equalToInteger(0));

  // Test deletion with the batch to delete and batches from other groups.

  // If
  // Generate logs and create two batches of different group Ids.
  __block NSString *batchIdToDelete;
  [self generateAndSaveLogsWithCount:2 groupId:kMSTestGroupId];
  NSArray *expectedLogs = [self generateAndSaveLogsWithCount:3 groupId:kMSAnotherTestGroupId];
  [self.sut loadLogsWithGroupId:kMSTestGroupId limit:2 withCompletion:^(__attribute__((unused))
                                                                        NSArray <MSLog> *_Nonnull logArray,
                                                                        NSString *batchId) {
    batchIdToDelete = batchId;
  }];
  [self.sut loadLogsWithGroupId:kMSAnotherTestGroupId limit:2 withCompletion:nil];

  // When
  [self.sut deleteLogsWithGroupId:kMSTestGroupId];

  // Then
  NSArray *remainingLogs = [self loadLogsWhere:nil];
  assertThat(remainingLogs, is(expectedLogs));
  assertThatInteger(self.sut.batches.count, equalToInteger(1));
  assertThatBool([self.sut.batches.allKeys containsObject:batchIdToDelete], isFalse());
}

- (void)testDeleteLogsByBatchIdWithOnlyOnePendingBatch {

  // If
  __block NSString *batchIdToDelete;
  __block NSArray *expectedLogs;
  NSString *condition;
  NSArray *remainingLogs;
  [self.sut.batches removeAllObjects];
  NSArray *savedLogs = [self generateAndSaveLogsWithCount:5 groupId:kMSTestGroupId];
  [self.sut loadLogsWithGroupId:kMSTestGroupId
                          limit:2
                 withCompletion:^(NSArray <MSLog> *_Nonnull logArray, NSString *batchId) {
                   batchIdToDelete = batchId;
                   NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT (self IN %@)", logArray];
                   expectedLogs = [savedLogs filteredArrayUsingPredicate:predicate];
                 }];
  NSArray *logIdsToDelete = self.sut.batches[batchIdToDelete];

  // When
  [self.sut deleteLogsWithBatchId:batchIdToDelete groupId:kMSTestGroupId];

  // Then
  remainingLogs = [self loadLogsWhere:nil];
  condition =
      [NSString stringWithFormat:@"%@ IN (%@)", kMSIdColumnName, [logIdsToDelete componentsJoinedByString:@", "]];
  assertThatInteger([self.sut countEntriesForTable:kMSLogTableName condition:condition], equalToInteger(0));
  assertThat(expectedLogs, is(remainingLogs));
  assertThatInteger(self.sut.batches.count, equalToInteger(0));
}

- (void)testDeleteLogsByBatchIdWithMultiplePendingBatches {

  // If
  __block NSString *batchIdToDelete;
  __block NSArray *expectedLogs;
  NSString *condition;
  NSArray *remainingLogs;
  [self.sut.batches removeAllObjects];
  NSArray *savedLogs = [self generateAndSaveLogsWithCount:5 groupId:kMSTestGroupId];
  [self.sut loadLogsWithGroupId:kMSTestGroupId
                          limit:2
                 withCompletion:^(NSArray <MSLog> *_Nonnull logArray, NSString *batchId) {
                   batchIdToDelete = batchId;

                   // Intersect arrays to build expected remaining logs.
                   NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT (self IN %@)", logArray];
                   expectedLogs = [savedLogs filteredArrayUsingPredicate:predicate];
                 }];
  NSArray *logIdsToDelete = self.sut.batches[batchIdToDelete];

  // Trigger another batch.
  [self.sut loadLogsWithGroupId:kMSTestGroupId limit:2 withCompletion:nil];

  // When
  [self.sut deleteLogsWithBatchId:batchIdToDelete groupId:kMSTestGroupId];

  // Then
  remainingLogs = [self loadLogsWhere:nil];
  condition =
      [NSString stringWithFormat:@"%@ IN (%@)", kMSIdColumnName, [logIdsToDelete componentsJoinedByString:@", "]];
  assertThatInteger([self.sut countEntriesForTable:kMSLogTableName condition:condition], equalToInteger(0));
  assertThat(expectedLogs, is(remainingLogs));
  assertThatInteger(self.sut.batches.count, equalToInteger(1));
}

- (void)testDeleteLogsByBatchIdWithPendingBatchesFromOtherGroups {

  // If
  __block NSString *batchIdToDelete;
  __block NSMutableArray *expectedLogs;
  NSString *condition;
  NSArray *remainingLogs;
  [self.sut.batches removeAllObjects];
  NSArray *savedLogs = [self generateAndSaveLogsWithCount:5 groupId:kMSTestGroupId];
  NSArray *savedLogsFromOtherGroup = [self generateAndSaveLogsWithCount:3 groupId:kMSAnotherTestGroupId];
  [self.sut loadLogsWithGroupId:kMSTestGroupId
                          limit:2
                 withCompletion:^(NSArray <MSLog> *_Nonnull logArray, NSString *batchId) {
                   batchIdToDelete = batchId;

                   // Intersect arrays to build expected remaining logs.
                   NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT (self IN %@)", logArray];
                   expectedLogs = [[savedLogs filteredArrayUsingPredicate:predicate] mutableCopy];

                   // Remaining logs should contains logs for other groups.
                   [expectedLogs addObjectsFromArray:savedLogsFromOtherGroup];
                 }];
  NSArray *logIdsToDelete = self.sut.batches[batchIdToDelete];

  // Trigger another batch.
  [self.sut loadLogsWithGroupId:kMSAnotherTestGroupId limit:2 withCompletion:nil];

  // When
  [self.sut deleteLogsWithBatchId:batchIdToDelete groupId:kMSTestGroupId];

  // Then
  remainingLogs = [self loadLogsWhere:nil];
  condition =
      [NSString stringWithFormat:@"%@ IN (%@)", kMSIdColumnName, [logIdsToDelete componentsJoinedByString:@", "]];
  assertThatInteger([self.sut countEntriesForTable:kMSLogTableName condition:condition], equalToInteger(0));
  assertThat(expectedLogs, is(remainingLogs));
  assertThatInteger(self.sut.batches.count, equalToInteger(1));
}

- (void)testCommonSchemaLogTargetTokenIsSavedAndRestored {

  // If
  NSString *testTargetToken = @"testTargetToken";
  MSCommonSchemaLog *log = [MSCommonSchemaLog new];
  [log addTransmissionTargetToken:testTargetToken];

  // When
  [self.sut saveLog:log withGroupId:kMSTestGroupId];

  // Then
  [self.sut loadLogsWithGroupId:kMSTestGroupId
                          limit:1
                 withCompletion:^(NSArray <MSLog> *_Nonnull logArray, __unused NSString *batchId) {
                   id <MSLog> restoredLog = logArray[0];
                   NSString *restoredTargetToken = [[restoredLog transmissionTargetTokens] anyObject];
                   assertThatInt([[restoredLog transmissionTargetTokens] count], equalToInt(1));
                   XCTAssertEqualObjects(testTargetToken, restoredTargetToken);
                 }];
}

- (void)testOnlyCommonSchemaLogTargetTokenIsSavedAndRestored {

  // If
  NSString *testTargetToken = @"testTargetToken";
  MSAbstractLog *log = [MSAbstractLog new];
  [log addTransmissionTargetToken:testTargetToken];

  // When
  [self.sut saveLog:log withGroupId:kMSTestGroupId];

  // Then
  [self.sut loadLogsWithGroupId:kMSTestGroupId
                          limit:1
                 withCompletion:^(NSArray <MSLog> *_Nonnull logArray, __unused NSString *batchId) {
                   assertThatInt([[logArray[0] transmissionTargetTokens] count], equalToInt(0));
                 }];
}

- (void)testDeleteLogsByBatchIdWithNoPendingBatches {

  // If
  [self.sut.batches removeAllObjects];
  [self generateAndSaveLogsWithCount:5 groupId:kMSTestGroupId];

  // When
  [self.sut deleteLogsWithBatchId:MS_UUID_STRING groupId:kMSTestGroupId];

  // Then
  assertThatInteger(self.sut.batches.count, equalToInteger(0));
  assertThatInteger([self.sut countEntriesForTable:kMSLogTableName condition:nil], equalToInteger(5));
}

- (void)testAddLogsWhenBelowStorageCapacity {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler invoked."];
  long maxCapacityInBytes = kMSTestStorageSizeMinimumUpperLimitInBytes + kMSDefaultPageSizeInBytes;
  long initialDataLengthInBytes = maxCapacityInBytes - 3 * kMSDefaultPageSizeInBytes;
  MSAbstractLog *additionalLog = [MSAbstractLog new];
  additionalLog.sid = MS_UUID_STRING;
  NSArray *addedLogs = [self fillDatabaseWithLogsOfSizeInBytes:initialDataLengthInBytes];
  __weak typeof(self) weakSelf = self;

  // When
  [weakSelf.sut setStorageSize:maxCapacityInBytes completionHandler:^(BOOL success) {
    typeof(self) strongSelf = weakSelf;
    BOOL logSavedSuccessfully = [strongSelf.sut saveLog:additionalLog withGroupId:kMSAnotherTestGroupId];

    // Then
    XCTAssertTrue(success);
    XCTAssertTrue(logSavedSuccessfully);
    NSString
        *whereCondition = [NSString stringWithFormat:@"\"%@\" = '%@'", kMSGroupIdColumnName, kMSAnotherTestGroupId];
    NSArray<id <MSLog>> *loadedLogs = [strongSelf loadLogsWhere:whereCondition];
    NSArray<id <MSLog>> *allLogs = [strongSelf loadLogsWhere:nil];
    XCTAssertEqual(loadedLogs.count, 1);
    XCTAssertEqualObjects(loadedLogs[0].sid, additionalLog.sid);
    XCTAssertEqual(addedLogs.count + 1, allLogs.count);
    [expectation fulfill];
  }];

  // Then
  [self waitForExpectationsWithTimeout:1 handler:^(NSError *_Nullable error) {
    if (error) {
      XCTFail(@"Expectation Failed with error: %@", error);
    }
  }];
}

- (void)testAddLogsDoesNotExceedCapacity {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler invoked."];
  __block long maxCapacityInBytes = kMSTestStorageSizeMinimumUpperLimitInBytes;
  NSArray *addedLogs = [self fillDatabaseWithLogsOfSizeInBytes:maxCapacityInBytes];

  // When
  __weak typeof(self) weakSelf = self;
  [self.sut setStorageSize:maxCapacityInBytes completionHandler:^(__unused BOOL success) {

    int additionalLogs = 0;
    while (additionalLogs <= [addedLogs count] * 2) {
      MSAbstractLog *additionalLog = [MSAbstractLog new];
      additionalLog.sid = MS_UUID_STRING;
      typeof(self) strongSelf = weakSelf;
      BOOL logSavedSuccessfully = [strongSelf.sut saveLog:additionalLog withGroupId:kMSTestGroupId];
      ++additionalLogs;

      // Then
      XCTAssertTrue([strongSelf.storageTestUtil getDataLengthInBytes] <= maxCapacityInBytes);
      XCTAssertTrue(logSavedSuccessfully);
    }
    [expectation fulfill];
  }];

  // Then
  [self waitForExpectationsWithTimeout:1 handler:^(NSError *_Nullable error) {
    if (error) {
      XCTFail(@"Expectation Failed with error: %@", error);
    }
  }];
}

- (void)testOldestLogsAreDeletedFirstWhenCapacityIsReached {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler invoked."];
  long maxCapacityInBytes = kMSTestStorageSizeMinimumUpperLimitInBytes + kMSDefaultPageSizeInBytes;
  NSArray *addedLogs = [self fillDatabaseWithLogsOfSizeInBytes:maxCapacityInBytes];
  MSAbstractLog *firstLog = addedLogs[0];
  int initialLogCount = (int)[addedLogs count];
  __block int originalLogsCount = initialLogCount;

  // When
  [self.sut setStorageSize:maxCapacityInBytes completionHandler:^(__unused BOOL success) {
    while (originalLogsCount < initialLogCount) {
      MSAbstractLog *additionalLog = [MSAbstractLog new];
      additionalLog.sid = MS_UUID_STRING;
      BOOL logSavedSuccessfully = [self.sut saveLog:additionalLog withGroupId:kMSAnotherTestGroupId];
      NSString *originalLogsFilter = [NSString stringWithFormat:@"\"%@\" = '%@'", kMSGroupIdColumnName, kMSTestGroupId];
      NSArray<id <MSLog>> *originalLogs = [self loadLogsWhere:originalLogsFilter];
      originalLogsCount = (int)[originalLogs count];
      if (originalLogsCount < initialLogCount) {
        XCTAssertEqual(originalLogsCount, initialLogCount - 1);
        BOOL containsFirstLog = [self logs:originalLogs containLogWithSessionId:firstLog.sid];
        XCTAssertFalse(containsFirstLog);
      }

      // Then
      XCTAssertTrue([self.storageTestUtil getDataLengthInBytes] <= maxCapacityInBytes);
      XCTAssertTrue(logSavedSuccessfully);
    }
    [expectation fulfill];
  }];

  // Then
  [self waitForExpectationsWithTimeout:1 handler:^(NSError *_Nullable error) {
    if (error) {
      XCTFail(@"Expectation Failed with error: %@", error);
    }
  }];
}

- (void)testMigration {

  // If
  [self.sut deleteDatabase];

  // Create old version db.
  // DO NOT CHANGE. THIS IS ALREADY PUBLISHED SCHEMA.
  MSDBSchema *schema0 = @{kMSLogTableName: @[
      @{kMSIdColumnName: @[kMSSQLiteTypeInteger, kMSSQLiteConstraintPrimaryKey, kMSSQLiteConstraintAutoincrement]},
      @{kMSGroupIdColumnName: @[kMSSQLiteTypeText, kMSSQLiteConstraintNotNull]},
      @{kMSLogColumnName: @[kMSSQLiteTypeText, kMSSQLiteConstraintNotNull]}]};
  MSDBStorage *storage0 = [[MSDBStorage alloc] initWithSchema:schema0 version:0 filename:kMSDBFileName];
  [self generateAndSaveLogsWithCount:10 groupId:kMSTestGroupId storage:storage0];

  // When
  self.sut = [MSLogDBStorage new];

  // Then
  assertThatInt([self loadLogsWhere:nil].count, equalToUnsignedInt(10));
  NSString *currentTable =
      [self.sut executeSelectionQuery:[NSString stringWithFormat:@"SELECT sql FROM sqlite_master WHERE name='%@'",
                                                                 kMSLogTableName]][0][0];
  assertThat(currentTable, is(@"CREATE TABLE \"logs\" ("
                              @"\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, "
                              @"\"groupId\" TEXT NOT NULL, "
                              @"\"log\" TEXT NOT NULL, "
                              @"\"targetToken\" TEXT)"));
}

- (void)testSetStorageSizeBelowMaximumLogSizeFails {

  // If
  long storageSize = 19 * 1024;
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler invoked."];
  self.sut = [MSLogDBStorage new];

  // When
  [self.sut setStorageSize:storageSize completionHandler:^(BOOL success) {

    // Then
    XCTAssertFalse(success);
    [expectation fulfill];
  }];

  // Then
  [self waitForExpectationsWithTimeout:1 handler:^(NSError *_Nullable error) {
    if (error) {
      XCTFail(@"Expectation Failed with error: %@", error);
    }
  }];
}

#pragma mark - Helper methods

- (NSArray<id <MSLog>> *)generateAndSaveLogsWithCount:(NSUInteger)count groupId:(NSString *)groupId {
  return [self generateAndSaveLogsWithCount:count groupId:groupId storage:self.sut];
}

- (NSArray<id <MSLog>> *)generateAndSaveLogsWithCount:(NSUInteger)count
                                              groupId:(NSString *)groupId
                                              storage:(MSDBStorage *)storage {
  NSMutableArray<id <MSLog>> *logs = [NSMutableArray arrayWithCapacity:count];
  NSUInteger truelogCount;
  for (NSUInteger i = 0; i < count; ++i) {
    id <MSLog> log = [MSAbstractLog new];
    log.sid = MS_UUID_STRING;
    NSData *logData = [NSKeyedArchiver archivedDataWithRootObject:log];
    NSString *base64Data = [logData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    NSString *addLogQuery = [NSString stringWithFormat:@"INSERT INTO \"%@\" (\"%@\", \"%@\") VALUES ('%@', '%@')",
                                                       kMSLogTableName,
                                                       kMSGroupIdColumnName,
                                                       kMSLogColumnName,
                                                       groupId,
                                                       base64Data];
    [storage executeNonSelectionQuery:addLogQuery];
    [logs addObject:log];
  }

  // Check the insertion worked.
  truelogCount = [storage countEntriesForTable:kMSLogTableName
                                     condition:[NSString stringWithFormat:@"\"%@\" = '%@'",
                                                                          kMSGroupIdColumnName,
                                                                          groupId]];
  assertThatUnsignedInteger(truelogCount, equalToUnsignedInteger(count));
  return logs;
}

- (NSArray<id <MSLog>> *)loadLogsWhere:(nullable NSString *)whereCondition {
  NSMutableArray<id <MSLog>> *logs = [NSMutableArray<id <MSLog>> new];
  NSMutableArray *rows = [NSMutableArray new];
  NSMutableString *selectLogQuery = [NSMutableString stringWithFormat:@"SELECT * FROM \"%@\"", kMSLogTableName];
  if (whereCondition.length > 0) {
    [selectLogQuery appendFormat:@" WHERE %@", whereCondition];
  }
  sqlite3 *db = [self.storageTestUtil openDatabase];
  sqlite3_stmt *statement = NULL;
  sqlite3_prepare_v2(db, [selectLogQuery UTF8String], -1, &statement, NULL);

  // Loop on rows.
  while (sqlite3_step(statement) == SQLITE_ROW) {
    NSMutableArray *entry = [NSMutableArray new];
    for (int i = 0; i < sqlite3_column_count(statement); i++) {
      id value = nil;
      switch (sqlite3_column_type(statement, i)) {
      case SQLITE_INTEGER:
        value = @(sqlite3_column_int(statement, i));
        break;
      case SQLITE_TEXT:
        value = [NSString stringWithUTF8String:(const char *) sqlite3_column_text(statement, i)];
        break;
      default:
        value = [NSNull null];
        break;
      }
      [entry addObject:value];
    }
    if (entry.count > 0) {
      [rows addObject:entry];
    }
  }
  sqlite3_finalize(statement);
  for (NSArray *row in rows) {
    NSString *base64Data = row[2];
    NSData *logData =
        [[NSData alloc] initWithBase64EncodedString:base64Data options:NSDataBase64DecodingIgnoreUnknownCharacters];
    id <MSLog> log = [NSKeyedUnarchiver unarchiveObjectWithData:logData];
    [logs addObject:log];
  }
  sqlite3_close(db);
  return logs;
}

- (NSArray<id <MSLog>> *)fillDatabaseWithLogsOfSizeInBytes:(long)sizeInBytes {
  NSMutableArray *logsAdded = [NSMutableArray new];
  int result = 0;
  int maxPageCount = (int)(sizeInBytes / kMSDefaultPageSizeInBytes);
  do {
    sqlite3 *db = [self.storageTestUtil openDatabase];
    NSString *statement = [NSString stringWithFormat:@"PRAGMA max_page_count = %i;", maxPageCount];
    sqlite3_exec(db, [statement UTF8String], NULL, NULL, NULL);
    MSAbstractLog *log = [MSAbstractLog new];
    log.sid = MS_UUID_STRING;
    NSData *logData = [NSKeyedArchiver archivedDataWithRootObject:log];
    NSString *base64Data = [logData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    NSString *addLogQuery = [NSString stringWithFormat:@"INSERT INTO \"%@\" (\"%@\", \"%@\") VALUES ('%@', '%@')",
                                                       kMSLogTableName,
                                                       kMSGroupIdColumnName,
                                                       kMSLogColumnName,
                                                       kMSTestGroupId,
                                                       base64Data];
    result = sqlite3_exec(db, [addLogQuery UTF8String], NULL, NULL, NULL);
    sqlite3_close(db);
    if (result == SQLITE_OK) {
      [logsAdded addObject:log];
    }
  } while (result == SQLITE_OK);
  return logsAdded;
}

- (BOOL)logs:(NSArray<id <MSLog>> *)logs containLogWithSessionId:(NSString *)sessionId {
  for (MSAbstractLog *log in logs) {
    if ([log.sid isEqualToString:sessionId]) {
      return YES;
      break;
    }
  }
  return NO;
}

@end
