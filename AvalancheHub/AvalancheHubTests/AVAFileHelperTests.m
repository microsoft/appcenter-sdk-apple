#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "AVAFileHelper.h"

@interface AVAFileHelperTests : XCTestCase

@end

@implementation AVAFileHelperTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [AVAFileHelper setFileManager:nil];
  [self resetTestDirectory];
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
  NSInteger filesCount = 5;
  NSString *extension = @".test";
  NSString *directory = [self testDirectory];

  // Create files with searched extension
  NSArray *expected = [self createTestFilesOfCount:filesCount
                                     withExtension:extension
                                       inDirectory:directory];

  // Create files with different extension
  [self createTestFilesOfCount:3 withExtension:@".foo" inDirectory:directory];

  // When
  NSArray *actual = [AVAFileHelper fileNamesForDirectory:directory
                                       withFileExtension:extension];

  // Then
  assertThat(actual, equalTo(expected));
}

- (void)testDeletingExistingFileReturnsYes {

  // If
  NSString *extension = @".test";
  NSString *directory = [self testDirectory];
  [self createTestFilesOfCount:1 withExtension:extension inDirectory:directory];
  NSString *filePath = [directory
      stringByAppendingPathComponent:[NSString
                                         stringWithFormat:@"0%@", extension]];

  // When
  BOOL success = [AVAFileHelper deleteFileWithPath:filePath];

  // Then
  assertThatBool(success, isTrue());
}

- (void)testDeletingunexistingFileReturnsNo {

  // If
  NSString *filePath = [[self testDirectory]
      stringByAppendingPathComponent:[NSString
                                         stringWithFormat:@"0%@", @".test"]];

  // When
  BOOL success = [AVAFileHelper deleteFileWithPath:filePath];

  // Then
  assertThatBool(success, isFalse());
}

- (void)testReadingFileReturnsCorrectContent {

  // If
  NSString *extension = @".test";
  NSString *directory = [self testDirectory];
  [self createTestFilesOfCount:1 withExtension:extension inDirectory:directory];
  NSString *filePath = [directory
      stringByAppendingPathComponent:[NSString
                                         stringWithFormat:@"0%@", extension]];
  NSData *expected = [@"0" dataUsingEncoding:NSUTF8StringEncoding];

  // When
  NSData *actual = [AVAFileHelper dataForFileWithPath:filePath];

  // Then
  assertThat(actual, equalTo(expected));
}

- (void)testSuccessfullyAppendingDataToFileWorksCorrectly {

  // If
  NSString *extension = @".test";
  NSString *directory = [self testDirectory];
  [self createTestFilesOfCount:1 withExtension:extension inDirectory:directory];
  NSString *filePath = [directory
      stringByAppendingPathComponent:[NSString
                                         stringWithFormat:@"0%@", extension]];
  NSData *newData = [@"123456789" dataUsingEncoding:NSUTF8StringEncoding];
  NSData *expected = [@"0123456789" dataUsingEncoding:NSUTF8StringEncoding];

  // When
  NSData *actual;
  if ([AVAFileHelper appendData:newData toFileWithPath:filePath]) {
    actual = [AVAFileHelper dataForFileWithPath:filePath];
  }

  // Then
  assertThat(expected, equalTo(actual));
}

#pragma mark - Helper

- (NSString *)testDirectory {
  NSString *testPath =
      [NSTemporaryDirectory() stringByAppendingPathComponent:@"testDirectory"];
  return testPath;
}

- (void)resetTestDirectory {
  [[NSFileManager defaultManager] removeItemAtPath:[self testDirectory]
                                             error:nil];
}

- (void)createTestDirectory {
  NSError *error;
  [[NSFileManager defaultManager] createDirectoryAtPath:[self testDirectory]
                            withIntermediateDirectories:YES
                                             attributes:nil
                                                  error:&error];
}

- (NSArray *)createTestFilesOfCount:(NSInteger)count
                      withExtension:(NSString *)extension
                        inDirectory:(NSString *)directory {
  NSMutableArray *fileNames = [NSMutableArray new];
  [self createTestDirectory];

  for (int i = 0; i < count; i++) {
    NSData *data = [[NSString stringWithFormat:@"%d", i]
        dataUsingEncoding:NSUTF8StringEncoding];
    NSString *fileName = [NSString stringWithFormat:@"%i%@", i, extension];
    NSString *filePath = [directory stringByAppendingPathComponent:fileName];

    if ([[NSFileManager defaultManager] createFileAtPath:filePath
                                                contents:data
                                              attributes:nil]) {
      [fileNames addObject:fileName];
    }
  }
  return fileNames;
}

@end
