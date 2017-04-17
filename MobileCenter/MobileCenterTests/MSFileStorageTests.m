#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSAbstractLogInternal.h"
#import "MSFile.h"
#import "MSFileStorage.h"
#import "MSFileUtil.h"
#import "MSStorageTestUtil.h"

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
  NSString *groupID = @"TestGroupID";
  NSString *logsId = @"TestId";
  NSString *expected = [MSStorageTestUtil filePathForLogWithId:logsId extension:@"ms" groupID:groupID];

  // When
  NSURL *actual = [self.sut fileURLForGroupID:groupID logsId:logsId];

  // Then
  assertThat(actual, equalTo([NSURL fileURLWithPath:expected]));
}

- (void)testSavingFirstFileCreatesNewBucket {

  // If
  NSString *groupID = @"TestGroupID";
  id fileHelperMock = OCMClassMock([MSFileUtil class]);
  MSAbstractLog *log = [MSAbstractLog new];
  MSStorageBucket *bucket = self.sut.buckets[groupID];
  assertThat(bucket, nilValue());

  // When
  BOOL success = [self.sut saveLog:log withGroupID:groupID];

  // Verify
  MSStorageBucket *actualBucket = self.sut.buckets[groupID];
  MSFile *actualCurrentFile = actualBucket.currentFile;
  XCTAssertTrue(success);
  assertThat(actualCurrentFile, notNilValue());
  assertThat(actualBucket.currentLogs, hasItem(log));
  assertThat(actualCurrentFile.creationDate, notNilValue());
  assertThat(actualCurrentFile.fileId, notNilValue());
  OCMVerify([fileHelperMock writeData:[NSKeyedArchiver archivedDataWithRootObject:actualBucket.currentLogs]
                               toFile:actualCurrentFile]);
}

- (void)testCreatingNewBucketsWillLoadExistingFiles {

  // If
  NSString *groupID = @"GroupID";
  MSAbstractLog *log = [MSAbstractLog new];
  MSFile *expected = [MSStorageTestUtil createFileWithId:@"test123"
                                                    data:[NSData new]
                                               extension:@"ms"
                                                 groupID:groupID
                                            creationDate:[NSDate date]];
  assertThat(self.sut.buckets[groupID], nilValue());

  // When
  BOOL success = [self.sut saveLog:log withGroupID:groupID];

  // Verify
  XCTAssertTrue(success);
  MSStorageBucket *bucket = self.sut.buckets[groupID];
  MSFile *actual = bucket.availableFiles.lastObject;
  assertThat(actual.fileURL, equalTo(expected.fileURL));
  assertThat(actual.fileId, equalTo(expected.fileId));

  // Sometimes we can get a difference between times in one second and it is a valid result.
  double maxAllowedDifference = 1;
  double difference = [actual.creationDate timeIntervalSinceDate:expected.creationDate];
  XCTAssertLessThanOrEqual(difference, maxAllowedDifference);
}

- (void)testSaveFirstLogOfABatchWillNotAddItToCurrentFileIfItIsNil {

  // If
  NSString *groupID = @"GroupID";
  MSAbstractLog *log = nil;
  MSStorageBucket *bucket = [self.sut bucketForGroupID:groupID];

  // When
  BOOL success = [self.sut saveLog:log withGroupID:groupID];

  // Verify
  XCTAssertFalse(success);
  assertThat(bucket.currentLogs, isEmpty());
}

- (void)testSaveFirstLogOfABatchWillAddCurrentFileToAvailableList {

  // If
  NSString *groupID = @"GroupID";
  MSAbstractLog *log = [MSAbstractLog new];
  assertThat(self.sut.buckets[groupID], nilValue());

  // When
  BOOL success = [self.sut saveLog:log withGroupID:groupID];

  // Verify
  XCTAssertTrue(success);
  MSStorageBucket *bucket = self.sut.buckets[groupID];
  MSFile *expected = bucket.currentFile;
  MSFile *actual = bucket.availableFiles.lastObject;
  assertThat(actual, equalTo(expected));
  assertThat(bucket.availableFiles, hasCountOf(1));
}

- (void)testSaveFirstLogOfBatchWillDeleteOldestFileIfFileLimitHasBeenReached {

  // If
  NSString *groupID = @"GroupID";
  MSStorageBucket *bucket = [self.sut bucketForGroupID:groupID];

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
  BOOL success = [self.sut saveLog:log withGroupID:groupID];

  // Verify
  XCTAssertTrue(success);
  assertThatInteger(bucket.availableFiles.count, equalToInteger(3));
  assertThat(bucket.availableFiles, containsInRelativeOrder(@[ bucket.currentFile, availableFile1, availableFile2 ]));
}

