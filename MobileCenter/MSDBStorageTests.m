#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSAbstractLogInternal.h"
#import "MSDBStoragePrivate.h"
#import "MSDatabaseConnection.h"
#import "MSUtility.h"
#import "MSUtility+Date.h"

static NSString *const kMSTestGroupId = @"TestGroupId";
static short const kMSTestMaxCapacity = 50;
static NSString *const kMSAnotherTestGroupId = @"AnotherGroupId";

@interface MSDBStorageTests : XCTestCase

@property(nonatomic) MSDBStorage *sut;
@property(nonatomic) id<MSDatabaseConnection> dbConnectionMock;

@end

@implementation MSDBStorageTests

#pragma mark - Setup
- (void)setUp {
  [super setUp];
  self.sut = [[MSDBStorage alloc] initWithCapacity:kMSTestMaxCapacity];
  self.dbConnectionMock = OCMProtocolMock(@protocol(MSDatabaseConnection));
  self.sut.connection = self.dbConnectionMock;
}

- (void)testLoadTooManyLogs {

  // If
  NSUInteger expectedLogsCount = 5;
  OCMStub([self.dbConnectionMock selectDataFromDB:[OCMArg any]])
      .andReturn([self generateSerializedLogsWithCount:expectedLogsCount + 1]);

  // When
  BOOL moreLogsAvailable =
      [self.sut loadLogsWithGroupId:kMSTestGroupId
                              limit:expectedLogsCount
                     withCompletion:^(NSArray<id<MSLog>> *_Nonnull logArray, NSString *_Nonnull batchId) {

                       // Then
                       assertThat(batchId, notNilValue());
                       XCTAssertTrue(expectedLogsCount == logArray.count);
                     }];
  XCTAssertTrue(moreLogsAvailable);
}

- (void)testLoadJustEnoughLogs {

  // If
  NSUInteger expectedLogsCount = 5;
  OCMStub([self.dbConnectionMock selectDataFromDB:[OCMArg any]])
      .andReturn([self generateSerializedLogsWithCount:expectedLogsCount]);

  // When
  BOOL moreLogsAvailable =
      [self.sut loadLogsWithGroupId:kMSTestGroupId
                              limit:expectedLogsCount
                     withCompletion:^(NSArray<id<MSLog>> *_Nonnull logArray, NSString *_Nonnull batchId) {

                       // Then
                       assertThat(batchId, notNilValue());
                       XCTAssertTrue(expectedLogsCount == logArray.count);
                     }];
  XCTAssertFalse(moreLogsAvailable);
}

- (void)testLoadNotEnoughLogs {

  // If
  NSUInteger expectedLogsCount = 2;
  NSUInteger limit = 5;
  OCMStub([self.dbConnectionMock selectDataFromDB:[OCMArg any]])
      .andReturn([self generateSerializedLogsWithCount:expectedLogsCount]);

  // When
  BOOL moreLogsAvailable =
      [self.sut loadLogsWithGroupId:kMSTestGroupId
                              limit:limit
                     withCompletion:^(NSArray<id<MSLog>> *_Nonnull logArray, NSString *_Nonnull batchId) {

                       // Then
                       assertThat(batchId, notNilValue());
                       XCTAssertTrue(expectedLogsCount == logArray.count);
                     }];
  XCTAssertFalse(moreLogsAvailable);
}

- (void)testLoadUnlimitedLogs {

  // If
  NSUInteger expectedLogsCount = 42;
  OCMStub([self.dbConnectionMock selectDataFromDB:[OCMArg any]])
      .andReturn([self generateSerializedLogsWithCount:expectedLogsCount]);

  // When
  NSDictionary<NSString *, id<MSLog>> *logs = [self.sut getLogsFromDBWithGroupId:kMSTestGroupId];

  // Then
  XCTAssertTrue(expectedLogsCount == logs.count);
}

- (void)testDeleteLogsWithGroupId {

  // Test deletion with no batch.

  /*
   * If
   */
  NSString *expectedQuery = [NSString
      stringWithFormat:@"DELETE FROM %@ WHERE %@ IN ('%@')", kMSLogTableName, kMSGroupIdColumnName, kMSTestGroupId];

  /*
   * When
   */
  [self.sut deleteLogsWithGroupId:kMSTestGroupId];

  /*
   * Then
   */
  OCMVerify([self.dbConnectionMock executeQuery:expectedQuery]);

  // Test deletion with only the batch to delete.

  /*
   * If
   */
  NSString *selectLogQuery =
  [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ == '%@' AND %@ IN ('%@') ''", kMSLogTableName,
   kMSGroupIdColumnName, kMSTestGroupId, kMSBatchIdColumnName, @"27','35"];
  
  /*
   * When
   */
  [self.sut deleteLogsWithBatchId:@"27"];
  [self.sut deleteLogsWithBatchId:@"35"];

  /*
   * Then
   */
  OCMVerify([self.dbConnectionMock executeQuery:expectedQuery]);
  
  int logCount = [self.dbConnectionMock  executeQuery:selectLogQuery];
  assertThatInteger(logCount, equalToInteger(0));

  // Test deletion with more than one batch to delete.

  /*
   * When
   */
  [self.sut deleteLogsWithGroupId:kMSTestGroupId];

  /*
   * Then
   */
  OCMVerify([self.dbConnectionMock executeQuery:expectedQuery]);

  // Test deletion with the batch to delete and batches from other groups.

  /*
   * When
   */
  [self.sut deleteLogsWithGroupId:kMSTestGroupId];

  /*
   * Then
   */
  OCMVerify([self.dbConnectionMock executeQuery:expectedQuery]);
}

