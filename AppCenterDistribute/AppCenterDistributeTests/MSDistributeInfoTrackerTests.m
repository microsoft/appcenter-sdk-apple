#import "MSAbstractLog.h"
#import "MSDistributeInfoTracker.h"
#import "MSTestFrameworks.h"

@interface MSDistributeInfoTrackerTests : XCTestCase

@property (nonatomic) MSDistributeInfoTracker *sut;

@end

@implementation MSDistributeInfoTrackerTests

- (void)setUp {
  [super setUp];
  self.sut = [[MSDistributeInfoTracker alloc] init];
}

- (void)testAddDistributionGroupIdToLogs {
  // If
  NSString *expectedDistributionGroupId = @"GROUP-ID";
  MSAbstractLog *log = [MSAbstractLog new];

  // When
  [self.sut updateDistributionGroupId:expectedDistributionGroupId];
  [self.sut onEnqueuingLog:log withInternalId:nil];

  // Then
  XCTAssertEqual(log.distributionGroupId, expectedDistributionGroupId);
}

- (void)testSetNewDistributionGroupId {

  // If
  MSAbstractLog *log1 = [MSAbstractLog new];

  // When
  [self.sut onEnqueuingLog:log1 withInternalId:nil];

  // Then
  XCTAssertNil(log1.distributionGroupId);

  // If
  NSString *expectedDistributionGroupId = @"GROUP-ID";
  MSAbstractLog *log2 = [MSAbstractLog new];

  // When
  [self.sut updateDistributionGroupId:expectedDistributionGroupId];
  [self.sut onEnqueuingLog:log2 withInternalId:nil];

  // Then
  XCTAssertEqual(log2.distributionGroupId, expectedDistributionGroupId);

  // If
  MSAbstractLog *log3 = [MSAbstractLog new];

  // When
  [self.sut removeDistributionGroupId];
  [self.sut onEnqueuingLog:log3 withInternalId:nil];

  // Then
  XCTAssertNil(log3.distributionGroupId);
}

@end
