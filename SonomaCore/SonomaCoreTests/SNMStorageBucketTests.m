#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "SNMFile.h"
#import "SNMFileStorage.h"

@interface SNMStorageBucketTests : XCTestCase

@property(nonatomic, strong) SNMStorageBucket *sut;

@end

@implementation SNMStorageBucketTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
  _sut = [SNMStorageBucket new];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - Tests

- (void)testNewInstanceWasInitialisedCorrectly {
  assertThat(_sut, notNilValue());
  assertThat(_sut.availableFiles, notNilValue());
  assertThat(_sut.availableFiles, isEmpty());
  assertThat(_sut.blockedFiles, notNilValue());
  assertThat(_sut.blockedFiles, isEmpty());
}

- (void)testSortingFilesByCreationDate {

  // If
  SNMFile *file1 = [[SNMFile alloc] initWithPath:@"3" fileId:@"3" creationDate:[NSDate dateWithTimeIntervalSinceNow:1]];
  SNMFile *file2 = [[SNMFile alloc] initWithPath:@"2" fileId:@"2" creationDate:[NSDate dateWithTimeIntervalSinceNow:2]];
  SNMFile *file3 = [[SNMFile alloc] initWithPath:@"1" fileId:@"1" creationDate:[NSDate dateWithTimeIntervalSinceNow:3]];
  NSMutableArray *unsortedFiles = [NSMutableArray arrayWithObjects:file2, file3, file1, nil];
  _sut.availableFiles = unsortedFiles;

  // When
  NSMutableArray *expected = [NSMutableArray arrayWithObjects:file1, file2, file3, nil];
    [self.sut sortAvailableFilesByCreationDate];

  // Then
  assertThat(_sut.availableFiles, equalTo(expected));
}

- (void)testRequestingFileByIdWillReturnCorrectFile {

  // If
  SNMFile *availableFile1 =
      [[SNMFile alloc] initWithPath:@"1" fileId:@"1" creationDate:[NSDate dateWithTimeIntervalSinceNow:1]];
  SNMFile *availableFile2 =
      [[SNMFile alloc] initWithPath:@"2" fileId:@"2" creationDate:[NSDate dateWithTimeIntervalSinceNow:2]];
  SNMFile *availableFile3 =
      [[SNMFile alloc] initWithPath:@"3" fileId:@"3" creationDate:[NSDate dateWithTimeIntervalSinceNow:3]];
  _sut.availableFiles = [NSMutableArray arrayWithObjects:availableFile1, availableFile2, availableFile3, nil];

  SNMFile *blockedFile1 =
      [[SNMFile alloc] initWithPath:@"4" fileId:@"4" creationDate:[NSDate dateWithTimeIntervalSinceNow:1]];
  SNMFile *blockedFile2 =
      [[SNMFile alloc] initWithPath:@"5" fileId:@"5" creationDate:[NSDate dateWithTimeIntervalSinceNow:2]];
  SNMFile *blockedFile3 =
      [[SNMFile alloc] initWithPath:@"6" fileId:@"6" creationDate:[NSDate dateWithTimeIntervalSinceNow:3]];
  self.sut.blockedFiles = [NSMutableArray arrayWithObjects:blockedFile1, blockedFile2, blockedFile3, nil];

  // When
  SNMFile *foundAvailableFile = [_sut fileWithId:@"3"];
  SNMFile *foundBlockedFile = [_sut fileWithId:@"5"];

  // Then
  assertThat(foundAvailableFile, equalTo(availableFile3));
  assertThat(foundBlockedFile, equalTo(blockedFile2));
}

- (void)testRequestingUnexisitngFileByIdWillReturnNil {

  // If
  SNMFile *availableFile1 =
      [[SNMFile alloc] initWithPath:@"1" fileId:@"1" creationDate:[NSDate dateWithTimeIntervalSinceNow:1]];
  SNMFile *availableFile2 =
      [[SNMFile alloc] initWithPath:@"2" fileId:@"2" creationDate:[NSDate dateWithTimeIntervalSinceNow:2]];
  SNMFile *availableFile3 =
      [[SNMFile alloc] initWithPath:@"3" fileId:@"3" creationDate:[NSDate dateWithTimeIntervalSinceNow:3]];
  self.sut.availableFiles = [NSMutableArray arrayWithObjects:availableFile1, availableFile2, availableFile3, nil];

  // When
  SNMFile *actual = [_sut fileWithId:@"4"];

  // Then
  assertThat(actual, nilValue());
}

- (void)testRemovingFileRemovesItFromBlockedAndAvailableList {

  // If
  SNMFile *file1 = [[SNMFile alloc] initWithPath:@"1" fileId:@"1" creationDate:[NSDate dateWithTimeIntervalSinceNow:1]];
  SNMFile *file2 = [[SNMFile alloc] initWithPath:@"2" fileId:@"2" creationDate:[NSDate dateWithTimeIntervalSinceNow:2]];
  self.sut.availableFiles = [NSMutableArray arrayWithObjects:file1, file2, nil];
  self.sut.blockedFiles = [NSMutableArray arrayWithObjects:file2, file1, nil];

  // When
  [self.sut removeFile:file1];

  // Then
  assertThat(self.sut.availableFiles, hasCountOf(1));
  assertThat(self.sut.availableFiles, isNot(hasItem(file1)));
  assertThat(self.sut.blockedFiles, hasCountOf(1));
  assertThat(self.sut.blockedFiles, isNot(hasItem(file1)));
}

@end
