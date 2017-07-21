#import "MSAbstractLogInternal.h"
#import "MSFile.h"
#import "MSFileStorage.h"
#import "MSFileUtil.h"
#import "MSStorageTestUtil.h"
#import "MSTestFrameworks.h"

@interface MSFileStorageTests : XCTestCase

@property(nonatomic) MSFileStorage *sut;

@end

@implementation MSFileStorageTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
  self.sut = [MSFileStorage new];
}

- (void)tearDown {
  [super tearDown];
  [MSStorageTestUtil resetLogsDirectory];
}

#pragma mark - Tests

- (void)testNewInstanceWasInitialisedCorrectly {
  assertThat(self.sut, notNilValue());
}

- (void)testFileStorageUsesCorrectFilePath {

  // If
  NSString *groupId = @"TestGroupId";
  NSString *logsId = @"TestId";
  NSString *expected = [MSStorageTestUtil filePathForLogWithId:logsId extension:@"ms" groupId:groupId];

  // When
  NSURL *actual = [self.sut fileURLForGroupId:groupId logsId:logsId];

  // Then
  assertThat(actual, equalTo([NSURL fileURLWithPath:expected]));
}

- (void)testSavingFirstFileCreatesNewBucket {

  // If
  NSString *groupId = @"TestGroupId";
  id fileHelperMock = OCMClassMock([MSFileUtil class]);
  MSAbstractLog *log = [MSAbstractLog new];
  MSStorageBucket *bucket = self.sut.buckets[groupId];
  assertThat(bucket, nilValue());

  // When
  BOOL success = [self.sut saveLog:log withGroupId:groupId];

  // Verify
  MSStorageBucket *actualBucket = self.sut.buckets[groupId];
  MSFile *actualCurrentFile = actualBucket.currentFile;
  XCTAssertTrue(success);
  assertThat(actualCurrentFile, notNilValue());
  assertThat(actualBucket.currentLogs, hasItem(log));
  assertThat(actualCurrentFile.creationDate, notNilValue());
  assertThat(actualCurrentFile.fileId, notNilValue());
  OCMVerify([fileHelperMock writeData:[NSKeyedArchiver archivedDataWithRootObject:actualBucket.currentLogs]
                               toFile:actualCurrentFile]);
}

#if !TARGET_OS_TV
// FIXME: TV OS can only use temporary cache directory. All file access needs to be reimplemented.
- (void)testCreatingNewBucketsWillLoadExistingFiles {

  // If
  NSString *groupId = @"GroupId";
  MSAbstractLog *log = [MSAbstractLog new];
  MSFile *expected = [MSStorageTestUtil createFileWithId:@"test123"
                                                    data:[NSData new]
                                               extension:@"ms"
                                                 groupId:groupId
                                            creationDate:[NSDate date]];
  assertThat(self.sut.buckets[groupId], nilValue());

  // When
  BOOL success = [self.sut saveLog:log withGroupId:groupId];

  // Verify
  XCTAssertTrue(success);
  MSStorageBucket *bucket = self.sut.buckets[groupId];
  MSFile *actual = bucket.availableFiles.lastObject;
  assertThat(actual.fileURL, equalTo(expected.fileURL));
  assertThat(actual.fileId, equalTo(expected.fileId));

  // Sometimes we can get a difference between times in one second and it is a valid result.
  double maxAllowedDifference = 1;
  double difference = [actual.creationDate timeIntervalSinceDate:expected.creationDate];
  XCTAssertLessThanOrEqual(difference, maxAllowedDifference);
}
#endif

- (void)testSaveFirstLogOfABatchWillNotAddItToCurrentFileIfItIsNil {

  // If
  NSString *groupId = @"GroupId";
  MSAbstractLog *log = nil;
  MSStorageBucket *bucket = [self.sut bucketForGroupId:groupId];

  // When
  BOOL success = [self.sut saveLog:log withGroupId:groupId];

  // Verify
  XCTAssertFalse(success);
  assertThat(bucket.currentLogs, isEmpty());
}

