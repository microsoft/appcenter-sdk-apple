#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSFileHelper.h"
#import "MSStorageTestHelper.h"

@interface MSFileHelperTests : XCTestCase

@end

@implementation MSFileHelperTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [MSFileHelper setFileManager:nil];
  [MSStorageTestHelper resetLogsDirectory];
  [super tearDown];
}

#pragma mark - Tests

- (void)testDefaultFileManagerIsUsedByDefault {

  // If
  NSFileManager *expected = [NSFileManager defaultManager];

  // When
  NSFileManager *actual = [MSFileHelper fileManager];

  // Then
  assertThat(expected, equalTo(actual));
}

- (void)testCustomSetFileManagerWorks {

  // If
  NSFileManager *expected = [NSFileManager new];

  // When
  [MSFileHelper setFileManager:expected];

  // Then
  NSFileManager *actual = [MSFileHelper fileManager];
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
  NSString *filePath = [MSStorageTestHelper filePathForLogWithId:fileId extension:@"ms" storageKey:subDirectory];
  MSFile *file = [[MSFile alloc] initWithPath:filePath fileId:fileId creationDate:[NSDate date]];

  [MSFileHelper writeData:[NSData new] toFile:file];
  NSString *storagePath = [MSStorageTestHelper storageDirForStorageKey:subDirectory];
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
  NSString *extension = @"ms";
  MSFile *file1 = [MSStorageTestHelper createFileWithId:@"1"
                                                     data:[NSData new]
                                                extension:extension
                                               storageKey:subDirectory
                                             creationDate:[NSDate date]];
  MSFile *file2 = [MSStorageTestHelper createFileWithId:@"2"
                                                     data:[NSData new]
                                                extension:extension
                                               storageKey:subDirectory
                                             creationDate:[NSDate date]];

  // Create files with searched extension
  NSArray<MSFile *> *expected = [NSArray arrayWithObjects:file1, file2, nil];

  // Create files with different extension
  [MSStorageTestHelper createFileWithId:@"3"
                                    data:[NSData new]
                               extension:@"foo"
                              storageKey:subDirectory
                            creationDate:[NSDate date]];

  // When
  NSString *directory = [MSStorageTestHelper storageDirForStorageKey:subDirectory];
  NSArray<MSFile *> *actual = [MSFileHelper filesForDirectory:directory withFileExtension:extension];

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
  NSArray *actual = [MSFileHelper filesForDirectory:nil withFileExtension:@"ms"];

  // Then
  assertThat(actual, nilValue());
  OCMReject(
      [fileManagerMock contentsOfDirectoryAtPath:[OCMArg any] error:((NSError __autoreleasing **)[OCMArg anyPointer])]);
}

- (void)testDeletingExistingFileReturnsYes {

  // If
  MSFile *file = [MSStorageTestHelper createFileWithId:@"0"
                                                    data:[NSData new]
                                               extension:@"ms"
                                              storageKey:@"testDirectory"
                                            creationDate:[NSDate date]];

  // When
  BOOL success = [MSFileHelper deleteFile:file];

  // Then
  assertThatBool(success, isTrue());
}

- (void)testDeletingUnexistingFileReturnsNo {

  // If
  NSString *subDirectory = @"testDirectory";
  NSString *extension = @"ms";
  NSString *fileName = @"foo";
  NSString *filePath = [MSStorageTestHelper filePathForLogWithId:fileName extension:extension storageKey:subDirectory];
  MSFile *file = [[MSFile alloc] initWithPath:filePath fileId:fileName creationDate:[NSDate date]];

  // When
  BOOL success = [MSFileHelper deleteFile:file];

  // Then
  assertThatBool(success, isFalse());
}

- (void)testDeletingFileWithEmptyPathReturnsNo {

  // If
  id fileManagerMock = OCMClassMock([NSFileManager class]);
  MSFile *file = [MSStorageTestHelper createFileWithId:@"0"
                                                    data:[NSData new]
                                               extension:@"ms"
                                              storageKey:@"testDirectory"
                                            creationDate:[NSDate date]];
  file.filePath = nil;

  // When
  BOOL success = [MSFileHelper deleteFile:file];

  // Then
  assertThatBool(success, isFalse());
  OCMReject([fileManagerMock removeItemAtPath:[OCMArg any] error:((NSError __autoreleasing **)[OCMArg anyPointer])]);
}

- (void)testReadingExistingFileReturnsCorrectContent {

  // If
  NSData *expected = [@"0" dataUsingEncoding:NSUTF8StringEncoding];
  MSFile *file = [MSStorageTestHelper createFileWithId:@"0"
                                                    data:expected
                                               extension:@"ms"
                                              storageKey:@"testDirectory"
                                            creationDate:[NSDate date]];

  // When
  NSData *actual = [MSFileHelper dataForFile:file];

  // Then
  assertThat(actual, equalTo(expected));
}

- (void)testReadingUnexistingFileReturnsNil {

  // If
  NSString *directory = [MSStorageTestHelper logsDir];
  MSFile *file = [MSFile new];
  file.filePath = [directory stringByAppendingPathComponent:@"0.test"];

  // When
  NSData *actual = [MSFileHelper dataForFile:file];

  // Then
  assertThat(actual, nilValue());
}

- (void)testSuccessfullyWritingDataItemsToFileWorksCorrectly {

  // If
  NSArray *items = @[ @"1", @"2" ];
  NSData *expected = [NSKeyedArchiver archivedDataWithRootObject:items];
  NSString *filePath = [MSStorageTestHelper filePathForLogWithId:@"0" extension:@"ms" storageKey:@"directory"];
  MSFile *file = [[MSFile alloc] initWithPath:filePath fileId:@"0" creationDate:[NSDate date]];

  // When
  BOOL success = [MSFileHelper writeData:expected toFile:file];

  // Then
  assertThatBool(success, isTrue());
  assertThat(expected, equalTo([NSData dataWithContentsOfFile:filePath]));
}

- (void)testAppendingDataToUnexistingDirWillCreateDirAndFile {

  // If
  NSString *fileName = @"0";
  NSString *filePath =
      [MSStorageTestHelper filePathForLogWithId:fileName extension:@"ms" storageKey:@"testDirectory"];
  NSData *expected = [@"123456789" dataUsingEncoding:NSUTF8StringEncoding];
  MSFile *file = [[MSFile alloc] initWithPath:filePath fileId:fileName creationDate:[NSDate date]];

  // When
  NSData *actual;
  if ([MSFileHelper writeData:expected toFile:file]) {
    actual = [MSFileHelper dataForFile:file];
  }

  // Then
  assertThat(expected, equalTo(actual));
}

@end
