#import <sqlite3.h>

#import "MSAbstractLogInternal.h"
#import "MSDBStoragePrivate.h"
#import "MSLogDBStoragePrivate.h"
#import "MSLogDBStorageVersion.h"
#import "MSLogWithProperties.h"
#import "MSStorageTestUtil.h"
#import "MSTestFrameworks.h"
#import "MSUtility.h"

static NSString *const kMSTestGroupId = @"TestGroupId";
static NSString *const kMSAnotherTestGroupId = @"AnotherGroupId";

// 40 KiB (10 pages by 4 KiB).
static const long kMSTestStorageSizeMinimumUpperLimitInBytes = 40 * 1024;

@interface MSLogDBStorageTests : XCTestCase

@property(nonatomic) MSLogDBStorage *sut;
@property(nonatomic) MSStorageTestUtil *storageTestUtil;

@end

@implementation MSLogDBStorageTests

#pragma mark - Setup

- (void)setUp {
  [super setUp];
  self.storageTestUtil = [[MSStorageTestUtil alloc] initWithDbFileName:kMSDBFileName];
  [self.storageTestUtil deleteDatabase];
  XCTAssertEqual([self.storageTestUtil getDataLengthInBytes], 0);
  self.sut = OCMPartialMock([MSLogDBStorage new]);
  OCMStub([self.sut executeNonSelectionQuery:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        NSString *query;
        [invocation getArgument:&query atIndex:2];
        [self validateQuerySyntax:query];
      })
      .andForwardToRealObject();
}

- (void)tearDown {
  [self.storageTestUtil deleteDatabase];
  [super tearDown];
}

- (void)testLoadTooManyLogs {

  // If
  NSUInteger expectedLogsCount = 5;
  NSMutableArray *expectedLogs = [[self generateAndSaveLogsWithCount:expectedLogsCount + 1
                                                             groupId:kMSTestGroupId
                                                               flags:MSFlagsDefault
                                              andVerifyLogGeneration:YES] mutableCopy];
  [expectedLogs removeLastObject];

  // When
  BOOL moreLogsAvailable = [self.sut loadLogsWithGroupId:kMSTestGroupId
                                                   limit:expectedLogsCount
                                      excludedTargetKeys:nil
                                       completionHandler:^(NSArray<id<MSLog>> *_Nonnull logArray, NSString *_Nonnull batchId) {
                                         // Then
                                         assertThat(batchId, notNilValue());
                                         assertThat(expectedLogs, is(logArray));
                                       }];
  XCTAssertTrue(moreLogsAvailable);
}

- (void)testLoadJustEnoughNormalLogs {

  // If
  NSUInteger expectedLogsCount = 5;
  NSArray *expectedLogs = [self generateAndSaveLogsWithCount:expectedLogsCount
                                                     groupId:kMSTestGroupId
                                                       flags:MSFlagsPersistenceNormal
                                      andVerifyLogGeneration:YES];

  // When
  BOOL moreLogsAvailable = [self.sut loadLogsWithGroupId:kMSTestGroupId
                                                   limit:expectedLogsCount
                                      excludedTargetKeys:nil
                                       completionHandler:^(NSArray<id<MSLog>> *_Nonnull logArray, NSString *_Nonnull batchId) {
                                         // Then
                                         assertThat(batchId, notNilValue());
                                         assertThat(expectedLogs, is(logArray));
                                       }];
  XCTAssertFalse(moreLogsAvailable);
}

- (void)testLoadJustEnoughMixedPriorityLogs {

  // If
  NSUInteger segmentLogCount = 2;
  NSUInteger expectedLogsCount = segmentLogCount * 4;
  NSMutableArray *expectedLogs = [NSMutableArray new];

  // Create 2 normal logs.
  NSMutableArray *normalLogs = [[self generateAndSaveLogsWithCount:segmentLogCount
                                                           groupId:kMSTestGroupId
                                                             flags:MSFlagsPersistenceNormal
                                            andVerifyLogGeneration:YES] mutableCopy];

  // Create 2 critical logs.
  expectedLogs = [[expectedLogs arrayByAddingObjectsFromArray:[self generateAndSaveLogsWithCount:segmentLogCount
                                                                                         groupId:kMSTestGroupId
                                                                                           flags:MSFlagsPersistenceCritical
                                                                          andVerifyLogGeneration:YES]] mutableCopy];

  // Create 2 normal logs.
  normalLogs = [[normalLogs arrayByAddingObjectsFromArray:[self generateAndSaveLogsWithCount:segmentLogCount
                                                                                     groupId:kMSTestGroupId
                                                                                       flags:MSFlagsPersistenceNormal
                                                                      andVerifyLogGeneration:NO]] mutableCopy];

  // Create 2 critical logs.
  expectedLogs = [[expectedLogs arrayByAddingObjectsFromArray:[self generateAndSaveLogsWithCount:segmentLogCount
                                                                                         groupId:kMSTestGroupId
                                                                                           flags:MSFlagsPersistenceCritical
                                                                          andVerifyLogGeneration:NO]] mutableCopy];

  // Build expected logs
  expectedLogs = [[expectedLogs arrayByAddingObjectsFromArray:normalLogs] mutableCopy];

  // When
  BOOL moreLogsAvailable = [self.sut loadLogsWithGroupId:kMSTestGroupId
                                                   limit:expectedLogsCount
                                      excludedTargetKeys:nil
                                       completionHandler:^(NSArray<id<MSLog>> *_Nonnull logArray, NSString *_Nonnull batchId) {
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
                                                     groupId:kMSTestGroupId
                                                       flags:MSFlagsDefault
                                      andVerifyLogGeneration:YES];

  // When
  BOOL moreLogsAvailable = [self.sut loadLogsWithGroupId:kMSTestGroupId
                                                   limit:limit
                                      excludedTargetKeys:nil
                                       completionHandler:^(NSArray<id<MSLog>> *_Nonnull logArray, NSString *_Nonnull batchId) {
                                         // Then
                                         assertThat(batchId, notNilValue());
                                         assertThat(expectedLogs, is(logArray));
                                       }];
  XCTAssertFalse(moreLogsAvailable);
}

- (void)testLoadLogsWhilePendingBatchesFromSameGroupId {

  // If
  NSUInteger expectedLogsCount = 5;
  __block NSArray *expectedLogs = [[self generateAndSaveLogsWithCount:expectedLogsCount
                                                              groupId:kMSTestGroupId
                                                                flags:MSFlagsDefault
                                               andVerifyLogGeneration:YES] mutableCopy];
  __block NSArray *unexpectedLogs;
  __block NSString *unexpectedBatchId;

  // Load some logs to trigger a new batch.
  [self.sut loadLogsWithGroupId:kMSTestGroupId
                          limit:2
             excludedTargetKeys:nil
              completionHandler:^(NSArray<id<MSLog>> *_Nonnull logArray, NSString *_Nonnull batchId) {
                // Those values shouldn't be in the next batch.
                unexpectedLogs = logArray;
                unexpectedBatchId = batchId;
              }];

  // When
  BOOL moreLogsAvailable = [self.sut loadLogsWithGroupId:kMSTestGroupId
                                                   limit:expectedLogsCount
                                      excludedTargetKeys:nil
                                       completionHandler:^(NSArray<id<MSLog>> *_Nonnull logArray, NSString *_Nonnull batchId) {
                                         // Then
                                         // Logs from previous batch are not expected here.
                                         NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)", unexpectedLogs];
                                         expectedLogs = [expectedLogs filteredArrayUsingPredicate:predicate];
                                         assertThat(batchId, notNilValue());
                                         assertThat(expectedLogs, is(logArray));
                                         assertThat(batchId, isNot(unexpectedBatchId));
                                       }];
  XCTAssertFalse(moreLogsAvailable);
}

