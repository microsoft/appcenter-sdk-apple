#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSFileUtil.h"
#import "MSStorageTestUtil.h"

@interface MSFileUtilTests : XCTestCase

@end

@implementation MSFileUtilTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [MSFileUtil setFileManager:nil];
  [MSStorageTestUtil resetLogsDirectory];
  [super tearDown];
}

#pragma mark - Tests

- (void)testDefaultFileManagerIsUsedByDefault {

  // If
  NSFileManager *expected = [NSFileManager defaultManager];

  // When
  NSFileManager *actual = [MSFileUtil fileManager];

  // Then
  assertThat(expected, equalTo(actual));
}

- (void)testCustomSetFileManagerWorks {

  // If
  NSFileManager *expected = [NSFileManager new];

  // When
  [MSFileUtil setFileManager:expected];

  // Then
  NSFileManager *actual = [MSFileUtil fileManager];
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
  NSString *filePath = [MSStorageTestUtil filePathForLogWithId:fileId extension:@"ms" storageKey:subDirectory];
  MSFile *file = [[MSFile alloc] initWithPath:filePath fileId:fileId creationDate:[NSDate date]];

  [MSFileUtil writeData:[NSData new] toFile:file];
  NSString *storagePath = [MSStorageTestUtil storageDirForStorageKey:subDirectory];
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
  MSFile *file1 = [MSStorageTestUtil createFileWithId:@"1"
                                                     data:[NSData new]
                                                extension:extension
                                               storageKey:subDirectory
                                             creationDate:[NSDate date]];
  MSFile *file2 = [MSStorageTestUtil createFileWithId:@"2"
                                                     data:[NSData new]
                                                extension:extension
                                               storageKey:subDirectory
                                             creationDate:[NSDate date]];

  // Create files with searched extension
  NSArray<MSFile *> *expected = [NSArray arrayWithObjects:file1, file2, nil];

  // Create files with different extension
  [MSStorageTestUtil createFileWithId:@"3"
                                    data:[NSData new]
                               extension:@"foo"
                              storageKey:subDirectory
                            creationDate:[NSDate date]];

  // When
  NSString *directory = [MSStorageTestUtil storageDirForStorageKey:subDirectory];
  NSArray<MSFile *> *actual = [MSFileUtil filesForDirectory:directory withFileExtension:extension];

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
  NSArray *actual = [MSFileUtil filesForDirectory:nil withFileExtension:@"ms"];

  // Then
  assertThat(actual, nilValue());
  OCMReject(
      [fileManagerMock contentsOfDirectoryAtPath:[OCMArg any] error:((NSError __autoreleasing **)[OCMArg anyPointer])]);
}

- (void)testDeletingExistingFileReturnsYes {

  // If
  MSFile *file = [MSStorageTestUtil createFileWithId:@"0"
                                                    data:[NSData new]
                                               extension:@"ms"
                                              storageKey:@"testDirectory"
                                            creationDate:[NSDate date]];

  // When
  BOOL success = [MSFileUtil deleteFile:file];

  // Then
  assertThatBool(success, isTrue());
}

- (void)testDeletingUnexistingFileReturnsNo {

  // If
  NSString *subDirectory = @"testDirectory";
  NSString *extension = @"ms";
  NSString *fileName = @"foo";
  NSString *filePath = [MSStorageTestUtil filePathForLogWithId:fileName extension:extension storageKey:subDirectory];
  MSFile *file = [[MSFile alloc] initWithPath:filePath fileId:fileName creationDate:[NSDate date]];

  // When
  BOOL success = [MSFileUtil deleteFile:file];

  // Then
  assertThatBool(success, isFalse());
}

- (void)testDeletingFileWithEmptyPathReturnsNo {

  // If
  id fileManagerMock = OCMClassMock([NSFileManager class]);
  MSFile *file = [MSStorageTestUtil createFileWithId:@"0"
                                                    data:[NSData new]
                                               extension:@"ms"
                                              storageKey:@"testDirectory"
                                            creationDate:[NSDate date]];
  file.filePath = nil;

  // When
  BOOL success = [MSFileUtil deleteFile:file];

  // Then
  assertThatBool(success, isFalse());
  OCMReject([fileManagerMock removeItemAtPath:[OCMArg any] error:((NSError __autoreleasing **)[OCMArg anyPointer])]);
}

- (void)testReadingExistingFileReturnsCorrectContent {

  // If
  NSData *expected = [@"0" dataUsingEncoding:NSUTF8StringEncoding];
  MSFile *file = [MSStorageTestUtil createFileWithId:@"0"
                                                    data:expected
                                               extension:@"ms"
                                              storageKey:@"testDirectory"
                                            creationDate:[NSDate date]];

  // When
  NSData *actual = [MSFileUtil dataForFile:file];

  // Then
  assertThat(actual, equalTo(expected));
}

- (void)testReadingUnexistingFileReturnsNil {

  // If
  NSString *directory = [MSStorageTestUtil logsDir];
  MSFile *file = [MSFile new];
  file.filePath = [directory stringByAppendingPathComponent:@"0.test"];

  // When
  NSData *actual = [MSFileUtil dataForFile:file];

  // Then
  assertThat(actual, nilValue());
}

- (void)testSuccessfullyWritingDataItemsToFileWorksCorrectly {

  // If
  NSArray *items = @[ @"1", @"2" ];
  NSData *expected = [NSKeyedArchiver archivedDataWithRootObject:items];
  NSString *filePath = [MSStorageTestUtil filePathForLogWithId:@"0" extension:@"ms" storageKey:@"directory"];
  MSFile *file = [[MSFile alloc] initWithPath:filePath fileId:@"0" creationDate:[NSDate date]];

  // When
  BOOL success = [MSFileUtil writeData:expected toFile:file];

  // Then
  assertThatBool(success, isTrue());
  assertThat(expected, equalTo([NSData dataWithContentsOfFile:filePath]));
}

- (void)testAppendingDataToUnexistingDirWillCreateDirAndFile {

  // If
  NSString *fileName = @"0";
  NSString *filePath =
      [MSStorageTestUtil filePathForLogWithId:fileName extension:@"ms" storageKey:@"testDirectory"];
  NSData *expected = [@"123456789" dataUsingEncoding:NSUTF8StringEncoding];
  MSFile *file = [[MSFile alloc] initWithPath:filePath fileId:fileName creationDate:[NSDate date]];

  // When
  NSData *actual;
  if ([MSFileUtil writeData:expected toFile:file]) {
    actual = [MSFileUtil dataForFile:file];
  }

  // Then
  assertThat(expected, equalTo(actual));
}

@end
