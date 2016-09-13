#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "AVAFile.h"
#import "AVAFileStorage.h"

@interface AVAStorageBucketTests : XCTestCase

@property(nonatomic, strong) AVAStorageBucket *sut;

@end

@implementation AVAStorageBucketTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
  _sut = [AVAStorageBucket new];
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
  AVAFile *file1 = [[AVAFile alloc] initWithPath:@"3" fileId:@"3" creationDate:[NSDate dateWithTimeIntervalSinceNow:1]];
  AVAFile *file2 = [[AVAFile alloc] initWithPath:@"2" fileId:@"2" creationDate:[NSDate dateWithTimeIntervalSinceNow:2]];
  AVAFile *file3 = [[AVAFile alloc] initWithPath:@"1" fileId:@"1" creationDate:[NSDate dateWithTimeIntervalSinceNow:3]];
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
  AVAFile *availableFile1 =
      [[AVAFile alloc] initWithPath:@"1" fileId:@"1" creationDate:[NSDate dateWithTimeIntervalSinceNow:1]];
  AVAFile *availableFile2 =
      [[AVAFile alloc] initWithPath:@"2" fileId:@"2" creationDate:[NSDate dateWithTimeIntervalSinceNow:2]];
  AVAFile *availableFile3 =
      [[AVAFile alloc] initWithPath:@"3" fileId:@"3" creationDate:[NSDate dateWithTimeIntervalSinceNow:3]];
  _sut.availableFiles = [NSMutableArray arrayWithObjects:availableFile1, availableFile2, availableFile3, nil];

  AVAFile *blockedFile1 =
      [[AVAFile alloc] initWithPath:@"4" fileId:@"4" creationDate:[NSDate dateWithTimeIntervalSinceNow:1]];
  AVAFile *blockedFile2 =
      [[AVAFile alloc] initWithPath:@"5" fileId:@"5" creationDate:[NSDate dateWithTimeIntervalSinceNow:2]];
  AVAFile *blockedFile3 =
      [[AVAFile alloc] initWithPath:@"6" fileId:@"6" creationDate:[NSDate dateWithTimeIntervalSinceNow:3]];
  self.sut.blockedFiles = [NSMutableArray arrayWithObjects:blockedFile1, blockedFile2, blockedFile3, nil];

  // When
  AVAFile *foundAvailableFile = [_sut fileWithId:@"3"];
  AVAFile *foundBlockedFile = [_sut fileWithId:@"5"];

  // Then
  assertThat(foundAvailableFile, equalTo(availableFile3));
  assertThat(foundBlockedFile, equalTo(blockedFile2));
}

- (void)testRequestingUnexisitngFileByIdWillReturnNil {

  // If
  AVAFile *availableFile1 =
      [[AVAFile alloc] initWithPath:@"1" fileId:@"1" creationDate:[NSDate dateWithTimeIntervalSinceNow:1]];
  AVAFile *availableFile2 =
      [[AVAFile alloc] initWithPath:@"2" fileId:@"2" creationDate:[NSDate dateWithTimeIntervalSinceNow:2]];
  AVAFile *availableFile3 =
      [[AVAFile alloc] initWithPath:@"3" fileId:@"3" creationDate:[NSDate dateWithTimeIntervalSinceNow:3]];
  self.sut.availableFiles = [NSMutableArray arrayWithObjects:availableFile1, availableFile2, availableFile3, nil];

  // When
  AVAFile *actual = [_sut fileWithId:@"4"];

  // Then
  assertThat(actual, nilValue());
}

- (void)testRemovingFileRemovesItFromBlockedAndAvailableList {

  // If
  AVAFile *file1 = [[AVAFile alloc] initWithPath:@"1" fileId:@"1" creationDate:[NSDate dateWithTimeIntervalSinceNow:1]];
  AVAFile *file2 = [[AVAFile alloc] initWithPath:@"2" fileId:@"2" creationDate:[NSDate dateWithTimeIntervalSinceNow:2]];
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
