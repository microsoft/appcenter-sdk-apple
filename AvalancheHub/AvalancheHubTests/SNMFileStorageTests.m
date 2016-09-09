#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "SNMAbstractLog.h"
#import "SNMFile.h"
#import "SNMFileHelper.h"
#import "SNMFileStorage.h"
#import "SNMStorageTestHelper.h"

@interface SNMFileStorageTests : XCTestCase

@property(nonatomic, strong) SNMFileStorage *sut;

@end

@implementation SNMFileStorageTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
  self.sut = [SNMFileStorage new];
}

- (void)tearDown {
  [super tearDown];
  [SNMStorageTestHelper resetLogsDirectory];
}

#pragma mark - Tests

- (void)testNewInstanceWasInitialisedCorrectly {
  assertThat(_sut, notNilValue());
}

- (void)testFileStorageUsesCorrectFilePath {

  // If
  NSString *storageKey = @"TestDirectory";
  NSString *logsId = @"TestId";
  NSString *expected = [SNMStorageTestHelper filePathForLogWithId:logsId extension:@"snm" storageKey:storageKey];

  // When
  NSString *actual = [self.sut filePathForStorageKey:storageKey logsId:logsId];

  // Then
  assertThat(actual, equalTo(expected));
}

- (void)testSavingFirstFileCreatesNewBucket {

  // If
  NSString *storageKey = @"TestDirectory";
  id fileHelperMock = OCMClassMock([SNMFileHelper class]);
  SNMAbstractLog *log = [SNMAbstractLog new];
  SNMStorageBucket *bucket = self.sut.buckets[storageKey];
  assertThat(bucket, nilValue());

  // When
  [self.sut saveLog:log withStorageKey:storageKey];

  // Verify
  SNMStorageBucket *actualBucket = self.sut.buckets[storageKey];
  SNMFile *actualCurrentFile = actualBucket.currentFile;
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
  SNMAbstractLog *log = [SNMAbstractLog new];
  SNMFile *expected = [SNMStorageTestHelper createFileWithId:@"test123"
                                                        data:[NSData new]
                                                   extension:@"SNM"
                                                  storageKey:storageKey
                                                creationDate:[NSDate date]];
  assertThat(self.sut.buckets[storageKey], nilValue());

  // When
  [self.sut saveLog:log withStorageKey:storageKey];

  // Verify
  SNMStorageBucket *bucket = self.sut.buckets[storageKey];
  SNMFile *actual = bucket.SNMilableFiles.lastObject;
  assertThat(actual.filePath, equalTo(expected.filePath));
  assertThat(actual.fileId, equalTo(expected.fileId));
  assertThat(actual.creationDate.description, equalTo(expected.creationDate.description));
}

- (void)testSaveFirstLogOfABatchWillNotAddItToCurrentFileIfItIsNil {

  // If
  NSString *storageKey = @"TestDirectory";
  SNMAbstractLog *log = nil;
  SNMStorageBucket *bucket = [self.sut bucketForStorageKey:storageKey];

  // When
  [self.sut saveLog:log withStorageKey:storageKey];

  // Verify
  assertThat(bucket.currentLogs, isEmpty());
}

- (void)testSaveFirstLogOfABatchWillAddCurrentFileToSNMilableList {

  // If
  NSString *storageKey = @"TestDirectory";
  SNMAbstractLog *log = [SNMAbstractLog new];
  assertThat(self.sut.buckets[storageKey], nilValue());

  // When
  [self.sut saveLog:log withStorageKey:storageKey];

  // Verify
  SNMStorageBucket *bucket = self.sut.buckets[storageKey];
  SNMFile *expected = bucket.currentFile;
  SNMFile *actual = bucket.SNMilableFiles.lastObject;
  assertThat(actual, equalTo(expected));
  assertThat(bucket.SNMilableFiles, hasCountOf(1));
}

- (void)testSaveFirstLogOfBatchWillDeleteOldestFileIfFileLimitHasBeenReached {

  // If
  NSString *storageKey = @"TestDirectory";
  SNMStorageBucket *bucket = [self.sut bucketForStorageKey:storageKey];

  SNMFile *SNMilableFile1 =
      [[SNMFile alloc] initWithPath:@"1" fileId:@"1" creationDate:[NSDate dateWithTimeIntervalSinceNow:1]];
  SNMFile *SNMilableFile2 =
      [[SNMFile alloc] initWithPath:@"2" fileId:@"2" creationDate:[NSDate dateWithTimeIntervalSinceNow:3]];
  SNMFile *SNMilableFile3 =
      [[SNMFile alloc] initWithPath:@"3" fileId:@"3" creationDate:[NSDate dateWithTimeIntervalSinceNow:5]];
  bucket.SNMilableFiles =
      [NSMutableArray<SNMFile *> arrayWithObjects:SNMilableFile1, SNMilableFile2, SNMilableFile3, nil];
  self.sut.bucketFileCountLimit = bucket.SNMilableFiles.count;
  SNMAbstractLog *log = [SNMAbstractLog new];

  // When
  [self.sut saveLog:log withStorageKey:storageKey];

  // Verify
  assertThatInteger(bucket.SNMilableFiles.count, equalToInteger(3));
  assertThat(bucket.SNMilableFiles, containsInRelativeOrder(@[ bucket.currentFile, SNMilableFile1, SNMilableFile2 ]));
}

