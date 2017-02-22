#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSAbstractLog.h"
#import "MSFile.h"
#import "MSFileUtil.h"
#import "MSFileStorage.h"
#import "MSStorageTestUtil.h"

@interface MSFileStorageTests : XCTestCase

@property(nonatomic, strong) MSFileStorage *sut;

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
  assertThat(_sut, notNilValue());
}

- (void)testFileStorageUsesCorrectFilePath {

  // If
  NSString *storageKey = @"TestDirectory";
  NSString *logsId = @"TestId";
  NSString *expected = [MSStorageTestUtil filePathForLogWithId:logsId extension:@"ms" storageKey:storageKey];

  // When
  NSString *actual = [self.sut filePathForStorageKey:storageKey logsId:logsId];

  // Then
  assertThat(actual, equalTo(expected));
}

- (void)testSavingFirstFileCreatesNewBucket {

  // If
  NSString *storageKey = @"TestDirectory";
  id fileHelperMock = OCMClassMock([MSFileUtil class]);
  MSAbstractLog *log = [MSAbstractLog new];
  MSStorageBucket *bucket = self.sut.buckets[storageKey];
  assertThat(bucket, nilValue());

  // When
  BOOL success = [self.sut saveLog:log withStorageKey:storageKey];

  // Verify
  MSStorageBucket *actualBucket = self.sut.buckets[storageKey];
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
  NSString *storageKey = @"TestDirectory";
  MSAbstractLog *log = [MSAbstractLog new];
  MSFile *expected = [MSStorageTestUtil createFileWithId:@"test123"
                                                    data:[NSData new]
                                               extension:@"ms"
                                              storageKey:storageKey
                                            creationDate:[NSDate date]];
  assertThat(self.sut.buckets[storageKey], nilValue());

  // When
  BOOL success = [self.sut saveLog:log withStorageKey:storageKey];

  // Verify
  XCTAssertTrue(success);
  MSStorageBucket *bucket = self.sut.buckets[storageKey];
  MSFile *actual = bucket.availableFiles.lastObject;
  assertThat(actual.filePath, equalTo(expected.filePath));
  assertThat(actual.fileId, equalTo(expected.fileId));

  //Sometimes we can get a difference between times in one second
  //And it is a valid result
  double maxAllowedDifference = 1;
  double difference = [actual.creationDate timeIntervalSinceDate:expected.creationDate];
  XCTAssertLessThanOrEqual(difference, maxAllowedDifference);
}

- (void)testSaveFirstLogOfABatchWillNotAddItToCurrentFileIfItIsNil {

  // If
  NSString *storageKey = @"TestDirectory";
  MSAbstractLog *log = nil;
  MSStorageBucket *bucket = [self.sut bucketForStorageKey:storageKey];

  // When
  BOOL success = [self.sut saveLog:log withStorageKey:storageKey];

  // Verify
  XCTAssertFalse(success);
  assertThat(bucket.currentLogs, isEmpty());
}

- (void)testSaveFirstLogOfABatchWillAddCurrentFileToAvailableList {

  // If
  NSString *storageKey = @"TestDirectory";
  MSAbstractLog *log = [MSAbstractLog new];
  assertThat(self.sut.buckets[storageKey], nilValue());

  // When
  BOOL success = [self.sut saveLog:log withStorageKey:storageKey];

  // Verify
  XCTAssertTrue(success);
  MSStorageBucket *bucket = self.sut.buckets[storageKey];
  MSFile *expected = bucket.currentFile;
  MSFile *actual = bucket.availableFiles.lastObject;
  assertThat(actual, equalTo(expected));
  assertThat(bucket.availableFiles, hasCountOf(1));
}

- (void)testSaveFirstLogOfBatchWillDeleteOldestFileIfFileLimitHasBeenReached {

  // If
  NSString *storageKey = @"TestDirectory";
  MSStorageBucket *bucket = [self.sut bucketForStorageKey:storageKey];

  MSFile *availableFile1 =
      [[MSFile alloc] initWithPath:@"1" fileId:@"1" creationDate:[NSDate dateWithTimeIntervalSinceNow:1]];
  MSFile *availableFile2 =
      [[MSFile alloc] initWithPath:@"2" fileId:@"2" creationDate:[NSDate dateWithTimeIntervalSinceNow:3]];
  MSFile *availableFile3 =
      [[MSFile alloc] initWithPath:@"3" fileId:@"3" creationDate:[NSDate dateWithTimeIntervalSinceNow:5]];
  bucket.availableFiles =
      [NSMutableArray<MSFile *> arrayWithObjects:availableFile1, availableFile2, availableFile3, nil];
  self.sut.bucketFileCountLimit = bucket.availableFiles.count;
  MSAbstractLog *log = [MSAbstractLog new];

  // When
  BOOL success = [self.sut saveLog:log withStorageKey:storageKey];

  // Verify
  XCTAssertTrue(success);
  assertThatInteger(bucket.availableFiles.count, equalToInteger(3));
  assertThat(bucket.availableFiles, containsInRelativeOrder(@[ bucket.currentFile, availableFile1, availableFile2 ]));
}