#if !TARGET_OS_TV
// FIXME: TV OS can only use temporary cache directory. All file access needs to be reimplemented.
- (void)testSaveFirstLogOfABatchWillAddCurrentFileToAvailableList {

  // If
  NSString *groupId = @"GroupId";
  MSAbstractLog *log = [MSAbstractLog new];
  assertThat(self.sut.buckets[groupId], nilValue());

  // When
  BOOL success = [self.sut saveLog:log withGroupId:groupId];

  // Verify
  XCTAssertTrue(success);
  MSStorageBucket *bucket = self.sut.buckets[groupId];
  MSFile *expected = bucket.currentFile;
  MSFile *actual = bucket.availableFiles.lastObject;
  assertThat(actual, equalTo(expected));
  assertThat(bucket.availableFiles, hasCountOf(1));
}
#endif

- (void)testSaveFirstLogOfBatchWillDeleteOldestFileIfFileLimitHasBeenReached {

  // If
  NSString *groupId = @"GroupId";
  MSStorageBucket *bucket = [self.sut bucketForGroupId:groupId];

  MSFile *availableFile1 = [[MSFile alloc] initWithURL:[NSURL fileURLWithPath:@"1"]
                                                fileId:@"1"
                                          creationDate:[NSDate dateWithTimeIntervalSinceNow:1]];
  MSFile *availableFile2 = [[MSFile alloc] initWithURL:[NSURL fileURLWithPath:@"2"]
                                                fileId:@"2"
                                          creationDate:[NSDate dateWithTimeIntervalSinceNow:3]];
  MSFile *availableFile3 = [[MSFile alloc] initWithURL:[NSURL fileURLWithPath:@"3"]
                                                fileId:@"3"
                                          creationDate:[NSDate dateWithTimeIntervalSinceNow:5]];
  bucket.availableFiles = [@[ availableFile1, availableFile2, availableFile3 ] mutableCopy];
  self.sut.bucketFileCountLimit = bucket.availableFiles.count;
  MSAbstractLog *log = [MSAbstractLog new];

  // When
  BOOL success = [self.sut saveLog:log withGroupId:groupId];

  // Verify
  XCTAssertTrue(success);
  assertThatInteger(bucket.availableFiles.count, equalToInteger(3));
  assertThat(bucket.availableFiles, containsInRelativeOrder(@[ bucket.currentFile, availableFile1, availableFile2 ]));
}

- (void)testDeleteFileRemovesLogsIdFromBlockedFilesList {

  // If
  NSString *groupId = @"GroupId";
  NSString *batchId = @"12345";
  self.sut.buckets[groupId] = [MSStorageBucket new];
  MSStorageBucket *bucket = self.sut.buckets[groupId];
  MSFile *blockedFile =
      [[MSFile alloc] initWithURL:[NSURL fileURLWithPath:@"333"] fileId:batchId creationDate:[NSDate date]];
  bucket.blockedFiles = [NSMutableArray arrayWithObject:blockedFile];

  // When
  [self.sut deleteLogsForId:batchId withGroupId:groupId];

  // Verify
  assertThatInteger(self.sut.buckets[groupId].blockedFiles.count, equalToInteger(0));
}

- (void)testDeleteFileWillCallFileHelperMethod {

  // If
  id fileHelperMock = OCMClassMock([MSFileUtil class]);
  NSString *groupId = @"GroupId";
  NSString *batchId = @"12345";
  self.sut.buckets[groupId] = [MSStorageBucket new];
  MSStorageBucket *bucket = self.sut.buckets[groupId];
  MSFile *availableFile =
      [[MSFile alloc] initWithURL:[NSURL fileURLWithPath:@"333"] fileId:batchId creationDate:[NSDate date]];
  bucket.availableFiles = [@[ availableFile ] mutableCopy];

  // When
  [self.sut deleteLogsForId:batchId withGroupId:groupId];

  // Verify
  OCMVerify([fileHelperMock deleteFile:availableFile]);
}

