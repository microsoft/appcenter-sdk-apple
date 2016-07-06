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

- (void)testOnlyExistingFileNamesWithExtensionInDirAreReturned {

  // If
  NSString *subDirectory = @"testDirectory";
  NSString *extension = @"ava";
  NSString *fileName1 = @"1";
  NSString *fileName2 = @"2";
  [AVAStorageTestHelper createLogFileWithId:fileName1 data:[NSData new] extension:extension storageKey:subDirectory];
  [AVAStorageTestHelper createLogFileWithId:fileName2 data:[NSData new] extension:extension storageKey:subDirectory];

  // Create files with searched extension
  NSArray *expected = [NSArray arrayWithObjects:fileName1, fileName2, nil];

  // Create files with different extension
  [AVAStorageTestHelper createLogFileWithId:@"foobar" data:[NSData new] extension:@"foo" storageKey:subDirectory];

  // When
  NSString *directory = [[AVAStorageTestHelper filePathForLogWithId:fileName1 extension:extension storageKey:subDirectory] stringByDeletingLastPathComponent];
  NSArray *actual = [AVAFileHelper fileNamesForDirectory:directory
                                       withFileExtension:extension];

  // Then
  assertThat(actual, equalTo(expected));
}

- (void)testCallingFileNamesForDirectoryWithNilPathReturnsNil {

  // If
  id fileManagerMock = OCMClassMock([NSFileManager class]);

  // When
  NSArray *actual =
      [AVAFileHelper fileNamesForDirectory:nil withFileExtension:@"ava"];

  // Then
  assertThat(actual, nilValue());
  OCMReject([fileManagerMock
      contentsOfDirectoryAtPath:[OCMArg any]
                          error:((NSError __autoreleasing **)
                                     [OCMArg anyPointer])]);
}

- (void)testDeletingExistingFileReturnsYes {

  // If
  NSString *fileName = @"0";
  NSString *subDirectory = @"testDirectory";
  NSString *extension = @"ava";
  [AVAStorageTestHelper createLogFileWithId:fileName data:[NSData new] extension:extension storageKey:subDirectory];
  NSString *filePath = [AVAStorageTestHelper filePathForLogWithId:fileName extension:extension storageKey:subDirectory];

  // When
  BOOL success = [AVAFileHelper deleteFileWithPath:filePath];

  // Then
  assertThatBool(success, isTrue());
}

- (void)testDeletingUnexistingFileReturnsNo {

  // If
  NSString *filePath = [AVAStorageTestHelper filePathForLogWithId:@"0" extension:@"awa" storageKey:@"testDirectory"];

  // When
  BOOL success = [AVAFileHelper deleteFileWithPath:filePath];

  // Then
  assertThatBool(success, isFalse());
}

- (void)testDeletingFileWithEmptyPathReturnsNo {

  // If
  id fileManagerMock = OCMClassMock([NSFileManager class]);

  // When
  BOOL success = [AVAFileHelper deleteFileWithPath:nil];

  // Then
  assertThatBool(success, isFalse());
  OCMReject([fileManagerMock
      removeItemAtPath:[OCMArg any]
                 error:((NSError __autoreleasing **)[OCMArg anyPointer])]);
}

- (void)testReadingExistingFileReturnsCorrectContent {

  // If
  NSString *fileName = @"0";
  NSString *subDirectory = @"testDirectory";
  NSString *extension = @"ava";
  NSData *expected = [@"0" dataUsingEncoding:NSUTF8StringEncoding];
  [AVAStorageTestHelper createLogFileWithId:fileName data:expected extension:extension storageKey:subDirectory];
  NSString *filePath = [AVAStorageTestHelper filePathForLogWithId:fileName extension:extension storageKey:subDirectory];
  

  // When
  NSData *actual = [AVAFileHelper dataForFileWithPath:filePath];

  // Then
  assertThat(actual, equalTo(expected));
}

- (void)testReadingUnexistingFileReturnsNil {

  // If
  NSString *directory = [AVAStorageTestHelper logsDir];
  NSString *filePath = [directory stringByAppendingPathComponent:@"0.test"];

  // When
  NSData *actual = [AVAFileHelper dataForFileWithPath:filePath];

  // Then
  assertThat(actual, nilValue());
}

- (void)testSuccessfullyAppendingDataToFileWorksCorrectly {

  // If
  NSString *fileName = @"0";
  NSString *subDirectory = @"testDirectory";
  NSString *extension = @"ava";
  NSData *oldData = [@"0" dataUsingEncoding:NSUTF8StringEncoding];
  NSData *newData = [@"123456789" dataUsingEncoding:NSUTF8StringEncoding];
  NSData *expected = [@"0123456789" dataUsingEncoding:NSUTF8StringEncoding];
  [AVAStorageTestHelper createLogFileWithId:fileName data:oldData extension:extension storageKey:subDirectory];
  NSString *filePath = [AVAStorageTestHelper filePathForLogWithId:fileName extension:extension storageKey:subDirectory];

  // When
  NSData *actual;
  if ([AVAFileHelper appendData:newData toFileWithPath:filePath]) {
    actual = [AVAFileHelper dataForFileWithPath:filePath];
  }

  // Then
  assertThat(expected, equalTo(actual));
}

- (void)testAppendingDataToUnexistingDirWillCreateDirAndFile {

  // If
  NSString *fileName = @"0";
  NSString *subDirectory = @"testDirectory";
  NSString *extension = @"ava";
  NSString *filePath = [AVAStorageTestHelper filePathForLogWithId:fileName extension:extension storageKey:subDirectory];
  NSData *expected = [@"123456789" dataUsingEncoding:NSUTF8StringEncoding];

  // When
  NSData *actual;
  if ([AVAFileHelper appendData:expected toFileWithPath:filePath]) {
    actual = [AVAFileHelper dataForFileWithPath:filePath];
  }

  // Then
  assertThat(expected, equalTo(actual));
}

// TODO: Test that Documents directory is excluded from backup

@end
