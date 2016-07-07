#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "AVAFileHelper.h"
#import "AVAStorageTestHelper.h"

@interface AVAFileHelperTests : XCTestCase

@end

@implementation AVAFileHelperTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [AVAFileHelper setFileManager:nil];
  [AVAStorageTestHelper resetLogsDirectory];
  [super tearDown];
}

#pragma mark - Tests

- (void)testDefaultFileManagerIsUsedByDefault {

  // If
  NSFileManager *expected = [NSFileManager defaultManager];

  // When
  NSFileManager *actual = [AVAFileHelper fileManager];

  // Then
  assertThat(expected, equalTo(actual));
}

- (void)testCustomSetFileManagerWorks {

  // If
  NSFileManager *expected = [NSFileManager new];

  // When
  [AVAFileHelper setFileManager:expected];

  // Then
  NSFileManager *actual = [AVAFileHelper fileManager];
  assertThat(expected, equalTo(actual));
}

- (void)testStorageSubDirectoriesAreExcludedDromBackupButAppSupportFolderIsNotAffected {
  
  // Explicitly do not exclude app support folder from backups
  NSError *getResourceError = nil;
  NSNumber *resourveValue = nil;
  NSString *appSupportPath = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
  XCTAssertTrue([[NSURL fileURLWithPath:appSupportPath] setResourceValue:@NO
                                                                  forKey:NSURLIsExcludedFromBackupKey
                                                                   error:&getResourceError]);
  
  // Create first file and verify that subdirectory is excluded from backups
  getResourceError = nil;
  resourveValue = nil;
  NSString *subDirectory = @"testDirectory";
  NSString *fileId = @"fileId";
  NSString *filePath = [AVAStorageTestHelper filePathForLogWithId:fileId extension:@"ava" storageKey:subDirectory];
  AVAFile *file = [[AVAFile alloc] initWithPath:filePath fileId:fileId creationDate:[NSDate date]];
  
  [AVAFileHelper appendData:[NSData new] toFile:file];
  NSString *storagePath = [AVAStorageTestHelper storageDirForStorageKey:subDirectory];
  [[NSURL fileURLWithPath:storagePath] getResourceValue:&resourveValue
                                                    forKey:NSURLIsExcludedFromBackupKey
                                                     error:&getResourceError];
  XCTAssertNil(getResourceError);
  XCTAssertEqual(resourveValue, @YES);
  
  // Verify that app support folder still isn't excluded
  [[NSURL fileURLWithPath:appSupportPath] getResourceValue:&resourveValue
                                                 forKey:NSURLIsExcludedFromBackupKey
                                                  error:&getResourceError];
  XCTAssertNil(getResourceError);
  XCTAssertEqual(resourveValue, @NO);
}

- (void)testOnlyExistingFileNamesWithExtensionInDirAreReturned {

  // If
  NSString *subDirectory = @"testDirectory";
  NSString *extension = @"ava";
  AVAFile *file1 = [AVAStorageTestHelper createFileWithId:@"1" data:[NSData new] extension:extension storageKey:subDirectory creationDate:[NSDate date]];
  AVAFile *file2 = [AVAStorageTestHelper createFileWithId:@"2" data:[NSData new] extension:extension storageKey:subDirectory creationDate:[NSDate date]];

  // Create files with searched extension
  NSArray<AVAFile *> *expected = [NSArray arrayWithObjects:file1, file2, nil];

  // Create files with different extension
  [AVAStorageTestHelper createFileWithId:@"3" data:[NSData new] extension:@"foo" storageKey:subDirectory creationDate:[NSDate date]];

  // When
  NSString *directory = [AVAStorageTestHelper storageDirForStorageKey:subDirectory];
  NSArray<AVAFile *> *actual = [AVAFileHelper filesForDirectory:directory withFileExtension:extension];

  // Then
  assertThatInteger(actual.count, equalToInteger(expected.count));
  for(int i = 0; i<actual.count; i++) {
    assertThat(actual[i].filePath, equalTo(expected[i].filePath));
    assertThat(actual[i].fileId, equalTo(expected[i].fileId));
    assertThat(actual[i].creationDate.description, equalTo(expected[i].creationDate.description));
  }
  
}

