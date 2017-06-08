#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSAbstractLog.h"
#import "MSDBStoragePrivate.h"
#import "MSDatabaseConnection.h"

static NSString *const kMSTestGroupId = @"TestGroupId";

@interface MSDBStorageTests : XCTestCase

@property(nonatomic) MSDBStorage *sut;
@property(nonatomic) id<MSDatabaseConnection> dbConnectionMock;

@end

@implementation MSDBStorageTests

#pragma mark - Setup
- (void)setUp {
  [super setUp];
  self.sut = [MSDBStorage new];
  self.dbConnectionMock = OCMProtocolMock(@protocol(MSDatabaseConnection));
  self.sut.connection = self.dbConnectionMock;
}

- (void)testLoadTooManyLogs {

  // If
  NSUInteger expectedLogsCount = 5;
  OCMStub([self.dbConnectionMock loadDataFromDB:[OCMArg any]])
      .andReturn([self generateSerializedLogsWithCount:expectedLogsCount + 1]);

  // When
  BOOL moreLogsAvailable =
      [self.sut loadLogsWithGroupId:kMSTestGroupId
                              limit:expectedLogsCount
                     withCompletion:^(NSArray<MSLog> *_Nonnull logArray, NSString *_Nonnull batchId) {

                       // Then
                       assertThat(batchId, notNilValue());
                       XCTAssertTrue(expectedLogsCount == logArray.count);
                     }];
  XCTAssertTrue(moreLogsAvailable);
}

- (void)testLoadJustEnoughLogs {

  // If
  NSUInteger expectedLogsCount = 5;
  OCMStub([self.dbConnectionMock loadDataFromDB:[OCMArg any]])
      .andReturn([self generateSerializedLogsWithCount:expectedLogsCount]);

  // When
  BOOL moreLogsAvailable =
      [self.sut loadLogsWithGroupId:kMSTestGroupId
                              limit:expectedLogsCount
                     withCompletion:^(NSArray<MSLog> *_Nonnull logArray, NSString *_Nonnull batchId) {

                       // Then
                       assertThat(batchId, notNilValue());
                       XCTAssertTrue(expectedLogsCount == logArray.count);
                     }];
  XCTAssertFalse(moreLogsAvailable);
}

- (void)testLoadNotEnoughLogs {

  // If
  NSUInteger expectedLogsCount = 2;
  NSUInteger limit = 5;
  OCMStub([self.dbConnectionMock loadDataFromDB:[OCMArg any]])
      .andReturn([self generateSerializedLogsWithCount:expectedLogsCount]);

  // When
  BOOL moreLogsAvailable =
      [self.sut loadLogsWithGroupId:kMSTestGroupId
                              limit:limit
                     withCompletion:^(NSArray<MSLog> *_Nonnull logArray, NSString *_Nonnull batchId) {

                       // Then
                       assertThat(batchId, notNilValue());
                       XCTAssertTrue(expectedLogsCount == logArray.count);
                     }];
  XCTAssertFalse(moreLogsAvailable);
}

- (void)testLoadUnlimitedLogs {

  // If
  NSUInteger expectedLogsCount = 42;
  OCMStub([self.dbConnectionMock loadDataFromDB:[OCMArg any]])
      .andReturn([self generateSerializedLogsWithCount:expectedLogsCount]);

  // When
  NSDictionary<NSString *, id<MSLog>> *logs = [self.sut getLogsFromDBWithGroupId:kMSTestGroupId];

  // Then
  XCTAssertTrue(expectedLogsCount == logs.count);
}

- (NSArray<NSArray<NSString *> *> *)generateSerializedLogsWithCount:(NSUInteger)count {
  NSMutableArray<NSArray<NSString *> *> *logs = [NSMutableArray arrayWithCapacity:count];
  for (NSUInteger i = 0; i < count; ++i) {
    NSData *logData = [NSKeyedArchiver archivedDataWithRootObject:[MSAbstractLog new]];
    NSString *base64Data = [logData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    [logs addObject:@[ [@(i) stringValue], kMSTestGroupId, base64Data ]];
  }
  return logs;
}

@end
