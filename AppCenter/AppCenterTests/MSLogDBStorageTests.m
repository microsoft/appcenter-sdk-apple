#import "MSAbstractLogInternal.h"
#import "MSCommonSchemaLog.h"
#import "MSDBStoragePrivate.h"
#import "MSLogDBStoragePrivate.h"
#import "MSTestFrameworks.h"
#import "MSUtility.h"
#import "MSUtility+Date.h"
#import "MSUtility+StringFormatting.h"

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
  [self.sut deleteDatabase];
  [super tearDown];
}

- (void)testLoadTooManyLogs {

  // If
  NSUInteger expectedLogsCount = 5;
  NSMutableArray *expectedLogs =
      [[self generateAndSaveLogsWithCount:expectedLogsCount + 1
                                  groupId:kMSTestGroupId] mutableCopy];
  [expectedLogs removeLastObject];

  // When
  BOOL moreLogsAvailable =
      [self.sut loadLogsWithGroupId:kMSTestGroupId
                              limit:expectedLogsCount
                     withCompletion:^(NSArray<id<MSLog>> *_Nonnull logArray,
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
  NSArray *expectedLogs = [self generateAndSaveLogsWithCount:expectedLogsCount
                                                     groupId:kMSTestGroupId];

  // When
  BOOL moreLogsAvailable =
      [self.sut loadLogsWithGroupId:kMSTestGroupId
                              limit:expectedLogsCount
                     withCompletion:^(NSArray<id<MSLog>> *_Nonnull logArray,
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
  NSArray *expectedLogs = [self generateAndSaveLogsWithCount:expectedLogsCount
                                                     groupId:kMSTestGroupId];

  // When
  BOOL moreLogsAvailable =
      [self.sut loadLogsWithGroupId:kMSTestGroupId
                              limit:limit
                     withCompletion:^(NSArray<id<MSLog>> *_Nonnull logArray,
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
  __block NSArray *expectedLogs =
      [[self generateAndSaveLogsWithCount:expectedLogsCount
                                  groupId:kMSTestGroupId] mutableCopy];
  __block NSArray *unexpectedLogs;
  __block NSString *unexpectedBatchId;

  // Load some logs to trigger a new batch.
  [self.sut loadLogsWithGroupId:kMSTestGroupId
                          limit:2
                 withCompletion:^(NSArray<id<MSLog>> *_Nonnull logArray,
                                  NSString *_Nonnull batchId) {

                   // Those values shouldn't be in the next batch.
                   unexpectedLogs = logArray;
                   unexpectedBatchId = batchId;
                 }];

  // When
  BOOL moreLogsAvailable = [self.sut
      loadLogsWithGroupId:kMSTestGroupId
                    limit:expectedLogsCount
           withCompletion:^(NSArray<id<MSLog>> *_Nonnull logArray,
                            NSString *_Nonnull batchId) {

             // Then
             // Logs from previous batch are not expected here.
             NSPredicate *predicate = [NSPredicate
                 predicateWithFormat:@"NOT (SELF IN %@)", unexpectedLogs];
             expectedLogs =
                 [expectedLogs filteredArrayUsingPredicate:predicate];
             assertThat(batchId, notNilValue());
             assertThat(expectedLogs, is(logArray));
             assertThat(batchId, isNot(unexpectedBatchId));
           }];
  XCTAssertFalse(moreLogsAvailable);
}

- (void)testLoadLogsWhilePendingBatchesFromOtherGroupId {

  // If
  NSUInteger expectedLogsCount = 5;
  __block NSArray *expectedLogs =
      [[self generateAndSaveLogsWithCount:expectedLogsCount
                                  groupId:kMSTestGroupId] mutableCopy];
  __block NSArray *unexpectedLogs;
  __block NSString *unexpectedBatchId;

  // Load some logs to trigger a new batch from another group Id.
  [self.sut loadLogsWithGroupId:kMSAnotherTestGroupId
                          limit:2
                 withCompletion:^(NSArray<id<MSLog>> *_Nonnull logArray,
                                  NSString *_Nonnull batchId) {

                   // Those values shouldn't be in the next batch.
                   unexpectedLogs = logArray;
                   unexpectedBatchId = batchId;
                 }];

  // When
  BOOL moreLogsAvailable = [self.sut
      loadLogsWithGroupId:kMSTestGroupId
                    limit:expectedLogsCount
           withCompletion:^(NSArray<id<MSLog>> *_Nonnull logArray,
                            NSString *_Nonnull batchId) {

             // Then
             // Logs from previous batch are not expected here.
             NSPredicate *predicate = [NSPredicate
                 predicateWithFormat:@"NOT (SELF IN %@)", unexpectedLogs];
             expectedLogs =
                 [expectedLogs filteredArrayUsingPredicate:predicate];
             assertThat(batchId, notNilValue());
             assertThat(expectedLogs, is(logArray));
             assertThat(batchId, isNot(unexpectedBatchId));
           }];
  XCTAssertFalse(moreLogsAvailable);
}

- (void)testLoadUnlimitedLogs {

  // If
  NSUInteger expectedLogsCount = 42;
  NSArray *expectedLogs = [self generateAndSaveLogsWithCount:expectedLogsCount
                                                     groupId:kMSTestGroupId];

  // When
  NSArray *logs = [self.sut logsFromDBWithGroupId:kMSTestGroupId];

  // Then
  assertThat(expectedLogs, is(logs));
}

- (void)testDeleteLogsWithGroupId {

  // Test deletion with no batch.

  // If
  [self.sut.batches removeAllObjects];
  [self generateAndSaveLogsWithCount:5 groupId:kMSTestGroupId];

  // When
  [self.sut deleteLogsWithGroupId:kMSTestGroupId];

  // Then
  assertThatInteger(
      [self.sut countEntriesForTable:kMSLogTableName condition:nil],
      equalToInteger(0));
  assertThatInteger(self.sut.batches.count, equalToInteger(0));

  // Test deletion with only the batch to delete.

  // If
  // Generate logs and create one batch by loading logs.
  [self generateAndSaveLogsWithCount:5 groupId:kMSTestGroupId];
  [self.sut loadLogsWithGroupId:kMSTestGroupId limit:2 withCompletion:nil];

  // When
  [self.sut deleteLogsWithGroupId:kMSTestGroupId];

  // Then
  assertThatInteger(
      [self.sut countEntriesForTable:kMSLogTableName condition:nil],
      equalToInteger(0));
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
  assertThatInteger(
      [self.sut countEntriesForTable:kMSLogTableName condition:nil],
      equalToInteger(0));
  assertThatInteger(self.sut.batches.count, equalToInteger(0));

  // Test deletion with the batch to delete and batches from other groups.

  // If
  // Generate logs and create two batches of different group Ids.
  __block NSString *batchIdToDelete;
  [self generateAndSaveLogsWithCount:2 groupId:kMSTestGroupId];
  NSArray *expectedLogs =
      [self generateAndSaveLogsWithCount:3 groupId:kMSAnotherTestGroupId];
  [self.sut loadLogsWithGroupId:kMSTestGroupId
                          limit:2
                 withCompletion:^(__attribute__((unused))
                                  NSArray<MSLog> *_Nonnull logArray,
                                  NSString *batchId) {
                   batchIdToDelete = batchId;
                 }];
  [self.sut loadLogsWithGroupId:kMSAnotherTestGroupId
                          limit:2
                 withCompletion:nil];

  // When
  [self.sut deleteLogsWithGroupId:kMSTestGroupId];

  // Then
  NSArray *remainingLogs = [self loadLogsWhere:nil];
  assertThat(expectedLogs, is(remainingLogs));
  assertThatInteger(self.sut.batches.count, equalToInteger(1));
  assertThatBool([self.sut.batches.allKeys containsObject:batchIdToDelete],
                 isFalse());
}

- (void)testDeleteLogsByBatchIdWithOnlyOnePendingBatch {

  // If
  __block NSString *batchIdToDelete;
  __block NSArray *expectedLogs;
  NSString *condition;
  NSArray *remainingLogs;
  [self.sut.batches removeAllObjects];
  NSArray *savedLogs =
      [self generateAndSaveLogsWithCount:5 groupId:kMSTestGroupId];
  [self.sut loadLogsWithGroupId:kMSTestGroupId
                          limit:2
                 withCompletion:^(NSArray<MSLog> *_Nonnull logArray,
                                  NSString *batchId) {
                   batchIdToDelete = batchId;
                   NSPredicate *predicate = [NSPredicate
                       predicateWithFormat:@"NOT (self IN %@)", logArray];
                   expectedLogs =
                       [savedLogs filteredArrayUsingPredicate:predicate];
                 }];
  NSArray *logIdsToDelete = self.sut.batches[batchIdToDelete];

  // When
  [self.sut deleteLogsWithBatchId:batchIdToDelete groupId:kMSTestGroupId];

  // Then
  remainingLogs = [self loadLogsWhere:nil];
  condition = [NSString
      stringWithFormat:@"%@ IN (%@)", kMSIdColumnName,
                       [logIdsToDelete componentsJoinedByString:@", "]];
  assertThatInteger(
      [self.sut countEntriesForTable:kMSLogTableName condition:condition],
      equalToInteger(0));
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
  NSArray *savedLogs =
      [self generateAndSaveLogsWithCount:5 groupId:kMSTestGroupId];
  [self.sut loadLogsWithGroupId:kMSTestGroupId
                          limit:2
                 withCompletion:^(NSArray<MSLog> *_Nonnull logArray,
                                  NSString *batchId) {
                   batchIdToDelete = batchId;

                   // Intersect arrays to build expected remaining logs.
                   NSPredicate *predicate = [NSPredicate
                       predicateWithFormat:@"NOT (self IN %@)", logArray];
                   expectedLogs =
                       [savedLogs filteredArrayUsingPredicate:predicate];
                 }];
  NSArray *logIdsToDelete = self.sut.batches[batchIdToDelete];

  // Trigger another batch.
  [self.sut loadLogsWithGroupId:kMSTestGroupId limit:2 withCompletion:nil];

  // When
  [self.sut deleteLogsWithBatchId:batchIdToDelete groupId:kMSTestGroupId];

  // Then
  remainingLogs = [self loadLogsWhere:nil];
  condition = [NSString
      stringWithFormat:@"%@ IN (%@)", kMSIdColumnName,
                       [logIdsToDelete componentsJoinedByString:@", "]];
  assertThatInteger(
      [self.sut countEntriesForTable:kMSLogTableName condition:condition],
      equalToInteger(0));
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
  NSArray *savedLogs =
      [self generateAndSaveLogsWithCount:5 groupId:kMSTestGroupId];
  NSArray *savedLogsFromOtherGroup =
      [self generateAndSaveLogsWithCount:3 groupId:kMSAnotherTestGroupId];
  [self.sut loadLogsWithGroupId:kMSTestGroupId
                          limit:2
                 withCompletion:^(NSArray<MSLog> *_Nonnull logArray,
                                  NSString *batchId) {
                   batchIdToDelete = batchId;

                   // Intersect arrays to build expected remaining logs.
                   NSPredicate *predicate = [NSPredicate
                       predicateWithFormat:@"NOT (self IN %@)", logArray];
                   expectedLogs = [[savedLogs
                       filteredArrayUsingPredicate:predicate] mutableCopy];

                   // Remaining logs should contains logs for other groups.
                   [expectedLogs addObjectsFromArray:savedLogsFromOtherGroup];
                 }];
  NSArray *logIdsToDelete = self.sut.batches[batchIdToDelete];

  // Trigger another batch.
  [self.sut loadLogsWithGroupId:kMSAnotherTestGroupId
                          limit:2
                 withCompletion:nil];

  // When
  [self.sut deleteLogsWithBatchId:batchIdToDelete groupId:kMSTestGroupId];

  // Then
  remainingLogs = [self loadLogsWhere:nil];
  condition = [NSString
      stringWithFormat:@"%@ IN (%@)", kMSIdColumnName,
                       [logIdsToDelete componentsJoinedByString:@", "]];
  assertThatInteger(
      [self.sut countEntriesForTable:kMSLogTableName condition:condition],
      equalToInteger(0));
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
                 withCompletion:^(NSArray<MSLog> *_Nonnull logArray,
                                  __unused NSString *batchId) {
                   id<MSLog> restoredLog = logArray[0];
                   NSString *restoredTargetToken =
                       [[restoredLog transmissionTargetTokens] anyObject];
                   assertThatInt([[restoredLog transmissionTargetTokens] count],
                                 equalToInt(1));
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
                 withCompletion:^(NSArray<MSLog> *_Nonnull logArray,
                                  __unused NSString *batchId) {
                   assertThatInt([[logArray[0] transmissionTargetTokens] count],
                                 equalToInt(0));
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
  assertThatInteger(
      [self.sut countEntriesForTable:kMSLogTableName condition:nil],
      equalToInteger(5));
}

- (void)testStorageCapacity {

  // If
  // Test just below the limit.
  short expectedCapacity = 3;
  __block int logCount = 2;
  self.sut = [[MSLogDBStorage alloc] initWithCapacity:expectedCapacity];
  NSMutableArray<id<MSLog>> *expectedLogs = [NSMutableArray<id<MSLog>> new];
  NSArray<id<MSLog>> *loadedLogs;

  // When
  for (int i = 0; i < logCount; i++) {
    id<MSLog> log = [MSAbstractLog new];
    log.sid = MS_UUID_STRING;
    [self.sut saveLog:log withGroupId:kMSTestGroupId];
    [expectedLogs addObject:log];
  }

  // Then
  // Get logs from DB.
  loadedLogs = [self loadLogsWhere:nil];
  assertThat(expectedLogs, is(loadedLogs));

  // Test at the limit.

  // If
  [self.sut deleteDatabase];
  [expectedLogs removeAllObjects];
  expectedCapacity = 2;
  self.sut = [[MSLogDBStorage alloc] initWithCapacity:expectedCapacity];

  // When
  for (int i = 0; i < logCount; i++) {
    id<MSLog> log = [MSAbstractLog new];
    log.sid = MS_UUID_STRING;

    // Save this log.
    [self.sut saveLog:log withGroupId:kMSTestGroupId];
    [expectedLogs addObject:log];
  }

  // Then
  // Get logs from DB.
  loadedLogs = [self loadLogsWhere:nil];
  assertThat(expectedLogs, is(loadedLogs));

  // Test just over the limit.

  // If
  [self.sut deleteDatabase];
  [expectedLogs removeAllObjects];
  expectedCapacity = 1;
  self.sut = [[MSLogDBStorage alloc] initWithCapacity:expectedCapacity];

  // When
  for (int i = 0; i < logCount; i++) {
    id<MSLog> log = [MSAbstractLog new];
    log.sid = MS_UUID_STRING;

    // Save this log.
    [self.sut saveLog:log withGroupId:kMSTestGroupId];
    [expectedLogs addObject:log];
  }

  // Then
  // The first is expected to be removed.
  [expectedLogs removeObjectAtIndex:0];

  // Get logs from DB.
  loadedLogs = [self loadLogsWhere:nil];
  assertThat(expectedLogs, is(loadedLogs));

  // Test way over the limit.

  // If
  [self.sut deleteDatabase];
  logCount = 10;
  [expectedLogs removeAllObjects];
  expectedCapacity = 1;
  self.sut = [[MSLogDBStorage alloc] initWithCapacity:expectedCapacity];

  // When
  for (int i = 0; i < logCount; i++) {
    id<MSLog> log = [MSAbstractLog new];
    log.sid = MS_UUID_STRING;

    // Save this log.
    [self.sut saveLog:log withGroupId:kMSTestGroupId];
    [expectedLogs addObject:log];
  }

  // Then
  // Only the last logs are expected.
  [expectedLogs removeObjectsInRange:NSMakeRange(0, expectedLogs.count -
                                                        expectedCapacity)];

  // Get logs from DB.
  loadedLogs = [self loadLogsWhere:nil];
  assertThat(expectedLogs, is(loadedLogs));
}

- (void)testMigration {

  // If
  [self.sut deleteDatabase];

  // Create old version db.
  // DO NOT CHANGE. THIS IS ALREADY PUBLISHED SCHEMA.
  MSDBSchema *schema0 = @{
    kMSLogTableName : @[
      @{
        kMSIdColumnName : @[
          kMSSQLiteTypeInteger, kMSSQLiteConstraintPrimaryKey,
          kMSSQLiteConstraintAutoincrement
        ]
      },
      @{
        kMSGroupIdColumnName :
            @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]
      },
      @{kMSLogColumnName : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]}
    ]
  };
  MSDBStorage *storage0 = [[MSDBStorage alloc] initWithSchema:schema0
                                                      version:0
                                                     filename:kMSDBFileName];
  [self generateAndSaveLogsWithCount:10
                             groupId:kMSTestGroupId
                             storage:storage0];

  // When
  self.sut = [[MSLogDBStorage alloc] initWithCapacity:kMSTestMaxCapacity];

  // Then
  assertThatInt([self loadLogsWhere:nil].count, equalToUnsignedInt(10));
  NSString *currentTable = [self.sut
      executeSelectionQuery:
          [NSString
              stringWithFormat:@"SELECT sql FROM sqlite_master WHERE name='%@'",
                               kMSLogTableName]][0][0];
  assertThat(currentTable, is(@"CREATE TABLE \"logs\" ("
                              @"\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, "
                              @"\"groupId\" TEXT NOT NULL, "
                              @"\"log\" TEXT NOT NULL, "
                              @"\"targetToken\" TEXT)"));
}

- (NSArray<id<MSLog>> *)generateAndSaveLogsWithCount:(NSUInteger)count
                                             groupId:(NSString *)groupId {
  return [self generateAndSaveLogsWithCount:count
                                    groupId:groupId
                                    storage:self.sut];
}

- (NSArray<id<MSLog>> *)generateAndSaveLogsWithCount:(NSUInteger)count
                                             groupId:(NSString *)groupId
                                             storage:(MSDBStorage *)storage {
  NSMutableArray<id<MSLog>> *logs = [NSMutableArray arrayWithCapacity:count];
  NSUInteger truelogCount;
  for (NSUInteger i = 0; i < count; ++i) {
    id<MSLog> log = [MSAbstractLog new];
    log.sid = MS_UUID_STRING;
    NSData *logData = [NSKeyedArchiver archivedDataWithRootObject:log];
    NSString *base64Data = [logData
        base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    NSString *addLogQuery = [NSString
        stringWithFormat:
            @"INSERT INTO \"%@\" (\"%@\", \"%@\") VALUES ('%@', '%@')",
            kMSLogTableName, kMSGroupIdColumnName, kMSLogColumnName, groupId,
            base64Data];
    [storage executeNonSelectionQuery:addLogQuery];
    [logs addObject:log];
  }

  // Check the insertion worked.
  truelogCount = [storage
      countEntriesForTable:kMSLogTableName
                 condition:[NSString stringWithFormat:@"\"%@\" = '%@'",
                                                      kMSGroupIdColumnName,
                                                      groupId]];
  assertThatUnsignedInteger(truelogCount, equalToUnsignedInteger(count));
  return logs;
}

- (NSArray<id<MSLog>> *)loadLogsWhere:(nullable NSString *)whereCondition {
  NSMutableArray<id<MSLog>> *logs = [NSMutableArray<id<MSLog>> new];
  NSMutableString *selectLogQuery = [NSMutableString
      stringWithFormat:@"SELECT * FROM \"%@\"", kMSLogTableName];
  if (whereCondition.length > 0) {
    [selectLogQuery appendFormat:@" WHERE %@", whereCondition];
  }
  NSArray<NSArray *> *result = [self.sut executeSelectionQuery:selectLogQuery];
  for (NSArray *row in result) {
    NSString *base64Data = row[2];
    NSData *logData = [[NSData alloc]
        initWithBase64EncodedString:base64Data
                            options:
                                NSDataBase64DecodingIgnoreUnknownCharacters];
    id<MSLog> log = [NSKeyedUnarchiver unarchiveObjectWithData:logData];
    [logs addObject:log];
  }
  return logs;
}

@end
