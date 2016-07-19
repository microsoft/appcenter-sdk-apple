#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "AVAAbstractLog.h"
#import "AVAFile.h"
#import "AVAFileHelper.h"
#import "AVAFileStorage.h"
#import "AVAStorageTestHelper.h"

@interface AVAFileStorageTests : XCTestCase

@property(nonatomic, strong) AVAFileStorage *sut;

@end

@implementation AVAFileStorageTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
  self.sut = [AVAFileStorage new];
}

- (void)tearDown {
  [super tearDown];
  [AVAStorageTestHelper resetLogsDirectory];
}

#pragma mark - Tests

- (void)testNewInstanceWasInitialisedCorrectly {
  assertThat(_sut, notNilValue());
}

- (void)testFileStorageUsesCorrectFilePath {

  // If
  NSString *storageKey = @"TestDirectory";
  NSString *logsId = @"TestId";
  NSString *expected = [AVAStorageTestHelper filePathForLogWithId:logsId
                                                        extension:@"ava"
                                                       storageKey:storageKey];

  // When
  NSString *actual = [self.sut filePathForStorageKey:storageKey logsId:logsId];

  // Then
  assertThat(actual, equalTo(expected));
}

- (void)testSavingFirstFileCreatesNewBucket {

  // If
  NSString *storageKey = @"TestDirectory";
  id fileHelperMock = OCMClassMock([AVAFileHelper class]);
  AVAAbstractLog *log = [AVAAbstractLog new];
  AVAStorageBucket *bucket = self.sut.buckets[storageKey];
  assertThat(bucket, nilValue());

  // When
  [self.sut saveLog:log withStorageKey:storageKey];

  // Verify
  AVAStorageBucket *actualBucket = self.sut.buckets[storageKey];
  AVAFile *actualCurrentFile = actualBucket.currentFile;
  assertThat(actualCurrentFile, notNilValue());
  assertThat(actualBucket.currentLogs, hasItem(log));
  assertThat(actualCurrentFile.creationDate, notNilValue());
  assertThat(actualCurrentFile.fileId, notNilValue());
  OCMVerify([fileHelperMock
      writeData:[NSKeyedArchiver
                    archivedDataWithRootObject:actualBucket.currentLogs]
         toFile:actualCurrentFile]);
}

- (void)testCreatingNewBucketsWillLoadExistingFiles {

  // If
  NSString *storageKey = @"TestDirectory";
  AVAAbstractLog *log = [AVAAbstractLog new];
  AVAFile *expected = [AVAStorageTestHelper createFileWithId:@"test123"
                                                        data:[NSData new]
                                                   extension:@"ava"
                                                  storageKey:storageKey
                                                creationDate:[NSDate date]];
  assertThat(self.sut.buckets[storageKey], nilValue());

  // When
  [self.sut saveLog:log withStorageKey:storageKey];

  // Verify
  AVAStorageBucket *bucket = self.sut.buckets[storageKey];
  AVAFile *actual = bucket.availableFiles[0];
  assertThatInteger(bucket.availableFiles.count, equalToInteger(1));
  assertThat(actual.filePath, equalTo(expected.filePath));
  assertThat(actual.fileId, equalTo(expected.fileId));
  assertThat(actual.creationDate.description,
             equalTo(expected.creationDate.description));
}

- (void)testLoadBatchWillEmptyCurrentLogs {

  // If
  NSString *storageKey = @"directory";
  AVAAbstractLog *log = [AVAAbstractLog new];
  [self.sut saveLog:log withStorageKey:storageKey];
  assertThatInteger(self.sut.buckets[storageKey].currentLogs.count,
                    equalToInteger(1));

  // When
  [self.sut loadLogsForStorageKey:storageKey withCompletion:nil];

  // Verify
  assertThat(self.sut.buckets[storageKey].currentLogs, isEmpty());
}

- (void)testDeleteFileRemovesLogsIdFromBlockedFilesList {

  // If
  NSString *storageKey = @"TestDirectory";
  NSString *batchId = @"12345";
  self.sut.buckets[storageKey] = [AVAStorageBucket new];
  AVAStorageBucket *bucket = self.sut.buckets[storageKey];
  AVAFile *blockedFile = [[AVAFile alloc] initWithPath:@"333"
                                                fileId:batchId
                                          creationDate:[NSDate date]];
  bucket.blockedFiles = [NSMutableArray arrayWithObject:blockedFile];

  // When
  [self.sut deleteLogsForId:batchId withStorageKey:storageKey];

  // Verify
  assertThatInteger(self.sut.buckets[storageKey].blockedFiles.count,
                    equalToInteger(0));
}

