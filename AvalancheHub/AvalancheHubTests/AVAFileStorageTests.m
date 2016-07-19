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

- (void)
    testRequestingCurrentFileWillAddItToBlockedFilesAndCreateNewCurrentFile {

  // If
  NSString *storageKey = @"TestDirectory";
  [self.sut saveLog:[AVAAbstractLog new] withStorageKey:storageKey];
  assertThat(self.sut.buckets[storageKey].blockedFiles, isEmpty());
  assertThat(self.sut.buckets[storageKey].availableFiles, isEmpty());

  // When
  [self.sut loadLogsForStorageKey:storageKey withCompletion:nil];

  // Verify
  assertThatInteger(self.sut.buckets[storageKey].blockedFiles.count,
                    equalToInteger(1));
  assertThat(self.sut.buckets[storageKey].availableFiles, isEmpty());
}

- (void)testRequestingCurrentFileWillEmptyCurrentLogs {

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
  [self.sut saveLog:[AVAAbstractLog new] withStorageKey:storageKey];
  __block NSString *batchId;
  [self.sut loadLogsForStorageKey:storageKey
                   withCompletion:^(NSArray<NSObject<AVALog> *> *logs,
                                    NSString *logsId) {
                     batchId = logsId;
                   }];
  assertThatInteger(self.sut.buckets[storageKey].blockedFiles.count,
                    equalToInteger(1));

  // When
  [self.sut deleteLogsForId:batchId withStorageKey:storageKey];

  // Verify
  assertThatInteger(self.sut.buckets[storageKey].blockedFiles.count,
                    equalToInteger(0));
}

- (void)testDeleteFileWillCallFileHelperMethod {

  // If: Create bucket, mock current file and load data of current file
  id fileHelperMock = OCMClassMock([AVAFileHelper class]);
  NSString *storageKey = @"TestDirectory";

  [self.sut saveLog:[AVAAbstractLog new] withStorageKey:storageKey];
  AVAFile *currentFile = [AVAStorageTestHelper createFileWithId:@"id"
                                                           data:[NSData new]
                                                      extension:@"ava"
                                                     storageKey:storageKey
                                                   creationDate:[NSDate date]];
  self.sut.buckets[storageKey].currentFile = currentFile;
  __block NSString *batchId;
  [self.sut loadLogsForStorageKey:storageKey
                   withCompletion:^(NSArray<NSObject<AVALog> *> *logs,
                                    NSString *logsId) {
                     batchId = logsId;
                   }];

  // When
  [self.sut deleteLogsForId:batchId withStorageKey:storageKey];

  // Verify
  OCMVerify([fileHelperMock deleteFile:currentFile]);
}

@end