- (void)testLoadCommonSchemaLogsWhilePendingBatchesWithSpecificTargetKeys {

  // If

  // Key: 1, group: A.
  MSCommonSchemaLog *log1 = [MSCommonSchemaLog new];
  [log1 addTransmissionTargetToken:@"1-t"];
  log1.iKey = @"o:1";
  [self.sut saveLog:log1 withGroupId:kMSTestGroupId flags:MSFlagsDefault];

  // Key: 2, group: A.
  MSCommonSchemaLog *log2 = [MSCommonSchemaLog new];
  [log2 addTransmissionTargetToken:@"2-t"];
  log2.iKey = @"o:2";
  [self.sut saveLog:log2 withGroupId:kMSTestGroupId flags:MSFlagsDefault];

  // Key: 2, group: B.
  MSCommonSchemaLog *log3 = [MSCommonSchemaLog new];
  [log3 addTransmissionTargetToken:@"2-t"];
  log3.iKey = @"o:2";
  [self.sut saveLog:log3 withGroupId:kMSAnotherTestGroupId flags:MSFlagsDefault];

  // Key: 1, group: A.
  MSCommonSchemaLog *log4 = [MSCommonSchemaLog new];
  [log4 addTransmissionTargetToken:@"1-t"];
  log4.iKey = @"o:1";
  [self.sut saveLog:log4 withGroupId:kMSTestGroupId flags:MSFlagsDefault];

  // Key: 2, group: A.
  MSCommonSchemaLog *log5 = [MSCommonSchemaLog new];
  [log5 addTransmissionTargetToken:@"2-t"];
  log5.iKey = @"o:2";
  [self.sut saveLog:log5 withGroupId:kMSTestGroupId flags:MSFlagsDefault];

  // When
  [self.sut loadLogsWithGroupId:kMSTestGroupId
                          limit:10
             excludedTargetKeys:@[ @"1" ]
              completionHandler:^(NSArray<MSLog> *_Nonnull logArray, __unused NSString *batchId) {
                // Then
                assertThatInt(logArray.count, equalToInt(2));
                for (MSCommonSchemaLog *log in logArray) {
                  XCTAssertTrue([log.iKey isEqualToString:@"o:2"]);
                }
              }];
  [self.sut loadLogsWithGroupId:kMSTestGroupId
                          limit:10
             excludedTargetKeys:@[ @"2" ]
              completionHandler:^(NSArray<MSLog> *_Nonnull logArray, __unused NSString *batchId) {
                // Then
                assertThatInt(logArray.count, equalToInt(2));
                for (MSCommonSchemaLog *log in logArray) {
                  XCTAssertTrue([log.iKey isEqualToString:@"o:1"]);
                }
              }];
  [self.sut loadLogsWithGroupId:kMSTestGroupId
                          limit:10
             excludedTargetKeys:nil
              completionHandler:^(NSArray<MSLog> *_Nonnull logArray, __unused NSString *batchId) {
                // Then
                assertThatInt(logArray.count, equalToInt(0));
              }];
}

- (void)testLoadCommonSchemaLogsWhilePendingBatchesWithTargetKeysForBackwardCompatibility {

  // If
  NSString *targetKeyFormat = @"testTargetKey%d";

  // When
  for (int i = 0; i < 20; i++) {
    MSCommonSchemaLog *log = [MSCommonSchemaLog new];
    if (i % 4 != 0) {
      NSString *targetKey = [NSString stringWithFormat:targetKeyFormat, i % 4];
      NSString *targetToken = [targetKey stringByAppendingString:@"-secret"];
      [log addTransmissionTargetToken:targetToken];
    }
    [self.sut saveLog:log withGroupId:kMSTestGroupId flags:MSFlagsDefault];
  }

  // Then
  [self.sut loadLogsWithGroupId:kMSTestGroupId
                          limit:20
             excludedTargetKeys:@[ @"testTargetKey1", @"testTargetKey2" ]
              completionHandler:^(NSArray<MSLog> *_Nonnull logArray, __unused NSString *batchId) {
                assertThatInt(logArray.count, equalToInt(5));
              }];
}

- (void)testLoadCommonSchemaLogsWhilePendingBatchesWithoutTargetKeysForBackwardCompatibility {

  // If
  NSString *targetKey = @"testTargetKey";

  // When
  for (int i = 0; i < 10; i++) {
    MSCommonSchemaLog *log = [MSCommonSchemaLog new];
    if (i < 5) {
      NSString *targetToken = [targetKey stringByAppendingString:@"-secret"];
      [log addTransmissionTargetToken:targetToken];
      log.iKey = targetKey;
    }
    [self.sut saveLog:log withGroupId:kMSTestGroupId flags:MSFlagsDefault];
  }

  // Then
  [self.sut loadLogsWithGroupId:kMSTestGroupId
                          limit:10
             excludedTargetKeys:nil
              completionHandler:^(NSArray<MSLog> *_Nonnull logArray, __unused NSString *batchId) {
                int iKeyCount = 0;
                for (MSCommonSchemaLog *log in logArray) {
                  if ([log.iKey isEqualToString:targetKey]) {
                    iKeyCount++;
                  }
                }
                XCTAssertEqual(iKeyCount, 5);
                XCTAssertEqual(logArray.count, 10);
              }];
}