- (void)testDeleteFileWillCallFileHelperMethod {

  // If
  id fileHelperMock = OCMClassMock([AVAFileHelper class]);
  NSString *storageKey = @"TestDirectory";
  NSString *batchId = @"12345";
  self.sut.buckets[storageKey] = [AVAStorageBucket new];
  AVAStorageBucket *bucket = self.sut.buckets[storageKey];
  AVAFile *availableFile = [[AVAFile alloc] initWithPath:@"333"
                                                  fileId:batchId
                                            creationDate:[NSDate date]];
  bucket.availableFiles = [NSMutableArray arrayWithObject:availableFile];

  // When
  [self.sut deleteLogsForId:batchId withStorageKey:storageKey];

  // Verify
  OCMVerify([fileHelperMock deleteFile:availableFile]);
}

- (void)testLoadBatchWillReturnOldestFileFirst {

  // If
  NSString *storageKey = @"TestDirectory";
  self.sut.buckets[storageKey] = [AVAStorageBucket new];
  AVAStorageBucket *bucket = self.sut.buckets[storageKey];

  AVAFile *availableFile1 =
      [[AVAFile alloc] initWithPath:@"1"
                             fileId:@"1"
                       creationDate:[NSDate dateWithTimeIntervalSinceNow:1]];
  AVAFile *availableFile2 =
      [[AVAFile alloc] initWithPath:@"2"
                             fileId:@"2"
                       creationDate:[NSDate dateWithTimeIntervalSinceNow:3]];
  AVAFile *availableFile3 =
      [[AVAFile alloc] initWithPath:@"3"
                             fileId:@"3"
                       creationDate:[NSDate dateWithTimeIntervalSinceNow:5]];
  bucket.availableFiles = [NSMutableArray<AVAFile *>
      arrayWithObjects:availableFile1, availableFile2, availableFile3, nil];
  AVAFile *currentFile = [[AVAFile alloc] initWithPath:@"333"
                                                fileId:@"333"
                                          creationDate:[NSDate date]];
  bucket.currentFile = currentFile;

  // When
  __block NSString *batchId;
  [self.sut loadLogsForStorageKey:storageKey
                   withCompletion:^(NSArray<NSObject<AVALog> *> *logs,
                                    NSString *logsId) {
                     batchId = logsId;
                   }];

  // Verify
  assertThat(batchId, equalTo(availableFile3.fileId));
}

- (void)testLoadBatchWillAddItToBlockedFiles {

  // If
  NSString *storageKey = @"TestDirectory";
  self.sut.buckets[storageKey] = [AVAStorageBucket new];
  AVAStorageBucket *bucket = self.sut.buckets[storageKey];

  AVAFile *availableFile =
      [[AVAFile alloc] initWithPath:@"1"
                             fileId:@"1"
                       creationDate:[NSDate dateWithTimeIntervalSinceNow:1]];
  bucket.availableFiles =
      [NSMutableArray<AVAFile *> arrayWithObject:availableFile];
  AVAFile *currentFile = [[AVAFile alloc] initWithPath:@"333"
                                                fileId:@"333"
                                          creationDate:[NSDate date]];
  bucket.currentFile = currentFile;

  // When
  [self.sut loadLogsForStorageKey:storageKey
                   withCompletion:^(NSArray<NSObject<AVALog> *> *logs,
                                    NSString *logsId){
                   }];

  // Verify
  assertThatInteger(bucket.availableFiles.count, equalToInteger(1));
  assertThatInteger(bucket.blockedFiles.count, equalToInteger(1));
  assertThat(currentFile, isIn(bucket.availableFiles));
  assertThat(availableFile, isIn(bucket.blockedFiles));
}

- (void)testLoadBatchWillCreateNewCurrentFile {

  // If
  NSString *storageKey = @"TestDirectory";
  self.sut.buckets[storageKey] = [AVAStorageBucket new];
  AVAStorageBucket *bucket = self.sut.buckets[storageKey];
  AVAFile *currentFile = [[AVAFile alloc] initWithPath:@"333"
                                                fileId:@"333"
                                          creationDate:[NSDate date]];
  bucket.currentFile = currentFile;

  // When
  [self.sut loadLogsForStorageKey:storageKey
                   withCompletion:^(NSArray<NSObject<AVALog> *> *logs,
                                    NSString *logsId){
                   }];

  // Verify
  assertThat(bucket.currentFile, isNot(equalTo(currentFile)));
}

- (void)testLoadBatchWillAddCurrentFileToAvailableList {

  // If
  NSString *storageKey = @"TestDirectory";
  self.sut.buckets[storageKey] = [AVAStorageBucket new];
  AVAStorageBucket *bucket = self.sut.buckets[storageKey];
  AVAFile *currentFile = [[AVAFile alloc] initWithPath:@"333"
                                                fileId:@"333"
                                          creationDate:[NSDate date]];
  bucket.currentFile = currentFile;

  // When
  [self.sut loadLogsForStorageKey:storageKey
                   withCompletion:^(NSArray<NSObject<AVALog> *> *logs,
                                    NSString *logsId){
                   }];

  // Verify
  assertThatInteger(bucket.availableFiles.count, equalToInteger(1));
  assertThat(currentFile, isIn(bucket.availableFiles));
}

@end
