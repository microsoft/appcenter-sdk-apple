#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <XCTest/XCTest.h>

#import "MSFile.h"

@interface MSFileTests : XCTestCase

@property(nonatomic) MSFile *sut;
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
  NSURL *fileURL = [NSURL fileURLWithPath:@"/Some/Path/To/File"];
  NSDate *creationDate = [NSDate dateWithTimeIntervalSinceNow:18];

  // When
  _sut = [[MSFile alloc] initWithURL:fileURL fileId:fileId creationDate:creationDate];

  // Then
  assertThat(_sut, notNilValue());
  assertThat(_sut.fileId, equalTo(fileId));
  assertThat(_sut.fileURL, equalTo(fileURL));
  assertThat(_sut.creationDate, equalTo(creationDate));
}

@end