- (void)testLoadLogsWhilePendingBatchesFromOtherGroupId {

  // If
  NSUInteger expectedLogsCount = 5;
  __block NSArray *expectedLogs = [[self generateAndSaveLogsWithCount:expectedLogsCount
                                                              groupId:kMSTestGroupId
                                                                flags:MSFlagsDefault
                                               andVerifyLogGeneration:YES] mutableCopy];
  __block NSArray *unexpectedLogs;
  __block NSString *unexpectedBatchId;

  // Load some logs to trigger a new batch from another group Id.
  [self.sut loadLogsWithGroupId:kMSAnotherTestGroupId
                          limit:2
             excludedTargetKeys:nil
              completionHandler:^(NSArray<id<MSLog>> *_Nonnull logArray, NSString *_Nonnull batchId) {
                // Those values shouldn't be in the next batch.
                unexpectedLogs = logArray;
                unexpectedBatchId = batchId;
              }];

  // When
  BOOL moreLogsAvailable = [self.sut loadLogsWithGroupId:kMSTestGroupId
                                                   limit:expectedLogsCount
                                      excludedTargetKeys:nil
                                       completionHandler:^(NSArray<id<MSLog>> *_Nonnull logArray, NSString *_Nonnull batchId) {
                                         // Then
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
  NSArray *expectedLogs = [self generateAndSaveLogsWithCount:expectedLogsCount
                                                     groupId:kMSTestGroupId
                                                       flags:MSFlagsDefault
                                      andVerifyLogGeneration:YES];

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
  [self generateAndSaveLogsWithCount:5 groupId:kMSTestGroupId flags:MSFlagsDefault andVerifyLogGeneration:YES];

  // When
  [self.sut deleteLogsWithGroupId:kMSTestGroupId];

  // Then
  assertThatInteger([self.sut countEntriesForTable:kMSLogTableName condition:nil], equalToInteger(0));
  assertThatInteger(self.sut.batches.count, equalToInteger(0));

  // Test deletion with only the batch to delete.

  // If
  // Generate logs and create one batch by loading logs.
  [self generateAndSaveLogsWithCount:5 groupId:kMSTestGroupId flags:MSFlagsDefault andVerifyLogGeneration:YES];
  [self.sut loadLogsWithGroupId:kMSTestGroupId limit:2 excludedTargetKeys:nil completionHandler:nil];

  // When
  [self.sut deleteLogsWithGroupId:kMSTestGroupId];

  // Then
  assertThatInteger([self.sut countEntriesForTable:kMSLogTableName condition:nil], equalToInteger(0));
  assertThatInteger(self.sut.batches.count, equalToInteger(0));

  // Test deletion with more than one batch to delete.

  // If
  // Generate logs and create two batches by loading logs twice.
  [self generateAndSaveLogsWithCount:5 groupId:kMSTestGroupId flags:MSFlagsDefault andVerifyLogGeneration:YES];
  [self.sut loadLogsWithGroupId:kMSTestGroupId limit:2 excludedTargetKeys:nil completionHandler:nil];
  [self.sut loadLogsWithGroupId:kMSTestGroupId limit:2 excludedTargetKeys:nil completionHandler:nil];

  // When
  [self.sut deleteLogsWithGroupId:kMSTestGroupId];

  // Then
  assertThatInteger([self.sut countEntriesForTable:kMSLogTableName condition:nil], equalToInteger(0));
  assertThatInteger(self.sut.batches.count, equalToInteger(0));

  // Test deletion with the batch to delete and batches from other groups.

  // If
  // Generate logs and create two batches of different group Ids.
  __block NSString *batchIdToDelete;
  [self generateAndSaveLogsWithCount:2 groupId:kMSTestGroupId flags:MSFlagsDefault andVerifyLogGeneration:YES];
  NSArray *expectedLogs = [self generateAndSaveLogsWithCount:3
                                                     groupId:kMSAnotherTestGroupId
                                                       flags:MSFlagsDefault
                                      andVerifyLogGeneration:YES];
  [self.sut loadLogsWithGroupId:kMSTestGroupId
                          limit:2
             excludedTargetKeys:nil
              completionHandler:^(__attribute__((unused)) NSArray<MSLog> *_Nonnull logArray, NSString *batchId) {
                batchIdToDelete = batchId;
              }];
  [self.sut loadLogsWithGroupId:kMSAnotherTestGroupId limit:2 excludedTargetKeys:nil completionHandler:nil];

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
  NSArray *savedLogs = [self generateAndSaveLogsWithCount:5 groupId:kMSTestGroupId flags:MSFlagsDefault andVerifyLogGeneration:YES];
  [self.sut loadLogsWithGroupId:kMSTestGroupId
                          limit:2
             excludedTargetKeys:nil
              completionHandler:^(NSArray<MSLog> *_Nonnull logArray, NSString *batchId) {
                batchIdToDelete = batchId;
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT (self IN %@)", logArray];
                expectedLogs = [savedLogs filteredArrayUsingPredicate:predicate];
              }];
  NSArray *logIdsToDelete = self.sut.batches[batchIdToDelete];

  // When
  [self.sut deleteLogsWithBatchId:batchIdToDelete groupId:kMSTestGroupId];

  // Then
  remainingLogs = [self loadLogsWhere:nil];
  condition = [NSString stringWithFormat:@"%@ IN (%@)", kMSIdColumnName, [logIdsToDelete componentsJoinedByString:@", "]];
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
  NSArray *savedLogs = [self generateAndSaveLogsWithCount:5 groupId:kMSTestGroupId flags:MSFlagsDefault andVerifyLogGeneration:YES];
  [self.sut loadLogsWithGroupId:kMSTestGroupId
                          limit:2
             excludedTargetKeys:nil
              completionHandler:^(NSArray<MSLog> *_Nonnull logArray, NSString *batchId) {
                batchIdToDelete = batchId;

                // Intersect arrays to build expected remaining logs.
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT (self IN %@)", logArray];
                expectedLogs = [savedLogs filteredArrayUsingPredicate:predicate];
              }];
  NSArray *logIdsToDelete = self.sut.batches[batchIdToDelete];

  // Trigger another batch.
  [self.sut loadLogsWithGroupId:kMSTestGroupId limit:2 excludedTargetKeys:nil completionHandler:nil];

  // When
  [self.sut deleteLogsWithBatchId:batchIdToDelete groupId:kMSTestGroupId];

  // Then
  remainingLogs = [self loadLogsWhere:nil];
  condition = [NSString stringWithFormat:@"%@ IN (%@)", kMSIdColumnName, [logIdsToDelete componentsJoinedByString:@", "]];
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
  NSArray *savedLogs = [self generateAndSaveLogsWithCount:5 groupId:kMSTestGroupId flags:MSFlagsDefault andVerifyLogGeneration:YES];
  NSArray *savedLogsFromOtherGroup = [self generateAndSaveLogsWithCount:3
                                                                groupId:kMSAnotherTestGroupId
                                                                  flags:MSFlagsDefault
                                                 andVerifyLogGeneration:YES];
  [self.sut loadLogsWithGroupId:kMSTestGroupId
                          limit:2
             excludedTargetKeys:nil
              completionHandler:^(NSArray<MSLog> *_Nonnull logArray, NSString *batchId) {
                batchIdToDelete = batchId;

                // Intersect arrays to build expected remaining logs.
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT (self IN %@)", logArray];
                expectedLogs = [[savedLogs filteredArrayUsingPredicate:predicate] mutableCopy];

                // Remaining logs should contains logs for other groups.
                [expectedLogs addObjectsFromArray:savedLogsFromOtherGroup];
              }];
  NSArray *logIdsToDelete = self.sut.batches[batchIdToDelete];

  // Trigger another batch.
  [self.sut loadLogsWithGroupId:kMSAnotherTestGroupId limit:2 excludedTargetKeys:nil completionHandler:nil];

  // When
  [self.sut deleteLogsWithBatchId:batchIdToDelete groupId:kMSTestGroupId];

  // Then
  remainingLogs = [self loadLogsWhere:nil];
  condition = [NSString stringWithFormat:@"%@ IN (%@)", kMSIdColumnName, [logIdsToDelete componentsJoinedByString:@", "]];
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
  [self.sut saveLog:log withGroupId:kMSTestGroupId flags:MSFlagsDefault];

  // Then
  [self.sut loadLogsWithGroupId:kMSTestGroupId
                          limit:1
             excludedTargetKeys:nil
              completionHandler:^(NSArray<MSLog> *_Nonnull logArray, __unused NSString *batchId) {
                id<MSLog> restoredLog = logArray[0];
                NSString *restoredTargetToken = [[restoredLog transmissionTargetTokens] anyObject];
                assertThatInt([restoredLog transmissionTargetTokens].count, equalToInt(1));
                XCTAssertEqualObjects(testTargetToken, restoredTargetToken);
              }];
}

- (void)testOnlyCommonSchemaLogTargetTokenIsSavedAndRestored {

  // If
  NSString *testTargetToken = @"testTargetToken";
  MSAbstractLog *log = [MSAbstractLog new];
  [log addTransmissionTargetToken:testTargetToken];

  // When
  [self.sut saveLog:log withGroupId:kMSTestGroupId flags:MSFlagsDefault];

  // Then
  [self.sut loadLogsWithGroupId:kMSTestGroupId
                          limit:1
             excludedTargetKeys:nil
              completionHandler:^(NSArray<MSLog> *_Nonnull logArray, __unused NSString *batchId) {
                assertThatInt([logArray[0] transmissionTargetTokens].count, equalToInt(0));
              }];
}

- (void)testDeleteLogsByBatchIdWithNoPendingBatches {

  // If
  [self.sut.batches removeAllObjects];
  [self generateAndSaveLogsWithCount:5 groupId:kMSTestGroupId flags:MSFlagsDefault andVerifyLogGeneration:YES];

  // When
  [self.sut deleteLogsWithBatchId:MS_UUID_STRING groupId:kMSTestGroupId];

  // Then
  assertThatInteger(self.sut.batches.count, equalToInteger(0));
  assertThatInteger([self.sut countEntriesForTable:kMSLogTableName condition:nil], equalToInteger(5));
}

- (void)testAddLogsWhenBelowStorageCapacity {

  // If
  long maxCapacityInBytes = kMSTestStorageSizeMinimumUpperLimitInBytes + 4 * 1024;
  long initialDataLengthInBytes = maxCapacityInBytes - 12 * 1024;
  MSAbstractLog *additionalLog = [MSAbstractLog new];
  additionalLog.sid = MS_UUID_STRING;
  NSArray *addedDbIds = [self fillDatabaseWithLogsOfSizeInBytes:initialDataLengthInBytes ofPriority:MSFlagsPersistenceNormal];

  // When
  [self.sut setMaxStorageSize:maxCapacityInBytes
            completionHandler:^(__unused BOOL success){
            }];

  // Then
  BOOL logSavedSuccessfully = [self.sut saveLog:additionalLog withGroupId:kMSAnotherTestGroupId flags:MSFlagsDefault];

  // Then
  XCTAssertTrue(logSavedSuccessfully);
  NSString *whereCondition = [NSString stringWithFormat:@"\"%@\" = '%@'", kMSGroupIdColumnName, kMSAnotherTestGroupId];
  NSArray<id<MSLog>> *loadedLogs = [self loadLogsWhere:whereCondition];
  NSArray<id<MSLog>> *allLogs = [self loadLogsWhere:nil];
  XCTAssertEqual(loadedLogs.count, 1);
  XCTAssertEqualObjects(loadedLogs[0].sid, additionalLog.sid);
  XCTAssertEqual(addedDbIds.count + 1, allLogs.count);
}

- (void)testAddCriticalLog {

  // If
  MSAbstractLog *aLog = [MSAbstractLog new];
  aLog.sid = MS_UUID_STRING;
  NSString *criticalLogsFilter =
      [NSString stringWithFormat:@"\"%@\" = '%u'", kMSPriorityColumnName, (unsigned int)MSFlagsPersistenceCritical];
  NSString *normalLogsFilter = [NSString stringWithFormat:@"\"%@\" = '%u'", kMSPriorityColumnName, (unsigned int)MSFlagsPersistenceNormal];

  // When
  [self.sut saveLog:aLog withGroupId:kMSTestGroupId flags:MSFlagsPersistenceCritical];

  // Then
  NSArray<id<MSLog>> *criticalLogs = [self loadLogsWhere:criticalLogsFilter];
  NSArray<id<MSLog>> *normalLogs = [self loadLogsWhere:normalLogsFilter];
  XCTAssertEqual(criticalLogs.count, 1);
  XCTAssertEqualObjects(criticalLogs[0].sid, aLog.sid);
  XCTAssertEqual(normalLogs.count, 0);
}

- (void)testAddNormalLog {

  // If
  MSAbstractLog *aLog = [MSAbstractLog new];
  aLog.sid = MS_UUID_STRING;
  NSString *criticalLogsFilter =
      [NSString stringWithFormat:@"\"%@\" = '%u'", kMSPriorityColumnName, (unsigned int)MSFlagsPersistenceCritical];
  NSString *normalLogsFilter = [NSString stringWithFormat:@"\"%@\" = '%u'", kMSPriorityColumnName, (unsigned int)MSFlagsPersistenceNormal];

  // When
  [self.sut saveLog:aLog withGroupId:kMSTestGroupId flags:MSFlagsPersistenceNormal];

  // Then
  NSArray<id<MSLog>> *criticalLogs = [self loadLogsWhere:criticalLogsFilter];
  NSArray<id<MSLog>> *normalLogs = [self loadLogsWhere:normalLogsFilter];
  XCTAssertEqual(normalLogs.count, 1);
  XCTAssertEqualObjects(normalLogs[0].sid, aLog.sid);
  XCTAssertEqual(criticalLogs.count, 0);
}

- (void)testAddLogsDoesNotExceedCapacity {

  // If
  long maxCapacityInBytes = kMSTestStorageSizeMinimumUpperLimitInBytes;
  [self fillDatabaseWithLogsOfSizeInBytes:maxCapacityInBytes ofPriority:MSFlagsPersistenceNormal];
  [self.sut setMaxStorageSize:maxCapacityInBytes
            completionHandler:^(__unused BOOL success){
            }];

  // When
  int additionalLogs = 0;
  while (additionalLogs <= 50) {
    MSAbstractLog *additionalLog = [MSAbstractLog new];
    BOOL logSavedSuccessfully = [self.sut saveLog:additionalLog withGroupId:kMSTestGroupId flags:MSFlagsDefault];
    ++additionalLogs;

    // Then
    XCTAssertTrue([self.storageTestUtil getDataLengthInBytes] <= maxCapacityInBytes);
    XCTAssertTrue(logSavedSuccessfully);
  }
}

- (void)testSaveNormalPriorityLogPurgesOldestNormalPriorityLogsWhenStorageFull {

  // If
  long maxCapacityInBytes = kMSTestStorageSizeMinimumUpperLimitInBytes + 4 * 1024;
  NSArray *addedDbIds = [self fillDatabaseWithLogsOfSizeInBytes:maxCapacityInBytes ofPriority:MSFlagsPersistenceNormal];
  NSNumber *firstLogDbId = addedDbIds[0];

  // When
  [self.sut setMaxStorageSize:maxCapacityInBytes
            completionHandler:^(__unused BOOL success){
            }];
  MSAbstractLog *additionalLog = [MSAbstractLog new];
  BOOL logSavedSuccessfully = [self.sut saveLog:additionalLog withGroupId:kMSAnotherTestGroupId flags:MSFlagsPersistenceNormal];

  // Then
  XCTAssertTrue([self.storageTestUtil getDataLengthInBytes] <= maxCapacityInBytes);
  XCTAssertTrue(logSavedSuccessfully);
  XCTAssertFalse([self containsLogWithDbId:firstLogDbId]);

  NSString *whereCondition = [NSString stringWithFormat:@"\"%@\" = '%@'", kMSGroupIdColumnName, kMSAnotherTestGroupId];
  NSArray<id<MSLog>> *loadedLogs = [self loadLogsWhere:whereCondition];
  XCTAssertEqual(loadedLogs.count, 1);
  XCTAssertEqualObjects(loadedLogs[0].sid, additionalLog.sid);
  XCTAssertEqual(1, [self findUnknownDBIdsFromKnownIdList:addedDbIds].count);
}

- (void)testSaveCriticalPriorityLogPurgesOldestNormalPriorityLogsWhenStorageFull {

  // If
  long maxCapacityInBytes = kMSTestStorageSizeMinimumUpperLimitInBytes + 4 * 1024;
  NSArray *addedDbIds = [self fillDatabaseWithLogsOfSizeInBytes:maxCapacityInBytes ofPriority:MSFlagsPersistenceNormal];
  NSNumber *firstLogDbId = addedDbIds[0];

  // When
  [self.sut setMaxStorageSize:maxCapacityInBytes
            completionHandler:^(__unused BOOL success){
            }];
  MSAbstractLog *additionalLog = [MSAbstractLog new];
  BOOL logSavedSuccessfully = [self.sut saveLog:additionalLog withGroupId:kMSAnotherTestGroupId flags:MSFlagsPersistenceCritical];

  // Then
  XCTAssertTrue([self.storageTestUtil getDataLengthInBytes] <= maxCapacityInBytes);
  XCTAssertTrue(logSavedSuccessfully);
  XCTAssertFalse([self containsLogWithDbId:firstLogDbId]);

  NSString *whereCondition = [NSString stringWithFormat:@"\"%@\" = '%@'", kMSGroupIdColumnName, kMSAnotherTestGroupId];
  NSArray<id<MSLog>> *loadedLogs = [self loadLogsWhere:whereCondition];
  XCTAssertEqual(loadedLogs.count, 1);
  XCTAssertEqualObjects(loadedLogs[0].sid, additionalLog.sid);
  XCTAssertEqual(1, [self findUnknownDBIdsFromKnownIdList:addedDbIds].count);
}

- (void)testSaveNormalPriorityLogDiscardsLogWhenStorageFullWithCriticalPriorityLogs {

  // If
  long maxCapacityInBytes = kMSTestStorageSizeMinimumUpperLimitInBytes + 4 * 1024;
  NSArray *addedDbIds = [self fillDatabaseWithLogsOfSizeInBytes:maxCapacityInBytes ofPriority:MSFlagsPersistenceCritical];

  // When
  [self.sut setMaxStorageSize:maxCapacityInBytes
            completionHandler:^(__unused BOOL success){
            }];
  MSAbstractLog *additionalLog = [MSAbstractLog new];
  BOOL logSavedSuccessfully = [self.sut saveLog:additionalLog withGroupId:kMSAnotherTestGroupId flags:MSFlagsPersistenceNormal];

  // Then
  XCTAssertTrue([self.storageTestUtil getDataLengthInBytes] <= maxCapacityInBytes);
  XCTAssertFalse(logSavedSuccessfully);
  for (NSNumber *dbId in addedDbIds) {
    XCTAssertTrue([self containsLogWithDbId:dbId]);
  }

  NSString *whereCondition = [NSString stringWithFormat:@"\"%@\" = '%@'", kMSGroupIdColumnName, kMSAnotherTestGroupId];
  NSArray<id<MSLog>> *loadedLogs = [self loadLogsWhere:whereCondition];
  XCTAssertEqual(loadedLogs.count, 0);
  XCTAssertEqual(0, [self findUnknownDBIdsFromKnownIdList:addedDbIds].count);
}

- (void)testSaveLogPurgesNormalPriorityLogWhenStorageFullWithMixedPriorityLogs {

  // If
  long maxCapacityInBytes = kMSTestStorageSizeMinimumUpperLimitInBytes + 4 * 1024;
  NSDictionary *addedDbIds = [self fillDatabaseWithMixedPriorityLogsOfSizeInBytesAndReturnDbIds:maxCapacityInBytes];
  NSNumber *oldestCriticalDbId = [((NSArray *)[addedDbIds objectForKey:[NSNumber numberWithInt:MSFlagsPersistenceCritical]]) firstObject];
  NSNumber *oldestNormalDbId = [((NSArray *)[addedDbIds objectForKey:[NSNumber numberWithInt:MSFlagsPersistenceNormal]]) firstObject];

  // When
  [self.sut setMaxStorageSize:maxCapacityInBytes
            completionHandler:^(__unused BOOL success){
            }];
  MSAbstractLog *additionalLog = [MSAbstractLog new];
  BOOL logSavedSuccessfully = [self.sut saveLog:additionalLog withGroupId:kMSAnotherTestGroupId flags:MSFlagsPersistenceNormal];

  // Then
  XCTAssertTrue([self.storageTestUtil getDataLengthInBytes] <= maxCapacityInBytes);
  XCTAssertTrue(logSavedSuccessfully);
  XCTAssertFalse([self containsLogWithDbId:oldestNormalDbId]);
  XCTAssertTrue([self containsLogWithDbId:oldestCriticalDbId]);
  NSString *whereCondition = [NSString stringWithFormat:@"\"%@\" = '%@'", kMSGroupIdColumnName, kMSAnotherTestGroupId];
  NSArray<id<MSLog>> *loadedLogs = [self loadLogsWhere:whereCondition];
  XCTAssertEqual(loadedLogs.count, 1);
  XCTAssertEqualObjects(loadedLogs[0].sid, additionalLog.sid);
  NSArray *knownIds = [NSArray new];
  for (NSArray<NSNumber *> *ids in [addedDbIds allValues]) {
    knownIds = [knownIds arrayByAddingObjectsFromArray:ids];
  }
  XCTAssertEqual(1, [self findUnknownDBIdsFromKnownIdList:knownIds].count);
}

- (void)testSaveLargeNormalPriorityLogDoesNotPurgeOldLogs {
  [self DoNotPurgeOldLogsWhenSavingLargeLogExceedsCapacityWithPriority:MSFlagsPersistenceNormal];
}

- (void)testSaveLargeCriticalPriorityLogDoesNotPurgeOldLogs {
  [self DoNotPurgeOldLogsWhenSavingLargeLogExceedsCapacityWithPriority:MSFlagsPersistenceCritical];
}

- (void)DoNotPurgeOldLogsWhenSavingLargeLogExceedsCapacityWithPriority:(MSFlags)priority {

  // If
  long maxCapacityInBytes = kMSTestStorageSizeMinimumUpperLimitInBytes + 4 * 1024;
  [self.sut setMaxStorageSize:maxCapacityInBytes
            completionHandler:^(__unused BOOL success){
            }];
  [self generateAndSaveLogsWithCount:1 groupId:kMSTestGroupId flags:MSFlagsPersistenceCritical andVerifyLogGeneration:YES];
  [self generateAndSaveLogsWithCount:2 groupId:kMSTestGroupId flags:MSFlagsPersistenceNormal andVerifyLogGeneration:YES];
  id<MSLog> largeLog = [self generateLogWithSize:@(maxCapacityInBytes)];
  sqlite3 *db = [self.storageTestUtil openDatabase];
  NSArray<NSNumber *> *criticalDbIds = [self dbIdsForPriority:MSFlagsPersistenceCritical inOpenedDatabase:db];
  NSArray<NSNumber *> *normalDbIds = [self dbIdsForPriority:MSFlagsPersistenceNormal inOpenedDatabase:db];
  sqlite3_close(db);

  // When
  BOOL logSavedSuccessfully = [self.sut saveLog:largeLog withGroupId:kMSAnotherTestGroupId flags:priority];

  // Then
  XCTAssertTrue([self.storageTestUtil getDataLengthInBytes] <= maxCapacityInBytes);
  XCTAssertFalse(logSavedSuccessfully);
  NSString *whereCondition = [NSString stringWithFormat:@"\"%@\" = '%@'", kMSGroupIdColumnName, kMSAnotherTestGroupId];
  NSArray<id<MSLog>> *loadedLogs = [self loadLogsWhere:whereCondition];
  XCTAssertEqual(loadedLogs.count, 0);
  NSArray *knownIds = [NSArray new];
  for (NSArray<NSNumber *> *ids in @[ criticalDbIds, normalDbIds ]) {
    knownIds = [knownIds arrayByAddingObjectsFromArray:ids];
  }
  XCTAssertEqual(0, [self findUnknownDBIdsFromKnownIdList:knownIds].count);
  for (NSNumber *dbId in normalDbIds) {
    XCTAssertTrue([self containsLogWithDbId:dbId]);
  }
  XCTAssertTrue([self containsLogWithDbId:[criticalDbIds firstObject]]);
}

- (void)testErrorDeletingOldestLog {

  // If
  id classMock = OCMClassMock([MSDBStorage class]);
  OCMStub([classMock executeNonSelectionQuery:startsWith(@"INSERT") inOpenedDatabase:[OCMArg anyPointer]]).andReturn(SQLITE_FULL);
  OCMStub([classMock executeNonSelectionQuery:startsWith(@"DELETE") inOpenedDatabase:[OCMArg anyPointer]]).andReturn(SQLITE_ERROR);

  // When
  MSAbstractLog *additionalLog = [MSAbstractLog new];
  BOOL logSavedSuccessfully = [self.sut saveLog:additionalLog withGroupId:kMSAnotherTestGroupId flags:MSFlagsDefault];

  // Then
  XCTAssertFalse(logSavedSuccessfully);
  [classMock stopMocking];
}

- (void)testCreateFromLatestSchema {

  // When
  self.sut = [MSLogDBStorage new];

  // Then
  NSString *currentTable =
      [self.sut executeSelectionQuery:[NSString stringWithFormat:@"SELECT sql FROM sqlite_master WHERE name='%@'", kMSLogTableName]][0][0];
  assertThat(currentTable, is(@"CREATE TABLE \"logs\" ("
                              @"\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, "
                              @"\"groupId\" TEXT NOT NULL, "
                              @"\"log\" TEXT NOT NULL, "
                              @"\"targetToken\" TEXT, "
                              @"\"targetKey\" TEXT, "
                              @"\"priority\" INTEGER)"));
  NSString *priorityIndex =
      [self.sut executeSelectionQuery:[NSString stringWithFormat:@"SELECT sql FROM sqlite_master WHERE name='ix_%@_%@'", kMSLogTableName,
                                                                 kMSPriorityColumnName]][0][0];
  assertThat(priorityIndex, is(@"CREATE INDEX \"ix_logs_priority\" ON \"logs\" (\"priority\")"));
}

- (void)testMigrationFromSchema0to3 {

  // If
  // Create old version db.
  // DO NOT CHANGE. THIS IS ALREADY PUBLISHED SCHEMA.
  MSDBSchema *schema0 = @{
    kMSLogTableName : @[
      @{kMSIdColumnName : @[ kMSSQLiteTypeInteger, kMSSQLiteConstraintPrimaryKey, kMSSQLiteConstraintAutoincrement ]},
      @{kMSGroupIdColumnName : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]},
      @{kMSLogColumnName : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]}
    ]
  };
  MSDBStorage *storage0 = [[MSDBStorage alloc] initWithSchema:schema0 version:kMSInitialVersion filename:kMSDBFileName];
  [self generateAndSaveLogsWithCount:10 size:nil groupId:kMSTestGroupId flags:MSFlagsDefault storage:storage0 andVerifyLogGeneration:YES];

  // When
  self.sut = [MSLogDBStorage new];

  // Then
  assertThatInt([self loadLogsWhere:nil].count, equalToUnsignedInt(10));
  NSString *currentTable =
      [self.sut executeSelectionQuery:[NSString stringWithFormat:@"SELECT sql FROM sqlite_master WHERE name='%@'", kMSLogTableName]][0][0];
  assertThat(currentTable, is(@"CREATE TABLE \"logs\" ("
                              @"\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, "
                              @"\"groupId\" TEXT NOT NULL, "
                              @"\"log\" TEXT NOT NULL, "
                              @"\"targetToken\" TEXT, "
                              @"\"targetKey\" TEXT, "
                              @"\"priority\" INTEGER)"));
  NSString *priorityIndex =
      [self.sut executeSelectionQuery:[NSString stringWithFormat:@"SELECT sql FROM sqlite_master WHERE name='ix_%@_%@'", kMSLogTableName,
                                                                 kMSPriorityColumnName]][0][0];
  assertThat(priorityIndex, is(@"CREATE INDEX \"ix_logs_priority\" ON \"logs\" (\"priority\")"));
}