- (void)testCallingFileNamesForDirectoryWithNilPathReturnsNil {

  // If
  id fileManagerMock = OCMClassMock([NSFileManager class]);

  // When
  NSArray *actual =
      [AVAFileHelper filesForDirectory:nil withFileExtension:@"ava"];

  // Then
  assertThat(actual, nilValue());
  OCMReject([fileManagerMock
      contentsOfDirectoryAtPath:[OCMArg any]
                          error:((NSError __autoreleasing **)
                                     [OCMArg anyPointer])]);
}

- (void)testDeletingExistingFileReturnsYes {

  // If
  AVAFile *file = [AVAStorageTestHelper createFileWithId:@"0" data:[NSData new] extension:@"ava" storageKey:@"testDirectory" creationDate:[NSDate date]];

  // When
  BOOL success = [AVAFileHelper deleteFile:file];

  // Then
  assertThatBool(success, isTrue());
}

- (void)testDeletingUnexistingFileReturnsNo {

  // If
  NSString *subDirectory = @"testDirectory";
  NSString *extension = @"ava";
  NSString *fileName = @"foo";
  NSString *filePath = [AVAStorageTestHelper filePathForLogWithId:fileName extension:extension storageKey:subDirectory];
  AVAFile *file = [[AVAFile alloc] initWithPath:filePath fileId:fileName creationDate:[NSDate date]];

  // When
  BOOL success = [AVAFileHelper deleteFile:file];

  // Then
  assertThatBool(success, isFalse());
}

- (void)testDeletingFileWithEmptyPathReturnsNo {

  // If
  id fileManagerMock = OCMClassMock([NSFileManager class]);
  AVAFile *file = [AVAStorageTestHelper createFileWithId:@"0" data:[NSData new] extension:@"ava" storageKey:@"testDirectory" creationDate:[NSDate date]];
  file.filePath = nil;

  // When
  BOOL success = [AVAFileHelper deleteFile:file];

  // Then
  assertThatBool(success, isFalse());
  OCMReject([fileManagerMock
      removeItemAtPath:[OCMArg any]
                 error:((NSError __autoreleasing **)[OCMArg anyPointer])]);
}

- (void)testReadingExistingFileReturnsCorrectContent {

  // If
  NSData *expected = [@"0" dataUsingEncoding:NSUTF8StringEncoding];
  AVAFile *file = [AVAStorageTestHelper createFileWithId:@"0" data:expected extension:@"ava" storageKey:@"testDirectory" creationDate:[NSDate date]];

  // When
  NSData *actual = [AVAFileHelper dataForFile:file];

  // Then
  assertThat(actual, equalTo(expected));
}

- (void)testReadingUnexistingFileReturnsNil {

  // If
  NSString *directory = [AVAStorageTestHelper logsDir];
  AVAFile *file = [AVAFile new];
  file.filePath = [directory stringByAppendingPathComponent:@"0.test"];
  
  // When
  NSData *actual = [AVAFileHelper dataForFile:file];

  // Then
  assertThat(actual, nilValue());
}

- (void)testSuccessfullyAppendingDataToFileWorksCorrectly {

  // If
  NSData *oldData = [@"0" dataUsingEncoding:NSUTF8StringEncoding];
  NSData *newData = [@"123456789" dataUsingEncoding:NSUTF8StringEncoding];
  NSData *expected = [@"0123456789" dataUsingEncoding:NSUTF8StringEncoding];
  AVAFile *file = [AVAStorageTestHelper createFileWithId:@"0" data:oldData extension:@"ava" storageKey:@"testDirectory" creationDate:[NSDate date]];

  // When
  NSData *actual;
  if ([AVAFileHelper appendData:newData toFile:file]) {
    actual = [AVAFileHelper dataForFile:file];
  }

  // Then
  assertThat(expected, equalTo(actual));
}

- (void)testAppendingDataToUnexistingDirWillCreateDirAndFile {

  // If
  NSString *fileName = @"0";
  NSString *filePath = [AVAStorageTestHelper filePathForLogWithId:fileName extension:@"ava" storageKey:@"testDirectory"];
  NSData *expected = [@"123456789" dataUsingEncoding:NSUTF8StringEncoding];
  AVAFile *file = [[AVAFile alloc] initWithPath:filePath fileId:fileName creationDate:[NSDate date]];

  // When
  NSData *actual;
  if ([AVAFileHelper appendData:expected toFile:file]) {
    actual = [AVAFileHelper dataForFile:file];
  }

  // Then
  assertThat(expected, equalTo(actual));
}

// TODO: Test that Documents directory is excluded from backup

@end
