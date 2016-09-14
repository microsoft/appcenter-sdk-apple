#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "SNMFileHelper.h"
#import "SNMStorageTestHelper.h"

@interface SNMFileHelperTests : XCTestCase

@end

@implementation SNMFileHelperTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [SNMFileHelper setFileManager:nil];
  [SNMStorageTestHelper resetLogsDirectory];
  [super tearDown];
}

#pragma mark - Tests

- (void)testDefaultFileManagerIsUsedByDefault {

  // If
  NSFileManager *expected = [NSFileManager defaultManager];

  // When
  NSFileManager *actual = [SNMFileHelper fileManager];

  // Then
  assertThat(expected, equalTo(actual));
}

- (void)testCustomSetFileManagerWorks {

  // If
  NSFileManager *expected = [NSFileManager new];

  // When
  [SNMFileHelper setFileManager:expected];

  // Then
  NSFileManager *actual = [SNMFileHelper fileManager];
  assertThat(expected, equalTo(actual));
}

- (void)testStorageSubDirectoriesAreExcludedDromBackupButAppSupportFolderIsNotAffected {

  // Explicitly do not exclude app support folder from backups
  NSError *getResourceError = nil;
  NSNumber *resourveValue = nil;
  NSString *appSupportPath =
      [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
  XCTAssertTrue([[NSURL fileURLWithPath:appSupportPath] setResourceValue:@NO
                                                                  forKey:NSURLIsExcludedFromBackupKey
                                                                   error:&getResourceError]);

  // Create first file and verify that subdirectory is excluded from backups
  getResourceError = nil;
  resourveValue = nil;
  NSString *subDirectory = @"testDirectory";
  NSString *fileId = @"fileId";
  NSString *filePath = [SNMStorageTestHelper filePathForLogWithId:fileId extension:@"SNM" storageKey:subDirectory];
  SNMFile *file = [[SNMFile alloc] initWithPath:filePath fileId:fileId creationDate:[NSDate date]];

  [SNMFileHelper writeData:[NSData new] toFile:file];
  NSString *storagePath = [SNMStorageTestHelper storageDirForStorageKey:subDirectory];
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
  NSString *extension = @"SNM";
  SNMFile *file1 = [SNMStorageTestHelper createFileWithId:@"1"
                                                     data:[NSData new]
                                                extension:extension
                                               storageKey:subDirectory
                                             creationDate:[NSDate date]];
  SNMFile *file2 = [SNMStorageTestHelper createFileWithId:@"2"
                                                     data:[NSData new]
                                                extension:extension
                                               storageKey:subDirectory
                                             creationDate:[NSDate date]];

  // Create files with searched extension
  NSArray<SNMFile *> *expected = [NSArray arrayWithObjects:file1, file2, nil];

  // Create files with different extension
  [SNMStorageTestHelper createFileWithId:@"3"
                                    data:[NSData new]
                               extension:@"foo"
                              storageKey:subDirectory
                            creationDate:[NSDate date]];

  // When
  NSString *directory = [SNMStorageTestHelper storageDirForStorageKey:subDirectory];
  NSArray<SNMFile *> *actual = [SNMFileHelper filesForDirectory:directory withFileExtension:extension];

  // Then
  assertThatInteger(actual.count, equalToInteger(expected.count));
  for (int i = 0; i < actual.count; i++) {
    assertThat(actual[i].filePath, equalTo(expected[i].filePath));
    assertThat(actual[i].fileId, equalTo(expected[i].fileId));
    assertThat(actual[i].creationDate.description, equalTo(expected[i].creationDate.description));
  }
}

- (void)testCallingFileNamesForDirectoryWithNilPathReturnsNil {

  // If
  id fileManagerMock = OCMClassMock([NSFileManager class]);

  // When
  NSArray *actual = [SNMFileHelper filesForDirectory:nil withFileExtension:@"SNM"];

  // Then
  assertThat(actual, nilValue());
  OCMReject(
      [fileManagerMock contentsOfDirectoryAtPath:[OCMArg any] error:((NSError __autoreleasing **)[OCMArg anyPointer])]);
}

- (void)testDeletingExistingFileReturnsYes {

  // If
  SNMFile *file = [SNMStorageTestHelper createFileWithId:@"0"
                                                    data:[NSData new]
                                               extension:@"SNM"
                                              storageKey:@"testDirectory"
                                            creationDate:[NSDate date]];

  // When
  BOOL success = [SNMFileHelper deleteFile:file];

  // Then
  assertThatBool(success, isTrue());
}

- (void)testDeletingUnexistingFileReturnsNo {

  // If
  NSString *subDirectory = @"testDirectory";
  NSString *extension = @"SNM";
  NSString *fileName = @"foo";
  NSString *filePath = [SNMStorageTestHelper filePathForLogWithId:fileName extension:extension storageKey:subDirectory];
  SNMFile *file = [[SNMFile alloc] initWithPath:filePath fileId:fileName creationDate:[NSDate date]];

  // When
  BOOL success = [SNMFileHelper deleteFile:file];

  // Then
  assertThatBool(success, isFalse());
}

- (void)testDeletingFileWithEmptyPathReturnsNo {

  // If
  id fileManagerMock = OCMClassMock([NSFileManager class]);
  SNMFile *file = [SNMStorageTestHelper createFileWithId:@"0"
                                                    data:[NSData new]
                                               extension:@"SNM"
                                              storageKey:@"testDirectory"
                                            creationDate:[NSDate date]];
  file.filePath = nil;

  // When
  BOOL success = [SNMFileHelper deleteFile:file];

  // Then
  assertThatBool(success, isFalse());
  OCMReject([fileManagerMock removeItemAtPath:[OCMArg any] error:((NSError __autoreleasing **)[OCMArg anyPointer])]);
}

- (void)testReadingExistingFileReturnsCorrectContent {

  // If
  NSData *expected = [@"0" dataUsingEncoding:NSUTF8StringEncoding];
  SNMFile *file = [SNMStorageTestHelper createFileWithId:@"0"
                                                    data:expected
                                               extension:@"SNM"
                                              storageKey:@"testDirectory"
                                            creationDate:[NSDate date]];

  // When
  NSData *actual = [SNMFileHelper dataForFile:file];

  // Then
  assertThat(actual, equalTo(expected));
}

- (void)testReadingUnexistingFileReturnsNil {

  // If
  NSString *directory = [SNMStorageTestHelper logsDir];
  SNMFile *file = [SNMFile new];
  file.filePath = [directory stringByAppendingPathComponent:@"0.test"];

  // When
  NSData *actual = [SNMFileHelper dataForFile:file];

  // Then
  assertThat(actual, nilValue());
}

- (void)testSuccessfullyWritingDataItemsToFileWorksCorrectly {

  // If
  NSArray *items = @[ @"1", @"2" ];
  NSData *expected = [NSKeyedArchiver archivedDataWithRootObject:items];
  NSString *filePath = [SNMStorageTestHelper filePathForLogWithId:@"0" extension:@"SNM" storageKey:@"directory"];
  SNMFile *file = [[SNMFile alloc] initWithPath:filePath fileId:@"0" creationDate:[NSDate date]];

  // When
  BOOL success = [SNMFileHelper writeData:expected toFile:file];

  // Then
  assertThatBool(success, isTrue());
  assertThat(expected, equalTo([NSData dataWithContentsOfFile:filePath]));
}

- (void)testAppendingDataToUnexistingDirWillCreateDirAndFile {

  // If
  NSString *fileName = @"0";
  NSString *filePath =
      [SNMStorageTestHelper filePathForLogWithId:fileName extension:@"SNM" storageKey:@"testDirectory"];
  NSData *expected = [@"123456789" dataUsingEncoding:NSUTF8StringEncoding];
  SNMFile *file = [[SNMFile alloc] initWithPath:filePath fileId:fileName creationDate:[NSDate date]];

  // When
  NSData *actual;
  if ([SNMFileHelper writeData:expected toFile:file]) {
    actual = [SNMFileHelper dataForFile:file];
  }

  // Then
  assertThat(expected, equalTo(actual));
}

@end