- (void)testMigrationFromSchema1to3 {

  // If
  // Create old version db.
  // DO NOT CHANGE. THIS IS ALREADY PUBLISHED SCHEMA.
  MSDBSchema *schema1 = @{
    kMSLogTableName : @[
      @{kMSIdColumnName : @[ kMSSQLiteTypeInteger, kMSSQLiteConstraintPrimaryKey, kMSSQLiteConstraintAutoincrement ]},
      @{kMSGroupIdColumnName : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]},
      @{kMSLogColumnName : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]}, @{kMSTargetTokenColumnName : @[ kMSSQLiteTypeText ]}
    ]
  };
  MSDBStorage *storage1 = [[MSDBStorage alloc] initWithSchema:schema1 version:kMSTargetTokenVersion filename:kMSDBFileName];
  [self generateAndSaveLogsWithCount:10 size:nil groupId:kMSTestGroupId flags:MSFlagsDefault storage:storage1 andVerifyLogGeneration:YES];

  // When
  self.sut = [MSLogDBStorage new];

  // Then
  assertThatInt([self loadLogsWhere:nil].count, equalToUnsignedInt(10));
  NSString *currentTable =
      [self.sut executeSelectionQuery:[NSString stringWithFormat:@"SELECT sql FROM sqlite_master WHERE name='%@'", kMSLogTableName]][0][0];
  assertThat(currentTable, is(@"CREATE TABLE \"logs\" ("
                              @"\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, "
                              @"\"groupId\" TEXT NOT NULL, "
                              @"\"log\" TEXT NOT NULL, "
                              @"\"targetToken\" TEXT, "
                              @"\"targetKey\" TEXT, "
                              @"\"priority\" INTEGER)"));
  NSString *priorityIndex =
      [self.sut executeSelectionQuery:[NSString stringWithFormat:@"SELECT sql FROM sqlite_master WHERE name='ix_%@_%@'", kMSLogTableName,
                                                                 kMSPriorityColumnName]][0][0];
  assertThat(priorityIndex, is(@"CREATE INDEX \"ix_logs_priority\" ON \"logs\" (\"priority\")"));
}

