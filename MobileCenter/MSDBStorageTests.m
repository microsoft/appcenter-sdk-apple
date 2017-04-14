#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "MSAbstractLog.h"
#import "MSDBStorage.h"

@interface MSDBStorageTests : XCTestCase

@property (nonatomic) MSDBStorage *sut;

@end

@implementation MSDBStorageTests

#pragma mark - Setup
- (void)setUp {
  [super setUp];
  self.sut = [MSDBStorage new];
}

- (void)testLoadTooManyLogs {

  // If
  id partialMock = OCMPartialMock(self.sut);
  OCMStub([partialMock bucketFileLogCountLimit]).andReturn(50);
  OCMStub([partialMock getLogsWith:[OCMArg any]]).andReturn([self generateLogs:self.sut.bucketFileLogCountLimit]);

  // When
  [self.sut loadLogsForGroupID:@"" withCompletion:^(BOOL succeeded, NSArray<MSLog> *_Nonnull logArray, __attribute__((unused)) NSString *_Nonnull batchId) {

    // Then
    XCTAssertTrue(succeeded);
    XCTAssertTrue(self.sut.bucketFileLogCountLimit == logArray.count);
  }];
}

- (NSArray*)generateLogs:(NSUInteger)maxCountLogs  {
  NSUInteger totalLogs = maxCountLogs * 2;
  NSMutableArray *logs = [NSMutableArray arrayWithCapacity:totalLogs];
  for (NSUInteger i = 0; i < totalLogs; ++i) {
    [logs addObject:[MSAbstractLog new]];
  }
  return logs;
}

@end
