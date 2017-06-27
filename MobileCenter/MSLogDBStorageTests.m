#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSAbstractLogInternal.h"
#import "MSDBStoragePrivate.h"
#import "MSLogDBStoragePrivate.h"
#import "MSUtility.h"
#import "MSUtility+Date.h"

static NSString *const kMSTestGroupId = @"TestGroupId";
static short const kMSTestMaxCapacity = 50;
static NSString *const kMSAnotherTestGroupId = @"AnotherGroupId";

@interface MSLogDBStorageTests : XCTestCase

@property(nonatomic) MSLogDBStorage *sut;

@end

@implementation MSLogDBStorageTests

#pragma mark - Setup
- (void)setUp {
  [super setUp];
  self.sut = [[MSLogDBStorage alloc] initWithCapacity:kMSTestMaxCapacity];
}

- (void)tearDown {
  [self.sut deleteDB];
  [super tearDown];
}

- (void)testLoadTooManyLogs {

  // If
  NSUInteger expectedLogsCount = 5;
  NSMutableArray *expectedLogs =
      [[self generateAndSaveLogsWithCount:expectedLogsCount + 1 groupId:kMSTestGroupId] mutableCopy];
  [expectedLogs removeLastObject];

  // When
  BOOL moreLogsAvailable =
      [self.sut loadLogsWithGroupId:kMSTestGroupId
                              limit:expectedLogsCount
                     withCompletion:^(NSArray<id<MSLog>> *_Nonnull logArray, NSString *_Nonnull batchId) {

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
  BOOL moreLogsAvailable =
      [self.sut loadLogsWithGroupId:kMSTestGroupId
                              limit:expectedLogsCount
                     withCompletion:^(NSArray<id<MSLog>> *_Nonnull logArray, NSString *_Nonnull batchId) {

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
  BOOL moreLogsAvailable =
      [self.sut loadLogsWithGroupId:kMSTestGroupId
                              limit:limit
                     withCompletion:^(NSArray<id<MSLog>> *_Nonnull logArray, NSString *_Nonnull batchId) {

                       // Then
                       assertThat(batchId, notNilValue());
                       assertThat(expectedLogs, is(logArray));
                     }];
  XCTAssertFalse(moreLogsAvailable);
}

- (void)testLoadLogsWhilePendingBatchesFromSameGroupId {

  /*
   * If
   */
  NSUInteger expectedLogsCount = 5;
  __block NSArray *expectedLogs =
      [[self generateAndSaveLogsWithCount:expectedLogsCount groupId:kMSTestGroupId] mutableCopy];
  __block NSArray *unexpectedLogs;
  __block NSString *unexpectedBatchId;

  // Load some logs to trigger a new batch.
  [self.sut loadLogsWithGroupId:kMSTestGroupId
                          limit:2
                 withCompletion:^(NSArray<id<MSLog>> *_Nonnull logArray, NSString *_Nonnull batchId) {

                   // Those values shouldn't be in the next batch.
                   unexpectedLogs = logArray;
                   unexpectedBatchId = batchId;
                 }];

  /*
   * When
   */
  BOOL moreLogsAvailable =
      [self.sut loadLogsWithGroupId:kMSTestGroupId
                              limit:expectedLogsCount
                     withCompletion:^(NSArray<id<MSLog>> *_Nonnull logArray, NSString *_Nonnull batchId) {

                       /*
                        * Then
                        */

                       // Logs from previous batch are not expected here.
                       NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)", unexpectedLogs];
                       expectedLogs = [expectedLogs filteredArrayUsingPredicate:predicate];
                       assertThat(batchId, notNilValue());
                       assertThat(expectedLogs, is(logArray));
                       assertThat(batchId, isNot(unexpectedBatchId));
                     }];
  XCTAssertFalse(moreLogsAvailable);
}

- (void)testLoadLogsWhilePendingBatchesFromOtherGroupId {

  /*
   * If
   */
  NSUInteger expectedLogsCount = 5;
  __block NSArray *expectedLogs =
      [[self generateAndSaveLogsWithCount:expectedLogsCount groupId:kMSTestGroupId] mutableCopy];
  __block NSArray *unexpectedLogs;
  __block NSString *unexpectedBatchId;

  // Load some logs to trigger a new batch from another group Id.
  [self.sut loadLogsWithGroupId:kMSAnotherTestGroupId
                          limit:2
                 withCompletion:^(NSArray<id<MSLog>> *_Nonnull logArray, NSString *_Nonnull batchId) {

                   // Those values shouldn't be in the next batch.
                   unexpectedLogs = logArray;
                   unexpectedBatchId = batchId;
                 }];

  /*
   * When
   */
  BOOL moreLogsAvailable =
      [self.sut loadLogsWithGroupId:kMSTestGroupId
                              limit:expectedLogsCount
                     withCompletion:^(NSArray<id<MSLog>> *_Nonnull logArray, NSString *_Nonnull batchId) {

                       /*
                        * Then
                        */

                       // Logs from previous batch are not expected here.
                       NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)", unexpectedLogs];
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

  /*
   * If
   */
  [self.sut.batches removeAllObjects];
  [self generateAndSaveLogsWithCount:5 groupId:kMSTestGroupId];

  /*
   * When
   */
  [self.sut deleteLogsWithGroupId:kMSTestGroupId];

  /*
   * Then
   */
  assertThatInteger([self.sut countEntriesForTable:kMSLogTableName condition:nil], equalToInteger(0));
  assertThatInteger(self.sut.batches.count, equalToInteger(0));

  // Test deletion with only the batch to delete.

  /*
   * If
   */

  // Generate logs and create one batch by loading logs.
  [self generateAndSaveLogsWithCount:5 groupId:kMSTestGroupId];
  [self.sut loadLogsWithGroupId:kMSTestGroupId limit:2 withCompletion:nil];

  /*
   * When
   */
  [self.sut deleteLogsWithGroupId:kMSTestGroupId];

  /*
   * Then
   */
  assertThatInteger([self.sut countEntriesForTable:kMSLogTableName condition:nil], equalToInteger(0));
  assertThatInteger(self.sut.batches.count, equalToInteger(0));

  // Test deletion with more than one batch to delete.

  /*
   * If
   */

  // Generate logs and create two batches by loading logs twice.
  [self generateAndSaveLogsWithCount:5 groupId:kMSTestGroupId];
  [self.sut loadLogsWithGroupId:kMSTestGroupId limit:2 withCompletion:nil];
  [self.sut loadLogsWithGroupId:kMSTestGroupId limit:2 withCompletion:nil];

  /*
   * When
   */
  [self.sut deleteLogsWithGroupId:kMSTestGroupId];

  /*
   * Then
   */
  assertThatInteger([self.sut countEntriesForTable:kMSLogTableName condition:nil], equalToInteger(0));
  assertThatInteger(self.sut.batches.count, equalToInteger(0));

  // Test deletion with the batch to delete and batches from other groups.

  /*
   * If
   */

  // Generate logs and create two batches of different group Ids.
  __block NSString *batchIdToDelete;
  [self generateAndSaveLogsWithCount:2 groupId:kMSTestGroupId];
  NSArray *expectedLogs = [self generateAndSaveLogsWithCount:3 groupId:kMSAnotherTestGroupId];
  [self.sut loadLogsWithGroupId:kMSTestGroupId
                          limit:2
                 withCompletion:^(__attribute__((unused)) NSArray<MSLog> *_Nonnull logArray, NSString *batchId) {
                   batchIdToDelete = batchId;
                 }];
  [self.sut loadLogsWithGroupId:kMSAnotherTestGroupId limit:2 withCompletion:nil];

  /*
   * When
   */
  [self.sut deleteLogsWithGroupId:kMSTestGroupId];

  /*
   * Then
   */
  NSArray *remainingLogs = [self loadLogsWhere:nil];
  assertThat(expectedLogs, is(remainingLogs));
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
                 withCompletion:^(NSArray<MSLog> *_Nonnull logArray, NSString *batchId) {
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

  /*
   * If
   */
  __block NSString *batchIdToDelete;
  __block NSArray *expectedLogs;
  NSString *condition;
  NSArray *remainingLogs;
  [self.sut.batches removeAllObjects];
  NSArray *savedLogs = [self generateAndSaveLogsWithCount:5 groupId:kMSTestGroupId];
  [self.sut loadLogsWithGroupId:kMSTestGroupId
                          limit:2
                 withCompletion:^(NSArray<MSLog> *_Nonnull logArray, NSString *batchId) {
                   batchIdToDelete = batchId;

                   // Intersect arrays to build expected remaining logs.
                   NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT (self IN %@)", logArray];
                   expectedLogs = [savedLogs filteredArrayUsingPredicate:predicate];
                 }];
  NSArray *logIdsToDelete = self.sut.batches[batchIdToDelete];

  // Trigger another batch.
  [self.sut loadLogsWithGroupId:kMSTestGroupId limit:2 withCompletion:nil];

  /*
   * When
   */
  [self.sut deleteLogsWithBatchId:batchIdToDelete groupId:kMSTestGroupId];

  /*
   * Then
   */
  remainingLogs = [self loadLogsWhere:nil];
  condition =
      [NSString stringWithFormat:@"%@ IN (%@)", kMSIdColumnName, [logIdsToDelete componentsJoinedByString:@", "]];
  assertThatInteger([self.sut countEntriesForTable:kMSLogTableName condition:condition], equalToInteger(0));
  assertThat(expectedLogs, is(remainingLogs));
  assertThatInteger(self.sut.batches.count, equalToInteger(1));
}

- (void)testDeleteLogsByBatchIdWithPendingBatchesFromOtherGroups {

  /*
   * If
   */
  __block NSString *batchIdToDelete;
  __block NSMutableArray *expectedLogs;
  NSString *condition;
  NSArray *remainingLogs;
  [self.sut.batches removeAllObjects];
  NSArray *savedLogs = [self generateAndSaveLogsWithCount:5 groupId:kMSTestGroupId];
  NSArray *savedLogsFromOtherGroup = [self generateAndSaveLogsWithCount:3 groupId:kMSAnotherTestGroupId];
  [self.sut loadLogsWithGroupId:kMSTestGroupId
                          limit:2
                 withCompletion:^(NSArray<MSLog> *_Nonnull logArray, NSString *batchId) {
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

  /*
   * When
   */
  [self.sut deleteLogsWithBatchId:batchIdToDelete groupId:kMSTestGroupId];

  /*
   * Then
   */
  remainingLogs = [self loadLogsWhere:nil];
  condition =
      [NSString stringWithFormat:@"%@ IN (%@)", kMSIdColumnName, [logIdsToDelete componentsJoinedByString:@", "]];
  assertThatInteger([self.sut countEntriesForTable:kMSLogTableName condition:condition], equalToInteger(0));
  assertThat(expectedLogs, is(remainingLogs));
  assertThatInteger(self.sut.batches.count, equalToInteger(1));
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

- (void)testStorageCapacity {

  /*
   * If
   */

  // Test just below the limit.
  short expectedCapacity = 3;
  __block int logCount = 2;
  self.sut = [[MSLogDBStorage alloc] initWithCapacity:expectedCapacity];
  NSMutableArray<id<MSLog>> *expectedLogs = [NSMutableArray<id<MSLog>> new];
  NSArray<id<MSLog>> *loadedLogs;

  /*
   * When
   */
  for (int i = 0; i < logCount; i++) {
    id<MSLog> log = [MSAbstractLog new];
    log.sid = MS_UUID_STRING;
    [self.sut saveLog:log withGroupId:kMSTestGroupId];
    [expectedLogs addObject:log];
  }

  /*
   * Then
   */

  // Get logs from DB.
  loadedLogs = [self loadLogsWhere:nil];
  assertThat(expectedLogs, is(loadedLogs));

  // Test at the limit.

  /*
   * If
   */
  [self.sut deleteDB];
  [expectedLogs removeAllObjects];
  expectedCapacity = 2;
  self.sut = [[MSLogDBStorage alloc] initWithCapacity:expectedCapacity];

  /*
   * When
   */
  for (int i = 0; i < logCount; i++) {
    id<MSLog> log = [MSAbstractLog new];
    log.sid = MS_UUID_STRING;

    // Save this log.
    [self.sut saveLog:log withGroupId:kMSTestGroupId];
    [expectedLogs addObject:log];
  }

  /*
   * Then
   */

  // Get logs from DB.
  loadedLogs = [self loadLogsWhere:nil];
  assertThat(expectedLogs, is(loadedLogs));

  // Test just over the limit.

  /*
   * If
   */
  [self.sut deleteDB];
  [expectedLogs removeAllObjects];
  expectedCapacity = 1;
  self.sut = [[MSLogDBStorage alloc] initWithCapacity:expectedCapacity];

  /*
   * When
   */
  for (int i = 0; i < logCount; i++) {
    id<MSLog> log = [MSAbstractLog new];
    log.sid = MS_UUID_STRING;

    // Save this log.
    [self.sut saveLog:log withGroupId:kMSTestGroupId];
    [expectedLogs addObject:log];
  }

  /*
   * Then
   */

  // The first is expected to be removed.
  [expectedLogs removeObjectAtIndex:0];

  // Get logs from DB.
  loadedLogs = [self loadLogsWhere:nil];
  assertThat(expectedLogs, is(loadedLogs));

  // Test way over the limit.

  /*
   * If
   */
  [self.sut deleteDB];
  logCount = 10;
  [expectedLogs removeAllObjects];
  expectedCapacity = 1;
  self.sut = [[MSLogDBStorage alloc] initWithCapacity:expectedCapacity];

  /*
   * When
   */
  for (int i = 0; i < logCount; i++) {
    id<MSLog> log = [MSAbstractLog new];
    log.sid = MS_UUID_STRING;

    // Save this log.
    [self.sut saveLog:log withGroupId:kMSTestGroupId];
    [expectedLogs addObject:log];
  }

  /*
   * Then
   */

  // Only the last logs are expected.
  [expectedLogs removeObjectsInRange:NSMakeRange(0, expectedLogs.count - expectedCapacity)];

  // Get logs from DB.
  loadedLogs = [self loadLogsWhere:nil];
  assertThat(expectedLogs, is(loadedLogs));
}

- (NSArray<id<MSLog>> *)generateAndSaveLogsWithCount:(NSUInteger)count groupId:(NSString *)groupId {
  NSMutableArray<id<MSLog>> *logs = [NSMutableArray arrayWithCapacity:count];
  NSUInteger truelogCount;
  for (NSUInteger i = 0; i < count; ++i) {
    id<MSLog> log = [MSAbstractLog new];
    log.sid = MS_UUID_STRING;
    NSData *logData = [NSKeyedArchiver archivedDataWithRootObject:log];
    NSString *base64Data = [logData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    NSString *addLogQuery =
        [NSString stringWithFormat:@"INSERT INTO \"%@\" (\"%@\", \"%@\") VALUES ('%@', '%@')", kMSLogTableName,
                                   kMSGroupIdColumnName, kMSLogColumnName, groupId, base64Data];
    [self.sut executeNonSelectionQuery:addLogQuery];
    [logs addObject:log];
  }

  // Check the insertion worked.
  truelogCount =
      [self.sut countEntriesForTable:kMSLogTableName
                           condition:[NSString stringWithFormat:@"\"%@\" = '%@'", kMSGroupIdColumnName, groupId]];
  assertThatUnsignedInteger(truelogCount, equalToUnsignedInteger(count));
  return logs;
}

- (NSArray<id<MSLog>> *)loadLogsWhere:(nullable NSString *)whereCondition {
  NSMutableArray<id<MSLog>> *logs = [NSMutableArray<id<MSLog>> new];
  NSMutableString *selectLogQuery = [NSMutableString stringWithFormat:@"SELECT * FROM \"%@\"", kMSLogTableName];
  if (whereCondition.length > 0) {
    [selectLogQuery appendFormat:@" WHERE %@", whereCondition];
  }
  NSArray<NSArray *> *result = [self.sut executeSelectionQuery:selectLogQuery];
  for (NSArray *row in result) {
    NSString *base64Data = row[2];
    NSData *logData =
        [[NSData alloc] initWithBase64EncodedString:base64Data options:NSDataBase64DecodingIgnoreUnknownCharacters];
    id<MSLog> log = [NSKeyedUnarchiver unarchiveObjectWithData:logData];
    [logs addObject:log];
  }
  return logs;
}

@end