- (void)testMigrationFromSchema2to3 {

  // If
  // Create old version db.
  // DO NOT CHANGE. THIS IS ALREADY PUBLISHED SCHEMA.
  MSDBSchema *schema2 = @{
    kMSLogTableName : @[
      @{kMSIdColumnName : @[ kMSSQLiteTypeInteger, kMSSQLiteConstraintPrimaryKey, kMSSQLiteConstraintAutoincrement ]},
      @{kMSGroupIdColumnName : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]},
      @{kMSLogColumnName : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]}, @{kMSTargetTokenColumnName : @[ kMSSQLiteTypeText ]},
      @{kMSTargetKeyColumnName : @[ kMSSQLiteTypeText ]}
    ]
  };
  MSDBStorage *storage2 = [[MSDBStorage alloc] initWithSchema:schema2 version:kMSTargetTokenVersion filename:kMSDBFileName];
  [self generateAndSaveLogsWithCount:10 size:nil groupId:kMSTestGroupId flags:MSFlagsDefault storage:storage2 andVerifyLogGeneration:YES];

  // When
  self.sut = [MSLogDBStorage new];

  // Then
  assertThatInt([self loadLogsWhere:nil].count, equalToUnsignedInt(10));
  NSString *currentTable =
      [self.sut executeSelectionQuery:[NSString stringWithFormat:@"SELECT sql FROM sqlite_master WHERE name='%@'", kMSLogTableName]][0][0];
  assertThat(currentTable, is(@"CREATE TABLE \"logs\" ("
                              @"\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, "
                              @"\"groupId\" TEXT NOT NULL, "
                              @"\"log\" TEXT NOT NULL, "
                              @"\"targetToken\" TEXT, "
                              @"\"targetKey\" TEXT, "
                              @"\"priority\" INTEGER)"));
  NSString *priorityIndex =
      [self.sut executeSelectionQuery:[NSString stringWithFormat:@"SELECT sql FROM sqlite_master WHERE name='ix_%@_%@'", kMSLogTableName,
                                                                 kMSPriorityColumnName]][0][0];
  assertThat(priorityIndex, is(@"CREATE INDEX \"ix_logs_priority\" ON \"logs\" (\"priority\")"));
}

