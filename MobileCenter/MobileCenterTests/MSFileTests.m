@import Foundation;
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
@import XCTest;

#import "MSFile.h"

@interface MSFileTests : XCTestCase

@property(nonatomic, strong) MSFile *sut;
@end

@implementation MSFileTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
  _sut = [MSFile new];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - Tests

- (void)testNewInstanceWasInitialisedCorrectly {

  // If
  NSString *fileId = @"12345";
  NSString *filePath = @"/Some/Path/To/File";
  NSDate *creationDate = [NSDate dateWithTimeIntervalSinceNow:18];

  // When
  _sut = [[MSFile alloc] initWithPath:filePath fileId:fileId creationDate:creationDate];

  // Then
  assertThat(_sut, notNilValue());
  assertThat(_sut.fileId, equalTo(fileId));
  assertThat(_sut.filePath, equalTo(filePath));
  assertThat(_sut.creationDate, equalTo(creationDate));
}

@end
