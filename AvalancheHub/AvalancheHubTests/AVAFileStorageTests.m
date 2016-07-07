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
  NSString *logsId = @"test123";
  NSString *storageKey = @"TestDirectory";
  AVAFile *file = [AVAStorageTestHelper createFileWithId:logsId data:[NSData new] extension:@"ava" storageKey:storageKey creationDate:[NSDate date]];
  assertThat(_sut.buckets[storageKey], nilValue());
  
  // When
  [_sut saveLog:[NSData new] withStorageKey:storageKey];
  
  // Verify
  AVAStorageBucket *bucket = _sut.buckets[storageKey];
  assertThatInteger(bucket.availableFiles.count, equalToInteger(1));
  assertThat(bucket.availableFiles[0], equalTo(file));
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

- (void)testRequestingCurrentFileWillCallFileHelperMethod {
  
  // If
  NSString *storageKey = @"TestDirectory";
  AVAFile *currentFile = [AVAStorageTestHelper createFileWithId:@"id" data:[NSData new] extension:@"ava" storageKey:storageKey creationDate:[NSDate date]];
  _sut.buckets[storageKey].currentFile = currentFile;
  id fileHelperMock = OCMClassMock([AVAFileHelper class]);
  
  // When
  __block NSString *fileId;
  [_sut loadLogsForStorageKey:storageKey withCompletion:^(NSArray<NSObject<AVALog> *> *logs,
                                                          NSString *logsId) {
    fileId = logsId;
  }];
  
  // Verify
  assertThat(fileId, equalTo(currentFile.fileId));
  OCMVerify([fileHelperMock dataForFile:currentFile]);
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
  
  // If
  NSString *storageKey = @"TestDirectory";
  AVAFile *currentFile = [AVAStorageTestHelper createFileWithId:@"id" data:[NSData new] extension:@"ava" storageKey:storageKey creationDate:[NSDate date]];
  _sut.buckets[storageKey].currentFile = currentFile;
  
  id fileHelperMock = OCMClassMock([AVAFileHelper class]);
  [_sut saveLog:[NSData new] withStorageKey:storageKey];
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