#pragma mark - Helper methods

- (id<MSLog>)generateLogWithSize:(NSNumber *)size {
  MSLogWithProperties *log = [MSLogWithProperties new];
  if (size) {
    NSString *s = [@"" stringByPaddingToLength:[size unsignedIntegerValue] withString:@"." startingAtIndex:0];
    log.properties = [NSMutableDictionary new];
    [log.properties setValue:s forKey:@"s"];
  }
  log.sid = MS_UUID_STRING;
  return log;
}

- (NSArray<id<MSLog>> *)generateAndSaveLogsWithCount:(NSUInteger)count
                                             groupId:(NSString *)groupId
                                               flags:(MSFlags)flags
                              andVerifyLogGeneration:(BOOL)verify {
  return [self generateAndSaveLogsWithCount:count size:nil groupId:groupId flags:flags storage:self.sut andVerifyLogGeneration:verify];
}

- (NSArray<id<MSLog>> *)generateAndSaveLogsWithCount:(NSUInteger)count
                                                size:(NSNumber *)size
                                             groupId:(NSString *)groupId
                                               flags:(MSFlags)flags
                              andVerifyLogGeneration:(BOOL)verify {
  return [self generateAndSaveLogsWithCount:count size:size groupId:groupId flags:flags storage:self.sut andVerifyLogGeneration:verify];
}

