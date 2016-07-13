#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "AVAFile.h"

@interface AVAFileTests : XCTestCase

@property(nonatomic, strong) AVAFile *sut;
@end

@implementation AVAFileTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
  _sut = [AVAFile new];
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
  _sut = [[AVAFile alloc] initWithPath:filePath
                                fileId:fileId
                          creationDate:creationDate];

  // Then
  assertThat(_sut, notNilValue());
  assertThat(_sut.fileId, equalTo(fileId));
  assertThat(_sut.filePath, equalTo(filePath));
  assertThat(_sut.creationDate, equalTo(creationDate));
}

@end
