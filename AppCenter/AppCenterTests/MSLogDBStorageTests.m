// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <sqlite3.h>

#import "MSAbstractLogInternal.h"
#import "MSDBStoragePrivate.h"
#import "MSLogDBStoragePrivate.h"
#import "MSLogDBStorageVersion.h"
#import "MSLogWithProperties.h"
#import "MSStorageBindableArray.h"
#import "MSStorageBindableType.h"
#import "MSStorageNumberType.h"
#import "MSStorageTestUtil.h"
#import "MSTestFrameworks.h"
#import "MSUtility.h"

static NSString *const kMSTestGroupId = @"TestGroupId";
static NSString *const kMSAnotherTestGroupId = @"AnotherGroupId";

// 40 KiB (10 pages by 4 KiB).
static const long kMSTestStorageSizeMinimumUpperLimitInBytes = 40 * 1024;

static NSString *const kMSLatestSchema = @"CREATE TABLE \"logs\" ("
                                         @"\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, "
                                         @"\"groupId\" TEXT NOT NULL, "
                                         @"\"log\" TEXT NOT NULL, "
                                         @"\"targetToken\" TEXT, "
                                         @"\"targetKey\" TEXT, "
                                         @"\"priority\" INTEGER)";

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
  OCMStub([self.sut executeNonSelectionQuery:OCMOCK_ANY withValues:OCMOCK_ANY])
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
                                                       flags:MSFlagsNormal
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
                                                             flags:MSFlagsNormal
                                            andVerifyLogGeneration:YES] mutableCopy];

  // Create 2 critical logs.
  expectedLogs = [[expectedLogs arrayByAddingObjectsFromArray:[self generateAndSaveLogsWithCount:segmentLogCount
                                                                                         groupId:kMSTestGroupId
                                                                                           flags:MSFlagsCritical
                                                                          andVerifyLogGeneration:YES]] mutableCopy];

  // Create 2 normal logs.
  normalLogs = [[normalLogs arrayByAddingObjectsFromArray:[self generateAndSaveLogsWithCount:segmentLogCount
                                                                                     groupId:kMSTestGroupId
                                                                                       flags:MSFlagsNormal
                                                                      andVerifyLogGeneration:NO]] mutableCopy];

  // Create 2 critical logs.
  expectedLogs = [[expectedLogs arrayByAddingObjectsFromArray:[self generateAndSaveLogsWithCount:segmentLogCount
                                                                                         groupId:kMSTestGroupId
                                                                                           flags:MSFlagsCritical
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
  assertThatInteger([self.sut countEntriesForTable:kMSLogTableName condition:nil withValues:nil], equalToInteger(0));
  assertThatInteger(self.sut.batches.count, equalToInteger(0));

  // Test deletion with only the batch to delete.

  // If
  // Generate logs and create one batch by loading logs.
  [self generateAndSaveLogsWithCount:5 groupId:kMSTestGroupId flags:MSFlagsDefault andVerifyLogGeneration:YES];
  [self.sut loadLogsWithGroupId:kMSTestGroupId limit:2 excludedTargetKeys:nil completionHandler:nil];

  // When
  [self.sut deleteLogsWithGroupId:kMSTestGroupId];

  // Then
  assertThatInteger([self.sut countEntriesForTable:kMSLogTableName condition:nil withValues:nil], equalToInteger(0));
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
  assertThatInteger([self.sut countEntriesForTable:kMSLogTableName condition:nil withValues:nil], equalToInteger(0));
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
  NSArray *remainingLogs = [self loadLogsWhere:nil withValues:nil];
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
  NSArray *savedLogs = [self generateAndSaveLogsWithCount:5
                                                  groupId:kMSTestGroupId
                                                    flags:MSFlagsDefault
                                   andVerifyLogGeneration:YES];
  [self.sut loadLogsWithGroupId:kMSTestGroupId
                          limit:2
             excludedTargetKeys:nil
              completionHandler:^(NSArray<MSLog> *_Nonnull logArray, NSString *batchId) {
                batchIdToDelete = batchId;
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT (self IN %@)", logArray];
                expectedLogs = [savedLogs filteredArrayUsingPredicate:predicate];
              }];
  NSArray *logIdsToDelete = self.sut.batches[batchIdToDelete];
  MSStorageBindableArray *array = [MSStorageBindableArray new];
  for (NSNumber *item in logIdsToDelete) {
    [array addNumber:item];
  }

  // When
  [self.sut deleteLogsWithBatchId:batchIdToDelete groupId:kMSTestGroupId];

  // Then
  remainingLogs = [self loadLogsWhere:nil withValues:nil];
  NSString *keyFormat = [self.sut buildKeyFormatWithCount:logIdsToDelete.count];
  condition = [NSString stringWithFormat:@"%@ IN %@", kMSIdColumnName, keyFormat];
  assertThatInteger([self.sut countEntriesForTable:kMSLogTableName condition:condition withValues:array], equalToInteger(0));
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
  NSArray *savedLogs = [self generateAndSaveLogsWithCount:5
                                                  groupId:kMSTestGroupId
                                                    flags:MSFlagsDefault
                                   andVerifyLogGeneration:YES];
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
  MSStorageBindableArray *array = [MSStorageBindableArray new];
  for (NSNumber *item in logIdsToDelete) {
    [array addNumber:item];
  }

  // Trigger another batch.
  [self.sut loadLogsWithGroupId:kMSTestGroupId limit:2 excludedTargetKeys:nil completionHandler:nil];

  // When
  [self.sut deleteLogsWithBatchId:batchIdToDelete groupId:kMSTestGroupId];

  // Then
  remainingLogs = [self loadLogsWhere:nil withValues:nil];
  NSString *keyFormat = [self.sut buildKeyFormatWithCount:logIdsToDelete.count];
  condition = [NSString stringWithFormat:@"%@ IN %@", kMSIdColumnName, keyFormat];
  assertThatInteger([self.sut countEntriesForTable:kMSLogTableName condition:condition withValues:array], equalToInteger(0));
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
  NSArray *savedLogs = [self generateAndSaveLogsWithCount:5
                                                  groupId:kMSTestGroupId
                                                    flags:MSFlagsDefault
                                   andVerifyLogGeneration:YES];
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
  MSStorageBindableArray *array = [MSStorageBindableArray new];
  for (NSNumber *item in logIdsToDelete) {
    [array addNumber:item];
  }
  // Trigger another batch.
  [self.sut loadLogsWithGroupId:kMSAnotherTestGroupId limit:2 excludedTargetKeys:nil completionHandler:nil];

  // When
  [self.sut deleteLogsWithBatchId:batchIdToDelete groupId:kMSTestGroupId];

  // Then
  remainingLogs = [self loadLogsWhere:nil withValues:nil];
  NSString *keyFormat = [self.sut buildKeyFormatWithCount:logIdsToDelete.count];
  condition = [NSString stringWithFormat:@"%@ IN %@", kMSIdColumnName, keyFormat];
  assertThatInteger([self.sut countEntriesForTable:kMSLogTableName condition:condition withValues:array], equalToInteger(0));
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
  assertThatInteger([self.sut countEntriesForTable:kMSLogTableName condition:nil withValues:nil], equalToInteger(5));
}

- (void)testAddLogsWhenBelowStorageCapacity {

  // If
  long maxCapacityInBytes = kMSTestStorageSizeMinimumUpperLimitInBytes + 4 * 1024;
  long initialDataLengthInBytes = maxCapacityInBytes - 12 * 1024;
  MSAbstractLog *additionalLog = [MSAbstractLog new];
  additionalLog.sid = MS_UUID_STRING;
  NSArray *addedDbIds = [self fillDatabaseWithLogsOfSizeInBytes:initialDataLengthInBytes ofPriority:MSFlagsNormal];

  // When
  [self.sut setMaxStorageSize:maxCapacityInBytes
            completionHandler:^(__unused BOOL success){
            }];

  // Then
  BOOL logSavedSuccessfully = [self.sut saveLog:additionalLog withGroupId:kMSAnotherTestGroupId flags:MSFlagsDefault];

  // Then
  XCTAssertTrue(logSavedSuccessfully);
  NSString *whereCondition = [NSString stringWithFormat:@"\"%@\" = ?", kMSGroupIdColumnName];
  MSStorageBindableArray *values = [MSStorageBindableArray new];
  [values addString:kMSAnotherTestGroupId];
  NSArray<id<MSLog>> *loadedLogs = [self loadLogsWhere:whereCondition withValues:values];
  NSArray<id<MSLog>> *allLogs = [self loadLogsWhere:nil withValues:nil];
  XCTAssertEqual(loadedLogs.count, 1);
  XCTAssertEqualObjects(loadedLogs[0].sid, additionalLog.sid);
  XCTAssertEqual(addedDbIds.count + 1, allLogs.count);
}

- (void)testAddCriticalLog {

  // If
  MSAbstractLog *aLog = [MSAbstractLog new];
  aLog.sid = MS_UUID_STRING;
  NSString *criticalLogsFilter = [NSString stringWithFormat:@"\"%@\" = ?", kMSPriorityColumnName];
  NSString *normalLogsFilter = [NSString stringWithFormat:@"\"%@\" = ?", kMSPriorityColumnName];

  // When
  [self.sut saveLog:aLog withGroupId:kMSTestGroupId flags:MSFlagsCritical];

  // Then
  MSStorageBindableArray *values = [MSStorageBindableArray new];
  [values addNumber:@((unsigned int)MSFlagsCritical)];
  NSArray<id<MSLog>> *criticalLogs = [self loadLogsWhere:criticalLogsFilter withValues:values];

  values = [MSStorageBindableArray new];
  [values addNumber:@((unsigned int)MSFlagsNormal)];
  NSArray<id<MSLog>> *normalLogs = [self loadLogsWhere:normalLogsFilter withValues:values];
  XCTAssertEqual(criticalLogs.count, 1);
  XCTAssertEqualObjects(criticalLogs[0].sid, aLog.sid);
  XCTAssertEqual(normalLogs.count, 0);
}

- (void)testAddNormalLog {

  // If
  MSAbstractLog *aLog = [MSAbstractLog new];
  aLog.sid = MS_UUID_STRING;
  NSString *criticalLogsFilter = [NSString stringWithFormat:@"\"%@\" = ?", kMSPriorityColumnName];
  NSString *normalLogsFilter = [NSString stringWithFormat:@"\"%@\" = ?", kMSPriorityColumnName];

  // When
  [self.sut saveLog:aLog withGroupId:kMSTestGroupId flags:MSFlagsNormal];

  // Then
  MSStorageBindableArray *values = [MSStorageBindableArray new];
  [values addNumber:@((unsigned int)MSFlagsCritical)];
  NSArray<id<MSLog>> *criticalLogs = [self loadLogsWhere:criticalLogsFilter withValues:values];

  values = [MSStorageBindableArray new];
  [values addNumber:@((unsigned int)MSFlagsNormal)];
  NSArray<id<MSLog>> *normalLogs = [self loadLogsWhere:normalLogsFilter withValues:values];
  XCTAssertEqual(normalLogs.count, 1);
  XCTAssertEqualObjects(normalLogs[0].sid, aLog.sid);
  XCTAssertEqual(criticalLogs.count, 0);
}

- (void)testAddLogsDoesNotExceedCapacity {

  // If
  long maxCapacityInBytes = kMSTestStorageSizeMinimumUpperLimitInBytes;
  [self fillDatabaseWithLogsOfSizeInBytes:maxCapacityInBytes ofPriority:MSFlagsNormal];
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
  NSArray *addedDbIds = [self fillDatabaseWithLogsOfSizeInBytes:maxCapacityInBytes ofPriority:MSFlagsNormal];
  NSNumber *firstLogDbId = addedDbIds[0];

  // When
  [self.sut setMaxStorageSize:maxCapacityInBytes
            completionHandler:^(__unused BOOL success){
            }];
  MSAbstractLog *additionalLog = [MSAbstractLog new];
  BOOL logSavedSuccessfully = [self.sut saveLog:additionalLog withGroupId:kMSAnotherTestGroupId flags:MSFlagsNormal];

  // Then
  XCTAssertTrue([self.storageTestUtil getDataLengthInBytes] <= maxCapacityInBytes);
  XCTAssertTrue(logSavedSuccessfully);
  XCTAssertFalse([self containsLogWithDbId:firstLogDbId]);

  NSString *whereCondition = [NSString stringWithFormat:@"\"%@\" = ?", kMSGroupIdColumnName];
  MSStorageBindableArray *values = [MSStorageBindableArray new];
  [values addString:kMSAnotherTestGroupId];
  NSArray<id<MSLog>> *loadedLogs = [self loadLogsWhere:whereCondition withValues:values];
  XCTAssertEqual(loadedLogs.count, 1);
  XCTAssertEqualObjects(loadedLogs[0].sid, additionalLog.sid);
  XCTAssertEqual(1, [self findUnknownDBIdsFromKnownIdList:addedDbIds].count);
}

- (void)testSaveCriticalPriorityLogPurgesOldestNormalPriorityLogsWhenStorageFull {

  // If
  long maxCapacityInBytes = kMSTestStorageSizeMinimumUpperLimitInBytes + 4 * 1024;
  NSArray *addedDbIds = [self fillDatabaseWithLogsOfSizeInBytes:maxCapacityInBytes ofPriority:MSFlagsNormal];
  NSNumber *firstLogDbId = addedDbIds[0];

  // When
  [self.sut setMaxStorageSize:maxCapacityInBytes
            completionHandler:^(__unused BOOL success){
            }];
  MSAbstractLog *additionalLog = [MSAbstractLog new];
  BOOL logSavedSuccessfully = [self.sut saveLog:additionalLog withGroupId:kMSAnotherTestGroupId flags:MSFlagsCritical];

  // Then
  XCTAssertTrue([self.storageTestUtil getDataLengthInBytes] <= maxCapacityInBytes);
  XCTAssertTrue(logSavedSuccessfully);
  XCTAssertFalse([self containsLogWithDbId:firstLogDbId]);

  NSString *whereCondition = [NSString stringWithFormat:@"\"%@\" = ?", kMSGroupIdColumnName];
  MSStorageBindableArray *values = [MSStorageBindableArray new];
  [values addString:kMSAnotherTestGroupId];
  NSArray<id<MSLog>> *loadedLogs = [self loadLogsWhere:whereCondition withValues:values];
  XCTAssertEqual(loadedLogs.count, 1);
  XCTAssertEqualObjects(loadedLogs[0].sid, additionalLog.sid);
  XCTAssertEqual(1, [self findUnknownDBIdsFromKnownIdList:addedDbIds].count);
}

- (void)testSaveNormalPriorityLogDiscardsLogWhenStorageFullWithCriticalPriorityLogs {

  // If
  long maxCapacityInBytes = kMSTestStorageSizeMinimumUpperLimitInBytes + 4 * 1024;
  NSArray *addedDbIds = [self fillDatabaseWithLogsOfSizeInBytes:maxCapacityInBytes ofPriority:MSFlagsCritical];

  // When
  [self.sut setMaxStorageSize:maxCapacityInBytes
            completionHandler:^(__unused BOOL success){
            }];
  MSAbstractLog *additionalLog = [MSAbstractLog new];
  BOOL logSavedSuccessfully = [self.sut saveLog:additionalLog withGroupId:kMSAnotherTestGroupId flags:MSFlagsNormal];

  // Then
  XCTAssertTrue([self.storageTestUtil getDataLengthInBytes] <= maxCapacityInBytes);
  XCTAssertFalse(logSavedSuccessfully);
  for (NSNumber *dbId in addedDbIds) {
    XCTAssertTrue([self containsLogWithDbId:dbId]);
  }

  NSString *whereCondition = [NSString stringWithFormat:@"\"%@\" = ?", kMSGroupIdColumnName];
  MSStorageBindableArray *values = [MSStorageBindableArray new];
  [values addString:kMSAnotherTestGroupId];
  NSArray<id<MSLog>> *loadedLogs = [self loadLogsWhere:whereCondition withValues:values];
  XCTAssertEqual(loadedLogs.count, 0);
  XCTAssertEqual(0, [self findUnknownDBIdsFromKnownIdList:addedDbIds].count);
}

- (void)testSaveLogPurgesNormalPriorityLogWhenStorageFullWithMixedPriorityLogs {

  // If
  long maxCapacityInBytes = kMSTestStorageSizeMinimumUpperLimitInBytes + 4 * 1024;
  NSDictionary *addedDbIds = [self fillDatabaseWithMixedPriorityLogsOfSizeInBytesAndReturnDbIds:maxCapacityInBytes];
  NSNumber *oldestCriticalDbId = [((NSArray *)[addedDbIds objectForKey:[NSNumber numberWithInt:MSFlagsCritical]]) firstObject];
  NSNumber *oldestNormalDbId = [((NSArray *)[addedDbIds objectForKey:[NSNumber numberWithInt:MSFlagsNormal]]) firstObject];

  // When
  [self.sut setMaxStorageSize:maxCapacityInBytes
            completionHandler:^(__unused BOOL success){
            }];
  MSAbstractLog *additionalLog = [MSAbstractLog new];
  BOOL logSavedSuccessfully = [self.sut saveLog:additionalLog withGroupId:kMSAnotherTestGroupId flags:MSFlagsNormal];

  // Then
  XCTAssertTrue([self.storageTestUtil getDataLengthInBytes] <= maxCapacityInBytes);
  XCTAssertTrue(logSavedSuccessfully);
  XCTAssertFalse([self containsLogWithDbId:oldestNormalDbId]);
  XCTAssertTrue([self containsLogWithDbId:oldestCriticalDbId]);
  NSString *whereCondition = [NSString stringWithFormat:@"\"%@\" = ?", kMSGroupIdColumnName];
  MSStorageBindableArray *values = [MSStorageBindableArray new];
  [values addString:kMSAnotherTestGroupId];
  NSArray<id<MSLog>> *loadedLogs = [self loadLogsWhere:whereCondition withValues:values];
  XCTAssertEqual(loadedLogs.count, 1);
  XCTAssertEqualObjects(loadedLogs[0].sid, additionalLog.sid);
  NSArray *knownIds = [NSArray new];
  for (NSArray<NSNumber *> *ids in [addedDbIds allValues]) {
    knownIds = [knownIds arrayByAddingObjectsFromArray:ids];
  }
  XCTAssertEqual(1, [self findUnknownDBIdsFromKnownIdList:knownIds].count);
}

- (void)testSaveLargeNormalPriorityLogDoesNotPurgeOldLogs {
  [self DoNotPurgeOldLogsWhenSavingLargeLogExceedsCapacityWithPriority:MSFlagsNormal];
}

- (void)testSaveLargeCriticalPriorityLogDoesNotPurgeOldLogs {
  [self DoNotPurgeOldLogsWhenSavingLargeLogExceedsCapacityWithPriority:MSFlagsCritical];
}

- (void)DoNotPurgeOldLogsWhenSavingLargeLogExceedsCapacityWithPriority:(MSFlags)priority {

  // If
  long maxCapacityInBytes = kMSTestStorageSizeMinimumUpperLimitInBytes + 4 * 1024;
  [self.sut setMaxStorageSize:maxCapacityInBytes
            completionHandler:^(__unused BOOL success){
            }];
  [self generateAndSaveLogsWithCount:1 groupId:kMSTestGroupId flags:MSFlagsCritical andVerifyLogGeneration:YES];
  [self generateAndSaveLogsWithCount:2 groupId:kMSTestGroupId flags:MSFlagsNormal andVerifyLogGeneration:YES];
  id<MSLog> largeLog = [self generateLogWithSize:@(maxCapacityInBytes)];
  sqlite3 *db = [self.storageTestUtil openDatabase];
  NSArray<NSNumber *> *criticalDbIds = [self dbIdsForPriority:MSFlagsCritical inOpenedDatabase:db];
  NSArray<NSNumber *> *normalDbIds = [self dbIdsForPriority:MSFlagsNormal inOpenedDatabase:db];
  sqlite3_close(db);

  // When
  BOOL logSavedSuccessfully = [self.sut saveLog:largeLog withGroupId:kMSAnotherTestGroupId flags:priority];

  // Then
  XCTAssertTrue([self.storageTestUtil getDataLengthInBytes] <= maxCapacityInBytes);
  XCTAssertFalse(logSavedSuccessfully);
  NSString *whereCondition = [NSString stringWithFormat:@"\"%@\" = ?", kMSGroupIdColumnName];
  MSStorageBindableArray *values = [MSStorageBindableArray new];
  [values addString:kMSAnotherTestGroupId];
  NSArray<id<MSLog>> *loadedLogs = [self loadLogsWhere:whereCondition withValues:values];
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
  OCMStub([classMock executeNonSelectionQuery:startsWith(@"INSERT") inOpenedDatabase:[OCMArg anyPointer] withValues:OCMOCK_ANY])
      .andReturn(SQLITE_FULL);
  OCMStub([classMock executeNonSelectionQuery:startsWith(@"DELETE") inOpenedDatabase:[OCMArg anyPointer] withValues:OCMOCK_ANY])
      .andReturn(SQLITE_ERROR);

  // When
  MSAbstractLog *additionalLog = [MSAbstractLog new];
  BOOL logSavedSuccessfully = [self.sut saveLog:additionalLog withGroupId:kMSAnotherTestGroupId flags:MSFlagsDefault];

  // Then
  XCTAssertFalse(logSavedSuccessfully);
  [classMock stopMocking];
}

- (void)testCreateFromLatestSchema {

  // When
  [self.storageTestUtil deleteDatabase];
  self.sut = [MSLogDBStorage new];

  // Then
  NSString *currentTable =
      [self.sut executeSelectionQuery:[NSString stringWithFormat:@"SELECT sql FROM sqlite_master WHERE name='%@'", kMSLogTableName]
                           withValues:nil][0][0];
  assertThat(currentTable, is(kMSLatestSchema));
  NSString *priorityIndex =
      [self.sut executeSelectionQuery:[NSString stringWithFormat:@"SELECT sql FROM sqlite_master WHERE name='ix_%@_%@'", kMSLogTableName,
                                                                 kMSPriorityColumnName]
                           withValues:nil][0][0];
  assertThat(priorityIndex, is(@"CREATE INDEX \"ix_logs_priority\" ON \"logs\" (\"priority\")"));
}

- (void)testMigrationToLatest {

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
  MSDBStorage *storage0 = [[MSDBStorage alloc] initWithSchema:schema0 version:0 filename:kMSDBFileName];
  [self generateAndSaveLogsWithCount:10
                                size:nil
                             groupId:kMSTestGroupId
                               flags:MSFlagsDefault
                             storage:storage0
              andVerifyLogGeneration:YES];

  // When
  self.sut = [MSLogDBStorage new];

  // Then
  // Migration to version 5 we drop the table and re-create, so we expect 0.
  assertThatInt([self loadLogsWhere:nil withValues:nil].count, equalToUnsignedInt(0));
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
  return [self generateAndSaveLogsWithCount:count
                                       size:nil
                                    groupId:groupId
                                      flags:flags
                                    storage:self.sut
                     andVerifyLogGeneration:verify];
}

- (NSArray<id<MSLog>> *)generateAndSaveLogsWithCount:(NSUInteger)count
                                                size:(NSNumber *)size
                                             groupId:(NSString *)groupId
                                               flags:(MSFlags)flags
                              andVerifyLogGeneration:(BOOL)verify {
  return [self generateAndSaveLogsWithCount:count
                                       size:size
                                    groupId:groupId
                                      flags:flags
                                    storage:self.sut
                     andVerifyLogGeneration:verify];
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
    NSString *base64Data = [[MSUtility archiveKeyedData:log] base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    NSString *addLogQuery = [NSString stringWithFormat:@"INSERT INTO \"%@\" (\"%@\", \"%@\", \"%@\") VALUES (?, ?, ?)", kMSLogTableName,
                                                       kMSGroupIdColumnName, kMSLogColumnName, kMSPriorityColumnName];

    MSStorageBindableArray *values = [MSStorageBindableArray new];
    [values addString:groupId];
    [values addString:base64Data];
    [values addNumber:@((unsigned int)flags)];
    [storage executeNonSelectionQuery:addLogQuery withValues:values];
    [logs addObject:log];
  }

  if (verify) {

    // Check the insertion worked.
    MSStorageBindableArray *values = [MSStorageBindableArray new];
    [values addNumber:@((unsigned int)flags)];
    trueLogCount =
        [storage countEntriesForTable:kMSLogTableName
                            condition:[NSString stringWithFormat:@"\"%@\" = '%@' AND \"%@\" = ?", kMSGroupIdColumnName,
                                                                 groupId, kMSPriorityColumnName]
                           withValues:values];
    assertThatUnsignedInteger(trueLogCount, equalToUnsignedInteger(count));
  }
  return logs;
}

- (NSArray<NSNumber *> *)dbIdsForPriority:(MSFlags)flags inOpenedDatabase:(void *)db {
  NSString *selectLogQuery = [NSString stringWithFormat:@"SELECT \"%@\" FROM \"%@\" WHERE \"%@\" = ? ORDER BY \"%@\" ASC", kMSIdColumnName,
                                                        kMSLogTableName, kMSPriorityColumnName, kMSIdColumnName];
  MSStorageBindableArray *values = [MSStorageBindableArray new];
  [values addNumber:@((unsigned int)flags)];
  NSArray<NSArray *> *entries = [MSDBStorage executeSelectionQuery:selectLogQuery inOpenedDatabase:db withValues:values];
  NSMutableArray *ids = [NSMutableArray new];
  for (NSMutableArray *row in entries) {
    [ids addObject:row[0]];
  }
  return ids;
}

- (NSArray<id<MSLog>> *)loadLogsWhere:(nullable NSString *)whereCondition withValues:(nullable MSStorageBindableArray *)values {
  NSMutableArray<id<MSLog>> *logs = [NSMutableArray<id<MSLog>> new];
  NSMutableArray *rows = [NSMutableArray new];
  NSMutableString *selectLogQuery = [NSMutableString stringWithFormat:@"SELECT * FROM \"%@\"", kMSLogTableName];
  if (whereCondition.length > 0) {
    [selectLogQuery appendFormat:@" WHERE %@", whereCondition];
  }
  sqlite3 *db = [self.storageTestUtil openDatabase];
  sqlite3_stmt *statement = NULL;
  sqlite3_prepare_v2(db, [selectLogQuery UTF8String], -1, &statement, NULL);
  [values bindAllValuesWithStatement:statement inOpenedDatabase:db];

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
    id<MSLog> log = (id<MSLog>)[MSUtility unarchiveKeyedData:logData];
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
    NSString *base64Data = [[MSUtility archiveKeyedData:log] base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    NSString *addLogQuery = [NSString stringWithFormat:@"INSERT INTO \"%@\" (\"%@\", \"%@\", \"%@\") VALUES ('%@', '%@', %u)",
                                                       kMSLogTableName, kMSGroupIdColumnName, kMSLogColumnName, kMSPriorityColumnName,
                                                       kMSTestGroupId, base64Data, (unsigned int)priority];
    result = sqlite3_exec(db, [addLogQuery UTF8String], NULL, NULL, NULL);
  } while (result == SQLITE_OK);

  // Get DB IDs for logs
  NSString *selectLogQuery =
      [NSString stringWithFormat:@"SELECT \"%@\" FROM \"%@\" ORDER BY \"%@\" ASC", kMSIdColumnName, kMSLogTableName, kMSIdColumnName];
  NSArray<NSArray *> *entries = [MSDBStorage executeSelectionQuery:selectLogQuery inOpenedDatabase:db withValues:nil];
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
    NSString *base64Data = [[MSUtility archiveKeyedData:log] base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    NSString *addLogQuery =
        [NSString stringWithFormat:@"INSERT INTO \"%@\" (\"%@\", \"%@\", \"%@\") VALUES ('%@', '%@', %u)", kMSLogTableName,
                                   kMSGroupIdColumnName, kMSLogColumnName, kMSPriorityColumnName, kMSTestGroupId, base64Data,
                                   (unsigned int)(count++ % 2 == 0 ? MSFlagsCritical : MSFlagsNormal)];
    result = sqlite3_exec(db, [addLogQuery UTF8String], NULL, NULL, NULL);
  } while (result == SQLITE_OK);

  // Get DB IDs for logs
  NSMutableDictionary *ids = [NSMutableDictionary new];
  for (NSNumber *flag in @[ [NSNumber numberWithInt:MSFlagsNormal], [NSNumber numberWithInt:MSFlagsCritical] ]) {
    NSString *selectLogQuery = [NSString stringWithFormat:@"SELECT \"%@\" FROM \"%@\" WHERE \"%@\" = ? ORDER BY \"%@\" ASC",
                                                          kMSIdColumnName, kMSLogTableName, kMSPriorityColumnName, kMSIdColumnName];

    MSStorageBindableArray *values = [MSStorageBindableArray new];
    [values addNumber:@([flag unsignedIntValue])];
    NSArray<NSArray *> *entries = [MSDBStorage executeSelectionQuery:selectLogQuery inOpenedDatabase:db withValues:values];
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
  NSString *selectLogQuery = [NSString stringWithFormat:@"SELECT COUNT(*) FROM \"%@\" WHERE \"%@\" = ?", kMSLogTableName, kMSIdColumnName];
  MSStorageBindableArray *values = [MSStorageBindableArray new];
  [values addNumber:dbId];
  NSArray<NSArray<NSNumber *> *> *entries = [MSDBStorage executeSelectionQuery:selectLogQuery inOpenedDatabase:db withValues:values];
  if (entries.count > 0) {
    return entries[0][0].unsignedIntegerValue > 0;
  }
  return NO;
}

- (NSArray<NSNumber *> *)findUnknownDBIdsFromKnownIdList:(NSArray<NSNumber *> *)idList {
  sqlite3 *db = [self.storageTestUtil openDatabase];
  NSString *keyFormat = [self.sut buildKeyFormatWithCount:idList.count];
  NSString *selectLogQuery = [NSString
      stringWithFormat:@"SELECT \"%@\" FROM \"%@\" WHERE \"%@\" NOT IN %@", kMSIdColumnName, kMSLogTableName, kMSIdColumnName, keyFormat];

  MSStorageBindableArray *values = [MSStorageBindableArray new];

  for (NSNumber *item in idList) {
    [values addNumber:item];
  }
  NSArray<NSArray<NSNumber *> *> *entries = [MSDBStorage executeSelectionQuery:selectLogQuery inOpenedDatabase:db withValues:values];
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