- (NSArray<id<MSLog>> *)generateAndSaveLogsWithCount:(NSUInteger)count
                                                size:(NSNumber *)size
                                             groupId:(NSString *)groupId
                                               flags:(MSFlags)flags
                                             storage:(MSDBStorage *)storage
                              andVerifyLogGeneration:(BOOL)verify {
  NSMutableArray<id<MSLog>> *logs = [NSMutableArray arrayWithCapacity:count];
  NSUInteger trueLogCount;
  for (NSUInteger i = 0; i < count; ++i) {
    id<MSLog> log = [self generateLogWithSize:size];
    NSData *logData = [NSKeyedArchiver archivedDataWithRootObject:log];
    NSString *base64Data = [logData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    NSString *addLogQuery =
        [NSString stringWithFormat:@"INSERT INTO \"%@\" (\"%@\", \"%@\", \"%@\") VALUES ('%@', '%@', %u)", kMSLogTableName,
                                   kMSGroupIdColumnName, kMSLogColumnName, kMSPriorityColumnName, groupId, base64Data, (unsigned int)flags];
    [storage executeNonSelectionQuery:addLogQuery];
    [logs addObject:log];
  }

  if (verify) {

    // Check the insertion worked.
    trueLogCount = [storage countEntriesForTable:kMSLogTableName
                                       condition:[NSString stringWithFormat:@"\"%@\" = '%@' AND \"%@\" = %u", kMSGroupIdColumnName, groupId,
                                                                            kMSPriorityColumnName, (unsigned int)flags]];
    assertThatUnsignedInteger(trueLogCount, equalToUnsignedInteger(count));
  }
  return logs;
}

- (NSArray<NSNumber *> *)dbIdsForPriority:(MSFlags)flags inOpenedDatabase:(void *)db {
  NSString *selectLogQuery = [NSString stringWithFormat:@"SELECT \"%@\" FROM \"%@\" WHERE \"%@\" = %u ORDER BY \"%@\" ASC", kMSIdColumnName,
                                                        kMSLogTableName, kMSPriorityColumnName, (unsigned int)flags, kMSIdColumnName];
  NSArray<NSArray *> *entries = [MSDBStorage executeSelectionQuery:selectLogQuery inOpenedDatabase:db];
  NSMutableArray *ids = [NSMutableArray new];
  for (NSMutableArray *row in entries) {
    [ids addObject:row[0]];
  }
  return ids;
}

- (NSArray<id<MSLog>> *)loadLogsWhere:(nullable NSString *)whereCondition {
  NSMutableArray<id<MSLog>> *logs = [NSMutableArray<id<MSLog>> new];
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
        value = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, i)];
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
    NSData *logData = [[NSData alloc] initWithBase64EncodedString:base64Data options:NSDataBase64DecodingIgnoreUnknownCharacters];
    id<MSLog> log = [NSKeyedUnarchiver unarchiveObjectWithData:logData];
    [logs addObject:log];
  }
  sqlite3_close(db);
  return logs;
}