- (void)testLoadBatchWillEmptyCurrentLogs {

  // If
  NSString *groupId = @"directory";
  MSAbstractLog *log = [MSAbstractLog new];
  BOOL success = [self.sut saveLog:log withGroupId:groupId];
  assertThatInteger(self.sut.buckets[groupId].currentLogs.count, equalToInteger(1));

  // When
  XCTAssertTrue(success);
  [self.sut loadLogsForGroupId:groupId withCompletion:nil];

  // Verify
  assertThat(self.sut.buckets[groupId].currentLogs, isEmpty());
}

- (void)testLoadBatchWillReturnOldestFileFirst {

  // If
  NSString *groupId = @"GroupId";
  self.sut.buckets[groupId] = [MSStorageBucket new];
  MSStorageBucket *bucket = self.sut.buckets[groupId];

  MSFile *availableFile1 = [[MSFile alloc] initWithURL:[NSURL fileURLWithPath:@"1"]
                                                fileId:@"1"
                                          creationDate:[NSDate dateWithTimeIntervalSinceNow:1]];
  MSFile *availableFile2 = [[MSFile alloc] initWithURL:[NSURL fileURLWithPath:@"2"]
                                                fileId:@"2"
                                          creationDate:[NSDate dateWithTimeIntervalSinceNow:3]];
  MSFile *availableFile3 = [[MSFile alloc] initWithURL:[NSURL fileURLWithPath:@"3"]
                                                fileId:@"3"
                                          creationDate:[NSDate dateWithTimeIntervalSinceNow:5]];
  bucket.availableFiles = [@[ availableFile1, availableFile2, availableFile3 ] mutableCopy];
  MSFile *currentFile =
      [[MSFile alloc] initWithURL:[NSURL fileURLWithPath:@"333"] fileId:@"333" creationDate:[NSDate date]];
  bucket.currentFile = currentFile;

  // When
  __block NSString *batchId;
  [self.sut loadLogsForGroupId:groupId
                withCompletion:^(__attribute__((unused)) BOOL succeeded,
                                 __attribute__((unused)) NSArray<NSObject<MSLog> *> *logs, NSString *logsId) {
                  batchId = logsId;
                }];

  // Verify
  assertThat(batchId, equalTo(availableFile3.fileId));
}

- (void)testLoadBatchWillAddItToBlockedFiles {

  // If
  NSString *groupId = @"GroupId";
  self.sut.buckets[groupId] = [MSStorageBucket new];
  MSStorageBucket *bucket = self.sut.buckets[groupId];

  MSFile *availableFile = [[MSFile alloc] initWithURL:[NSURL fileURLWithPath:@"1"]
                                               fileId:@"1"
                                         creationDate:[NSDate dateWithTimeIntervalSinceNow:1]];
  bucket.availableFiles = [NSMutableArray<MSFile *> arrayWithObject:availableFile];

  // When
  [self.sut loadLogsForGroupId:groupId
                withCompletion:^(__attribute__((unused)) BOOL succeeded,
                                 __attribute__((unused)) NSArray<NSObject<MSLog> *> *logs,
                                 __attribute__((unused)) NSString *logsId){
                }];

  // Verify
  assertThatInteger(bucket.availableFiles.count, equalToInteger(0));
  assertThatInteger(bucket.blockedFiles.count, equalToInteger(1));
  assertThat(bucket.blockedFiles, hasItem(availableFile));
}

- (void)testLoadBatchWillCreateNewCurrentFile {

  // If
  NSString *groupId = @"TestDirectory";
  self.sut.buckets[groupId] = [MSStorageBucket new];
  MSStorageBucket *bucket = self.sut.buckets[groupId];
  MSFile *currentFile =
      [[MSFile alloc] initWithURL:[NSURL fileURLWithPath:@"333"] fileId:@"333" creationDate:[NSDate date]];
  bucket.currentFile = currentFile;

  // When
  [self.sut loadLogsForGroupId:groupId
                withCompletion:^(__attribute__((unused)) BOOL succeeded,
                                 __attribute__((unused)) NSArray<NSObject<MSLog> *> *logs,
                                 __attribute__((unused)) NSString *logsId){
                }];

  // Verify
  assertThat(bucket.currentFile, isNot(equalTo(currentFile)));
}

@end