- (void)testDeleteFileRemovesLogsIdFromBlockedFilesList {

  // If
  NSString *storageKey = @"TestDirectory";
  NSString *batchId = @"12345";
  self.sut.buckets[storageKey] = [MSStorageBucket new];
  MSStorageBucket *bucket = self.sut.buckets[storageKey];
  MSFile *blockedFile = [[MSFile alloc] initWithPath:@"333" fileId:batchId creationDate:[NSDate date]];
  bucket.blockedFiles = [NSMutableArray arrayWithObject:blockedFile];

  // When
  [self.sut deleteLogsForId:batchId withStorageKey:storageKey];

  // Verify
  assertThatInteger(self.sut.buckets[storageKey].blockedFiles.count, equalToInteger(0));
}

- (void)testDeleteFileWillCallFileHelperMethod {

  // If
  id fileHelperMock = OCMClassMock([MSFileUtil class]);
  NSString *storageKey = @"TestDirectory";
  NSString *batchId = @"12345";
  self.sut.buckets[storageKey] = [MSStorageBucket new];
  MSStorageBucket *bucket = self.sut.buckets[storageKey];
  MSFile *availableFile = [[MSFile alloc] initWithPath:@"333" fileId:batchId creationDate:[NSDate date]];
  bucket.availableFiles = [NSMutableArray arrayWithObject:availableFile];

  // When
  [self.sut deleteLogsForId:batchId withStorageKey:storageKey];

  // Verify
  OCMVerify([fileHelperMock deleteFile:availableFile]);
}

- (void)testLoadBatchWillEmptyCurrentLogs {

  // If
  NSString *storageKey = @"directory";
  MSAbstractLog *log = [MSAbstractLog new];
  BOOL success = [self.sut saveLog:log withStorageKey:storageKey];
  assertThatInteger(self.sut.buckets[storageKey].currentLogs.count, equalToInteger(1));

  // When
  XCTAssertTrue(success);
  [self.sut loadLogsForStorageKey:storageKey withCompletion:nil];

  // Verify
  assertThat(self.sut.buckets[storageKey].currentLogs, isEmpty());
}

- (void)testLoadBatchWillReturnOldestFileFirst {

  // If
  NSString *storageKey = @"TestDirectory";
  self.sut.buckets[storageKey] = [MSStorageBucket new];
  MSStorageBucket *bucket = self.sut.buckets[storageKey];

  MSFile *availableFile1 =
      [[MSFile alloc] initWithPath:@"1" fileId:@"1" creationDate:[NSDate dateWithTimeIntervalSinceNow:1]];
  MSFile *availableFile2 =
      [[MSFile alloc] initWithPath:@"2" fileId:@"2" creationDate:[NSDate dateWithTimeIntervalSinceNow:3]];
  MSFile *availableFile3 =
      [[MSFile alloc] initWithPath:@"3" fileId:@"3" creationDate:[NSDate dateWithTimeIntervalSinceNow:5]];
  bucket.availableFiles =
      [NSMutableArray<MSFile *> arrayWithObjects:availableFile1, availableFile2, availableFile3, nil];
  MSFile *currentFile = [[MSFile alloc] initWithPath:@"333" fileId:@"333" creationDate:[NSDate date]];
  bucket.currentFile = currentFile;

  // When
  __block NSString *batchId;
  [self.sut loadLogsForStorageKey:storageKey
                   withCompletion:^(BOOL succeeded, NSArray<NSObject<MSLog> *> *logs, NSString *logsId) {
                     batchId = logsId;
                   }];

  // Verify
  assertThat(batchId, equalTo(availableFile3.fileId));
}

- (void)testLoadBatchWillAddItToBlockedFiles {

  // If
  NSString *storageKey = @"TestDirectory";
  self.sut.buckets[storageKey] = [MSStorageBucket new];
  MSStorageBucket *bucket = self.sut.buckets[storageKey];

  MSFile *availableFile =
      [[MSFile alloc] initWithPath:@"1" fileId:@"1" creationDate:[NSDate dateWithTimeIntervalSinceNow:1]];
  bucket.availableFiles = [NSMutableArray<MSFile *> arrayWithObject:availableFile];

  // When
  [self.sut loadLogsForStorageKey:storageKey
                   withCompletion:^(BOOL succeeded, NSArray<NSObject<MSLog> *> *logs, NSString *logsId){
                   }];

  // Verify
  assertThatInteger(bucket.availableFiles.count, equalToInteger(0));
  assertThatInteger(bucket.blockedFiles.count, equalToInteger(1));
  assertThat(bucket.blockedFiles, hasItem(availableFile));
}

- (void)testLoadBatchWillCreateNewCurrentFile {

  // If
  NSString *storageKey = @"TestDirectory";
  self.sut.buckets[storageKey] = [MSStorageBucket new];
  MSStorageBucket *bucket = self.sut.buckets[storageKey];
  MSFile *currentFile = [[MSFile alloc] initWithPath:@"333" fileId:@"333" creationDate:[NSDate date]];
  bucket.currentFile = currentFile;

  // When
  [self.sut loadLogsForStorageKey:storageKey
                   withCompletion:^(BOOL succeeded, NSArray<NSObject<MSLog> *> *logs, NSString *logsId){
                   }];

  // Verify
  assertThat(bucket.currentFile, isNot(equalTo(currentFile)));
}

@end