- (void)testDeleteLogsWithBatchId {

  // Test deletion with only the batch to delete.

  /*
   * If
   */
  NSString *batchToDelete = MS_UUID_STRING;
  NSString *expectedQuery = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ IN ('%@')", kMSLogTableName,
                                                       kMSBatchIdColumnName, batchToDelete];

  /*
   * When
   */
  [self.sut deleteLogsWithBatchId:batchToDelete];

  /*
   * Then
   */
  OCMVerify([self.dbConnectionMock executeQuery:expectedQuery]);

  // Test deletion with more than one batch to delete.

  /*
   * When
   */
  [self.sut deleteLogsWithBatchId:batchToDelete];

  /*
   * Then
   */
  OCMVerify([self.dbConnectionMock executeQuery:expectedQuery]);

  // Test deletion with more than one batch to delete.

  /*
   * When
   */
  [self.sut deleteLogsWithBatchId:batchToDelete];

  /*
   * Then
   */
  OCMVerify([self.dbConnectionMock executeQuery:expectedQuery]);
}

- (void)testStorageCapacity {

  /**
   * If
   */
  
  // Test just below the limit.
  short expectedCapacity = 3;
  __block BOOL deletionHappened = NO;
  __block int overflowCount = 0;
  __block int logCount = 2;
  self.sut = [[MSDBStorage alloc] initWithCapacity:expectedCapacity];
  self.sut.connection = self.dbConnectionMock;
  NSString *deleteQuery = [NSString
      stringWithFormat:@"DELETE FROM %@ WHERE groupId = '%@' ORDER BY id ASC LIMIT", kMSLogTableName, kMSTestGroupId];
  
  // Capture the overflow count and the query.
  OCMStub([self.dbConnectionMock executeQuery:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    NSString *query;
    BOOL returnValue = YES;
    [invocation retainArguments];
    [invocation getArgument:&query atIndex:2];
    if ([query hasPrefix:deleteQuery]) {
      overflowCount = [[query stringByReplacingOccurrencesOfString:deleteQuery withString:@""] intValue];
      deletionHappened = YES;
    }
    [invocation setReturnValue:&returnValue];
  });
  
  // Setup variable log count.
  OCMStub([self.dbConnectionMock selectDataFromDB:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    NSArray<NSArray<NSString *> *> * returnValue = @[@[[@(logCount) stringValue]]];
    [invocation retainArguments];
    [invocation setReturnValue:&returnValue];
  });

  /**
   * When
   */
  [self.sut saveLog:[MSAbstractLog new] withGroupId:kMSTestGroupId];

  /**
   * Then
   */
  assertThatBool(deletionHappened, isFalse());
  
  // Test at the limit.

  /**
   * If
   */
  expectedCapacity = 2;
  self.sut = [[MSDBStorage alloc] initWithCapacity:expectedCapacity];
  self.sut.connection = self.dbConnectionMock;

  /**
   * When
   */
  [self.sut saveLog:[MSAbstractLog new] withGroupId:kMSTestGroupId];

  /**
   * Then
   */
  assertThatBool(deletionHappened, isFalse());
  
  // Test just over the limit.

  /**
   * If
   */
  expectedCapacity = 1;
  self.sut = [[MSDBStorage alloc] initWithCapacity:expectedCapacity];
  self.sut.connection = self.dbConnectionMock;

  /**
   * When
   */
  [self.sut saveLog:[MSAbstractLog new] withGroupId:kMSTestGroupId];

  /**
   * Then
   */
  assertThatBool(deletionHappened, isTrue());
  assertThatInt(overflowCount, equalToInt(1));
  
  // Test way over the limit.
  
  /**
   * If
   */
  logCount = 10;
  expectedCapacity = 1;
  self.sut = [[MSDBStorage alloc] initWithCapacity:expectedCapacity];
  self.sut.connection = self.dbConnectionMock;
  
  /**
   * When
   */
  [self.sut saveLog:[MSAbstractLog new] withGroupId:kMSTestGroupId];
  
  /**
   * Then
   */
  assertThatBool(deletionHappened, isTrue());
  assertThatInt(overflowCount, equalToInt(9));
}

- (NSArray<NSArray<NSString *> *> *)generateSerializedLogsWithCount:(NSUInteger)count {
  NSMutableArray<NSArray<NSString *> *> *logs = [NSMutableArray arrayWithCapacity:count];
  for (NSUInteger i = 0; i < count; ++i) {
    NSData *logData = [NSKeyedArchiver archivedDataWithRootObject:[MSAbstractLog new]];
    NSString *base64Data = [logData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    [logs addObject:@[ [@(i) stringValue], kMSTestGroupId, base64Data ]];
  }
  return logs;
}

@end