- (void)testDeleteFileRemovesLogsIdFromBlockedFilesList {

  // If
  NSString *groupID = @"GroupID";
  NSString *batchId = @"12345";
  self.sut.buckets[groupID] = [MSStorageBucket new];
  MSStorageBucket *bucket = self.sut.buckets[groupID];
  MSFile *blockedFile =
      [[MSFile alloc] initWithURL:[NSURL fileURLWithPath:@"333"] fileId:batchId creationDate:[NSDate date]];
  bucket.blockedFiles = [NSMutableArray arrayWithObject:blockedFile];

  // When
  [self.sut deleteLogsForId:batchId withGroupID:groupID];

  // Verify
  assertThatInteger(self.sut.buckets[groupID].blockedFiles.count, equalToInteger(0));
}

- (void)testDeleteFileWillCallFileHelperMethod {

  // If
  id fileHelperMock = OCMClassMock([MSFileUtil class]);
  NSString *groupID = @"GroupID";
  NSString *batchId = @"12345";
  self.sut.buckets[groupID] = [MSStorageBucket new];
  MSStorageBucket *bucket = self.sut.buckets[groupID];
  MSFile *availableFile =
      [[MSFile alloc] initWithURL:[NSURL fileURLWithPath:@"333"] fileId:batchId creationDate:[NSDate date]];
  bucket.availableFiles = [@[ availableFile ] mutableCopy];

  // When
  [self.sut deleteLogsForId:batchId withGroupID:groupID];

  // Verify
  OCMVerify([fileHelperMock deleteFile:availableFile]);
}

- (void)testLoadBatchWillEmptyCurrentLogs {

  // If
  NSString *groupID = @"directory";
  MSAbstractLog *log = [MSAbstractLog new];
  BOOL success = [self.sut saveLog:log withGroupID:groupID];
  assertThatInteger(self.sut.buckets[groupID].currentLogs.count, equalToInteger(1));

  // When
  XCTAssertTrue(success);
  [self.sut loadLogsForGroupID:groupID withCompletion:nil];

  // Verify
  assertThat(self.sut.buckets[groupID].currentLogs, isEmpty());
}

- (void)testLoadBatchWillReturnOldestFileFirst {

  // If
  NSString *groupID = @"GroupID";
  self.sut.buckets[groupID] = [MSStorageBucket new];
  MSStorageBucket *bucket = self.sut.buckets[groupID];

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
  [self.sut loadLogsForGroupID:groupID
                withCompletion:^(__attribute__((unused)) BOOL succeeded,
                                 __attribute__((unused)) NSArray<NSObject<MSLog> *> *logs, NSString *logsId) {
                  batchId = logsId;
                }];

  // Verify
  assertThat(batchId, equalTo(availableFile3.fileId));
}

- (void)testLoadBatchWillAddItToBlockedFiles {

  // If
  NSString *groupID = @"GroupID";
  self.sut.buckets[groupID] = [MSStorageBucket new];
  MSStorageBucket *bucket = self.sut.buckets[groupID];

  MSFile *availableFile = [[MSFile alloc] initWithURL:[NSURL fileURLWithPath:@"1"]
                                               fileId:@"1"
                                         creationDate:[NSDate dateWithTimeIntervalSinceNow:1]];
  bucket.availableFiles = [NSMutableArray<MSFile *> arrayWithObject:availableFile];

  // When
  [self.sut loadLogsForGroupID:groupID
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
  NSString *groupID = @"TestDirectory";
  self.sut.buckets[groupID] = [MSStorageBucket new];
  MSStorageBucket *bucket = self.sut.buckets[groupID];
  MSFile *currentFile =
      [[MSFile alloc] initWithURL:[NSURL fileURLWithPath:@"333"] fileId:@"333" creationDate:[NSDate date]];
  bucket.currentFile = currentFile;

  // When
  [self.sut loadLogsForGroupID:groupID
                withCompletion:^(__attribute__((unused)) BOOL succeeded,
                                 __attribute__((unused)) NSArray<NSObject<MSLog> *> *logs,
                                 __attribute__((unused)) NSString *logsId){
                }];

  // Verify
  assertThat(bucket.currentFile, isNot(equalTo(currentFile)));
}

@end