- (NSArray<NSNumber *> *)fillDatabaseWithLogsOfSizeInBytes:(long)sizeInBytes ofPriority:(MSFlags)priority {
  int result = 0;
  sqlite3 *db = [self.storageTestUtil openDatabase];
  sqlite3_stmt *statement = NULL;
  sqlite3_prepare_v2(db, "PRAGMA page_size;", -1, &statement, NULL);
  sqlite3_step(statement);
  int pageSize = sqlite3_column_int(statement, 0);
  sqlite3_finalize(statement);
  long maxPageCount = sizeInBytes / pageSize;
  sqlite3_exec(db, [[NSString stringWithFormat:@"PRAGMA max_page_count = %ld;", maxPageCount] UTF8String], NULL, NULL, NULL);
  do {
    MSAbstractLog *log = [MSAbstractLog new];
    NSData *logData = [NSKeyedArchiver archivedDataWithRootObject:log];
    NSString *base64Data = [logData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    NSString *addLogQuery = [NSString stringWithFormat:@"INSERT INTO \"%@\" (\"%@\", \"%@\", \"%@\") VALUES ('%@', '%@', %u)",
                                                       kMSLogTableName, kMSGroupIdColumnName, kMSLogColumnName, kMSPriorityColumnName,
                                                       kMSTestGroupId, base64Data, (unsigned int)priority];
    result = sqlite3_exec(db, [addLogQuery UTF8String], NULL, NULL, NULL);
  } while (result == SQLITE_OK);

  // Get DB IDs for logs
  NSString *selectLogQuery =
      [NSString stringWithFormat:@"SELECT \"%@\" FROM \"%@\" ORDER BY \"%@\" ASC", kMSIdColumnName, kMSLogTableName, kMSIdColumnName];
  NSArray<NSArray *> *entries = [MSDBStorage executeSelectionQuery:selectLogQuery inOpenedDatabase:db];
  NSMutableArray *ids = [NSMutableArray new];
  for (NSMutableArray *row in entries) {
    [ids addObject:row[0]];
  }
  sqlite3_close(db);

  return ids;
}

- (NSDictionary<NSNumber *, NSArray<NSNumber *> *> *)fillDatabaseWithMixedPriorityLogsOfSizeInBytesAndReturnDbIds:(long)sizeInBytes {
  int result = 0, count = 0;
  sqlite3 *db = [self.storageTestUtil openDatabase];
  sqlite3_stmt *statement = NULL;
  sqlite3_prepare_v2(db, "PRAGMA page_size;", -1, &statement, NULL);
  sqlite3_step(statement);
  int pageSize = sqlite3_column_int(statement, 0);
  sqlite3_finalize(statement);
  long maxPageCount = sizeInBytes / pageSize;
  sqlite3_exec(db, [[NSString stringWithFormat:@"PRAGMA max_page_count = %ld;", maxPageCount] UTF8String], NULL, NULL, NULL);
  do {
    MSAbstractLog *log = [MSAbstractLog new];
    NSData *logData = [NSKeyedArchiver archivedDataWithRootObject:log];
    NSString *base64Data = [logData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    NSString *addLogQuery =
        [NSString stringWithFormat:@"INSERT INTO \"%@\" (\"%@\", \"%@\", \"%@\") VALUES ('%@', '%@', %u)", kMSLogTableName,
                                   kMSGroupIdColumnName, kMSLogColumnName, kMSPriorityColumnName, kMSTestGroupId, base64Data,
                                   (unsigned int)(count++ % 2 == 0 ? MSFlagsPersistenceCritical : MSFlagsPersistenceNormal)];
    result = sqlite3_exec(db, [addLogQuery UTF8String], NULL, NULL, NULL);
  } while (result == SQLITE_OK);

  // Get DB IDs for logs
  NSMutableDictionary *ids = [NSMutableDictionary new];
  for (NSNumber *flag in @[ [NSNumber numberWithInt:MSFlagsPersistenceNormal], [NSNumber numberWithInt:MSFlagsPersistenceCritical] ]) {
    NSString *selectLogQuery =
        [NSString stringWithFormat:@"SELECT \"%@\" FROM \"%@\" WHERE \"%@\" = %u ORDER BY \"%@\" ASC", kMSIdColumnName, kMSLogTableName,
                                   kMSPriorityColumnName, (unsigned int)[flag unsignedIntegerValue], kMSIdColumnName];
    NSArray<NSArray *> *entries = [MSDBStorage executeSelectionQuery:selectLogQuery inOpenedDatabase:db];
    NSMutableArray *priorityIds = [NSMutableArray new];
    for (NSMutableArray *row in entries) {
      [priorityIds addObject:row[0]];
    }
    [ids setObject:priorityIds forKey:flag];
  }
  sqlite3_close(db);

  return ids;
}

- (BOOL)containsLogWithDbId:(NSNumber *)dbId {
  sqlite3 *db = [self.storageTestUtil openDatabase];
  NSString *selectLogQuery =
      [NSString stringWithFormat:@"SELECT COUNT(*) FROM \"%@\" WHERE \"%@\" = %@", kMSLogTableName, kMSIdColumnName, dbId];
  NSArray<NSArray<NSNumber *> *> *entries = [MSDBStorage executeSelectionQuery:selectLogQuery inOpenedDatabase:db];
  if (entries.count > 0) {
    return entries[0][0].unsignedIntegerValue > 0;
  }
  return NO;
}

- (NSArray<NSNumber *> *)findUnknownDBIdsFromKnownIdList:(NSArray<NSNumber *> *)idList {
  sqlite3 *db = [self.storageTestUtil openDatabase];
  NSString *selectLogQuery = [NSString stringWithFormat:@"SELECT \"%@\" FROM \"%@\" WHERE \"%@\" NOT IN (%@)", kMSIdColumnName,
                                                        kMSLogTableName, kMSIdColumnName, [idList componentsJoinedByString:@","]];
  NSArray<NSArray<NSNumber *> *> *entries = [MSDBStorage executeSelectionQuery:selectLogQuery inOpenedDatabase:db];
  if (entries.count > 0) {
    return entries[0];
  }
  return nil;
}

- (void)validateQuerySyntax:(NSString *)query {
  sqlite3 *db = [self.storageTestUtil openDatabase];
  NSString *statement = [NSString stringWithFormat:@"EXPLAIN %@", query];
  char *error;
  int result = sqlite3_exec(db, [statement UTF8String], NULL, NULL, &error);
  XCTAssert(result == SQLITE_OK, "%s", error);
  sqlite3_close(db);
}

@end
