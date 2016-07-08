#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>

#import "AVAFileStorage.h"
#import "AVAFileHelper.h"
#import "AVAStorageTestHelper.h"
#import "AVAFile.h"

@interface AVAFileStorageTests : XCTestCase

@property(nonatomic, strong) AVAFileStorage *sut;

@end

@implementation AVAFileStorageTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
  _sut = [AVAFileStorage new];
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
  NSString *expected = [AVAStorageTestHelper filePathForLogWithId:logsId extension:@"ava" storageKey:storageKey];

  // When
  NSString *actual = [_sut filePathForStorageKey:storageKey logsId:logsId];
  
  // Then
  assertThat(actual, equalTo(expected));
}

- (void)testSavingFirstFileCreatesNewBucket {
  
  // If
  NSString *storageKey = @"TestDirectory";
  id fileHelperMock = OCMClassMock([AVAFileHelper class]);
  NSData *logData = [NSData new];
  assertThat(_sut.buckets[storageKey], nilValue());
  
  // When
  [_sut saveLog:logData withStorageKey:storageKey];
  
  // Verify
  AVAFile *currentFile = _sut.buckets[storageKey].currentFile;
  assertThat(currentFile, notNilValue());
  assertThat(currentFile.creationDate, notNilValue());
  assertThat(currentFile.fileId, notNilValue());
  
  OCMVerify([fileHelperMock appendData:logData toFile:currentFile]);
}

- (void)testCreatingNewBucketsWillLoadExistingFiles {
  
  // If
  NSString *storageKey = @"TestDirectory";
  AVAFile *expected = [AVAStorageTestHelper createFileWithId:@"test123" data:[NSData new] extension:@"ava" storageKey:storageKey creationDate:[NSDate date]];
  assertThat(_sut.buckets[storageKey], nilValue());
  
  // When
  [_sut saveLog:[NSData new] withStorageKey:storageKey];
  
  // Verify
  AVAStorageBucket *bucket = _sut.buckets[storageKey];
  AVAFile *actual = bucket.availableFiles[0];
  assertThatInteger(bucket.availableFiles.count, equalToInteger(1));
  assertThat(actual.filePath, equalTo(expected.filePath));
  assertThat(actual.fileId, equalTo(expected.fileId));
  assertThat(actual.creationDate.description, equalTo(expected.creationDate.description));
}

- (void)testRequestingCurrentFileWillAddItToBlockedFilesAndCreateNewCurrentFile {
  
  // If
  NSString *storageKey = @"TestDirectory";
  NSData *logData = [NSData new];
  [_sut saveLog:logData withStorageKey:storageKey];
  assertThat(_sut.buckets[storageKey].blockedFiles, isEmpty());
  assertThat(_sut.buckets[storageKey].availableFiles, isEmpty());
  
  // When
  [_sut loadLogsForStorageKey:storageKey withCompletion:nil];
  
  // Verify
  assertThatInteger(_sut.buckets[storageKey].blockedFiles.count, equalToInteger(1));
  assertThat(_sut.buckets[storageKey].availableFiles, isEmpty());
}

- (void)testDeleteFileRemovesLogsIdFromBlockedFilesList {
  
  // If
  NSString *storageKey = @"TestDirectory";
  [_sut saveLog:[NSData new] withStorageKey:storageKey];
  __block NSString *batchId;
  [_sut loadLogsForStorageKey:storageKey withCompletion:^(NSArray<NSObject<AVALog> *> *logs,
                                                          NSString *logsId) {
    batchId = logsId;
  }];
  assertThatInteger(_sut.buckets[storageKey].blockedFiles.count, equalToInteger(1));
  
  // When
  [_sut deleteLogsForId:batchId withStorageKey:storageKey];
  
  // Verify
  assertThatInteger(_sut.buckets[storageKey].blockedFiles.count, equalToInteger(0));
}

- (void)testDeleteFileWillCallFileHelperMethod {
  
  // If: Create bucket, mock current file and load data of current file
    id fileHelperMock = OCMClassMock([AVAFileHelper class]);
  NSString *storageKey = @"TestDirectory";
  
  [_sut saveLog:[NSData new] withStorageKey:storageKey];
  AVAFile *currentFile = [AVAStorageTestHelper createFileWithId:@"id" data:[NSData new] extension:@"ava" storageKey:storageKey creationDate:[NSDate date]];
  _sut.buckets[storageKey].currentFile = currentFile;
  __block NSString *batchId;
  [_sut loadLogsForStorageKey:storageKey withCompletion:^(NSArray<NSObject<AVALog> *> *logs,
                                                          NSString *logsId) {
    batchId = logsId;
  }];
  
  // When
  [_sut deleteLogsForId:batchId withStorageKey:storageKey];
  
  // Verify
  OCMVerify([fileHelperMock deleteFile:currentFile]);
}

@end
