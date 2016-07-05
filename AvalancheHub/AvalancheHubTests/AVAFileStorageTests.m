#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>

#import "AVAFileStorage.h"
#import "AVAFileHelper.h"

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
}

#pragma mark - Tests

- (void)testNewInstanceWasInitialisedCorrectly {
  assertThat(_sut, notNilValue());
}

- (void)testFileStorageUsesCorrectFilePath {
  
  // If
  NSString *storageKey = @"TestDirectory";
  NSString *logsId = @"TestId";
  NSString *expected = [self filePathForLogWithId:logsId storageKey:storageKey];

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
  NSString *currentFilePath = _sut.buckets[storageKey].currentFilePath;
  assertThat(currentFilePath, containsSubstring(storageKey));
  OCMVerify([fileHelperMock appendData:logData toFileWithPath:currentFilePath]);
}

- (void)testRequestingCurrentFileWillAddItToBlockedFilesAndCreateNewCurrentFile {
  
  // If
  NSString *storageKey = @"TestDirectory";
  id fileHelperMock = OCMClassMock([AVAFileHelper class]);
  [_sut saveLog:[NSData new] withStorageKey:storageKey];
  assertThat(_sut.buckets[storageKey].blockedFiles, isEmpty());
  assertThat(_sut.buckets[storageKey].availableFiles, isEmpty());
  
  // When
  [_sut loadLogsForStorageKey:storageKey withCompletion:nil];
  
  // Verify
  assertThatInteger(_sut.buckets[storageKey].blockedFiles.count, equalToInteger(1));
  assertThat(_sut.buckets[storageKey].availableFiles, isEmpty());
}

#pragma mark - Helper

- (NSString *)filePathForLogWithId:(NSString *)logsId storageKey:(NSString *)storageKey {
  NSString *logFilePath = [NSString stringWithFormat:@"com.microsoft.avalanche/logs/%@/%@.ava", storageKey, logsId];
  NSString *documentsDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
  NSString *path = [documentsDir stringByAppendingPathComponent:logFilePath];
  
  return path;
}

@end