- (void)testDeleteFileRemovesLogsIdFromBlockedFilesList {

  // If
  NSString *storageKey = @"TestDirectory";
  NSString *batchId = @"12345";
  self.sut.buckets[storageKey] = [SNMStorageBucket new];
  SNMStorageBucket *bucket = self.sut.buckets[storageKey];
  SNMFile *blockedFile = [[SNMFile alloc] initWithPath:@"333" fileId:batchId creationDate:[NSDate date]];
  bucket.blockedFiles = [NSMutableArray arrayWithObject:blockedFile];

  // When
  [self.sut deleteLogsForId:batchId withStorageKey:storageKey];

  // Verify
  assertThatInteger(self.sut.buckets[storageKey].blockedFiles.count, equalToInteger(0));
}

- (void)testDeleteFileWillCallFileHelperMethod {

  // If
  id fileHelperMock = OCMClassMock([SNMFileHelper class]);
  NSString *storageKey = @"TestDirectory";
  NSString *batchId = @"12345";
  self.sut.buckets[storageKey] = [SNMStorageBucket new];
  SNMStorageBucket *bucket = self.sut.buckets[storageKey];
  SNMFile *SNMilableFile = [[SNMFile alloc] initWithPath:@"333" fileId:batchId creationDate:[NSDate date]];
  bucket.SNMilableFiles = [NSMutableArray arrayWithObject:SNMilableFile];

  // When
  [self.sut deleteLogsForId:batchId withStorageKey:storageKey];

  // Verify
  OCMVerify([fileHelperMock deleteFile:SNMilableFile]);
}

- (void)testLoadBatchWillEmptyCurrentLogs {

  // If
  NSString *storageKey = @"directory";
  SNMAbstractLog *log = [SNMAbstractLog new];
  [self.sut saveLog:log withStorageKey:storageKey];
  assertThatInteger(self.sut.buckets[storageKey].currentLogs.count, equalToInteger(1));

  // When
  [self.sut loadLogsForStorageKey:storageKey withCompletion:nil];

  // Verify
  assertThat(self.sut.buckets[storageKey].currentLogs, isEmpty());
}

- (void)testLoadBatchWillReturnOldestFileFirst {

  // If
  NSString *storageKey = @"TestDirectory";
  self.sut.buckets[storageKey] = [SNMStorageBucket new];
  SNMStorageBucket *bucket = self.sut.buckets[storageKey];

  SNMFile *SNMilableFile1 =
      [[SNMFile alloc] initWithPath:@"1" fileId:@"1" creationDate:[NSDate dateWithTimeIntervalSinceNow:1]];
  SNMFile *SNMilableFile2 =
      [[SNMFile alloc] initWithPath:@"2" fileId:@"2" creationDate:[NSDate dateWithTimeIntervalSinceNow:3]];
  SNMFile *SNMilableFile3 =
      [[SNMFile alloc] initWithPath:@"3" fileId:@"3" creationDate:[NSDate dateWithTimeIntervalSinceNow:5]];
  bucket.SNMilableFiles =
      [NSMutableArray<SNMFile *> arrayWithObjects:SNMilableFile1, SNMilableFile2, SNMilableFile3, nil];
  SNMFile *currentFile = [[SNMFile alloc] initWithPath:@"333" fileId:@"333" creationDate:[NSDate date]];
  bucket.currentFile = currentFile;

  // When
  __block NSString *batchId;
  [self.sut loadLogsForStorageKey:storageKey
                   withCompletion:^(NSArray<NSObject<SNMLog> *> *logs, NSString *logsId) {
                     batchId = logsId;
                   }];

  // Verify
  assertThat(batchId, equalTo(SNMilableFile3.fileId));
}

- (void)testLoadBatchWillAddItToBlockedFiles {

  // If
  NSString *storageKey = @"TestDirectory";
  self.sut.buckets[storageKey] = [SNMStorageBucket new];
  SNMStorageBucket *bucket = self.sut.buckets[storageKey];

  SNMFile *SNMilableFile =
      [[SNMFile alloc] initWithPath:@"1" fileId:@"1" creationDate:[NSDate dateWithTimeIntervalSinceNow:1]];
  bucket.SNMilableFiles = [NSMutableArray<SNMFile *> arrayWithObject:SNMilableFile];

  // When
  [self.sut loadLogsForStorageKey:storageKey
                   withCompletion:^(NSArray<NSObject<SNMLog> *> *logs, NSString *logsId){
                   }];

  // Verify
  assertThatInteger(bucket.SNMilableFiles.count, equalToInteger(0));
  assertThatInteger(bucket.blockedFiles.count, equalToInteger(1));
  assertThat(bucket.blockedFiles, hasItem(SNMilableFile));
}

- (void)testLoadBatchWillCreateNewCurrentFile {

  // If
  NSString *storageKey = @"TestDirectory";
  self.sut.buckets[storageKey] = [SNMStorageBucket new];
  SNMStorageBucket *bucket = self.sut.buckets[storageKey];
  SNMFile *currentFile = [[SNMFile alloc] initWithPath:@"333" fileId:@"333" creationDate:[NSDate date]];
  bucket.currentFile = currentFile;

  // When
  [self.sut loadLogsForStorageKey:storageKey
                   withCompletion:^(NSArray<NSObject<SNMLog> *> *logs, NSString *logsId){
                   }];

  // Verify
  assertThat(bucket.currentFile, isNot(equalTo(currentFile)));
}

@end
