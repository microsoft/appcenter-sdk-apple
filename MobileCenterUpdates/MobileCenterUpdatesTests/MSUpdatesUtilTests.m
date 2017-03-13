#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSBasicMachOParser.h"
#import "MSUpdatesUtil.h"

@interface MobileCenterUpdatesTests : XCTestCase

@end

@implementation MobileCenterUpdatesTests

- (void)testGetMainBundle {

  // When.
  NSBundle *bundle = MSUpdatesBundle();

  // Then.
  XCTAssertNotNil(bundle);
}

- (void)testLocalizedString {

  // When.
  NSString *test = MSUpdatesLocalizedString(@"");

  // Then.
  XCTAssertTrue([test isEqualToString:@""]);

  // When.
  test = MSUpdatesLocalizedString(@"NonExistendString");

  // Then.
  XCTAssertTrue([test isEqualToString:@"NonExistendString"]);

  // When.
  test = MSUpdatesLocalizedString(@"Working");

  // Then.
  XCTAssertTrue([test isEqualToString:@"Yes, this works!"]);
}

- (void)testCompareReleaseSameVersion {

  /**
   * If.
   */

  // Mock current UUID.
  NSString *testUUID = @"CD55E7A9-7AD1-4CA6-B722-3D133F487DA9";
  id parserMock = OCMClassMock([MSBasicMachOParser class]);
  OCMStub([parserMock machOParserForMainBundle]).andReturn(parserMock);
  OCMStub([parserMock uuid]).andReturn([[NSUUID alloc] initWithUUIDString:testUUID]);

  // Mock current versions.
  NSString *expectedShortVer = @"2.5.3-alpha+EF69A";
  NSString *expectedVersion = @"2.5.3.1";
  NSDictionary<NSString *, id> *plist = @{
    @"CFBundleShortVersionString" : expectedShortVer,
    @"CFBundleVersion" : expectedVersion
  };
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);
  OCMStub([bundleMock infoDictionary]).andReturn(plist);

  // Define release details.
  MSReleaseDetails *details = [MSReleaseDetails new];
  details.shortVersion = expectedShortVer;
  details.version = expectedVersion;
  details.packageHashes = @[ [testUUID lowercaseString] ];

  /**
   * When
   */
  NSComparisonResult result = MSCompareCurrentReleaseWithRelease(details);

  /**
   * Then
   */
  assertThatInt(result, equalToInt(NSOrderedSame));
  [bundleMock stopMocking];
  [parserMock stopMocking];
}

- (void)testCompareReleaseDifferentBuildUUIDs {

  /**
   * If.
   */

  // Mock current UUID.
  id parserMock = OCMClassMock([MSBasicMachOParser class]);
  OCMStub([parserMock machOParserForMainBundle]).andReturn(parserMock);
  OCMStub([parserMock uuid]).andReturn([[NSUUID alloc] initWithUUIDString:@"CD55E7A9-7AD1-4CA6-B722-3D133F487DA9"]);

  // Mock current versions.
  NSString *expectedShortVer = @"2.5.3-alpha+EF69A";
  NSString *expectedVersion = @"2.5.3.1";
  NSDictionary<NSString *, id> *plist = @{
    @"CFBundleShortVersionString" : expectedShortVer,
    @"CFBundleVersion" : expectedVersion
  };
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);
  OCMStub([bundleMock infoDictionary]).andReturn(plist);

  // Define release details.
  MSReleaseDetails *details = [MSReleaseDetails new];
  details.shortVersion = expectedShortVer;
  details.version = expectedVersion;
  details.packageHashes = @[ @"4255f7a9-2ed1-35a6-b831-3d144e473ce9" ];

  /**
   * When
   */
  NSComparisonResult result = MSCompareCurrentReleaseWithRelease(details);

  /**
   * Then
   */
  assertThatInt(result, equalToInt(NSOrderedAscending));
  [bundleMock stopMocking];
  [parserMock stopMocking];
}

- (void)testCompareReleaseCurrentReleaseNotSemVer {

  /**
   * If.
   */

  // Mock current versions.
  NSString *expectedShortVer = @"not sementic versioning";
  NSDictionary<NSString *, id> *plist = @{ @"CFBundleShortVersionString" : expectedShortVer };
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);
  OCMStub([bundleMock infoDictionary]).andReturn(plist);

  // Define release details.
  MSReleaseDetails *details = [MSReleaseDetails new];
  details.shortVersion = @"2.5.3-alpha+EF69A";

  /**
   * When
   */
  NSComparisonResult result = MSCompareCurrentReleaseWithRelease(details);

  /**
   * Then
   */
  assertThatInt(result, equalToInt(NSOrderedAscending));
  [bundleMock stopMocking];
}

- (void)testCompareReleaseTestedReleaseNotSemVer {

  /**
   * If.
   */

  // Mock current versions.
  NSString *expectedShortVer = @"2.5.3-alpha+EF69A";
  NSDictionary<NSString *, id> *plist = @{ @"CFBundleShortVersionString" : expectedShortVer };
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);
  OCMStub([bundleMock infoDictionary]).andReturn(plist);

  // Define release details.
  MSReleaseDetails *details = [MSReleaseDetails new];
  details.shortVersion = @"not sementic versioning";

  /**
   * When
   */
  NSComparisonResult result = MSCompareCurrentReleaseWithRelease(details);

  /**
   * Then
   */
  assertThatInt(result, equalToInt(NSOrderedDescending));
  [bundleMock stopMocking];
}

- (void)testCompareReleaseNoneSemVerButDifferentBuildUUIDs {

  /**
   * If.
   */

  // Mock current UUID.
  id parserMock = OCMClassMock([MSBasicMachOParser class]);
  OCMStub([parserMock machOParserForMainBundle]).andReturn(parserMock);
  OCMStub([parserMock uuid]).andReturn([[NSUUID alloc] initWithUUIDString:@"CD55E7A9-7AD1-4CA6-B722-3D133F487DA9"]);

  // Mock current versions.
  NSString *expectedVersion = @"2.5.3.1";
  NSDictionary<NSString *, id> *plist = @{
    @"CFBundleShortVersionString" : @"not sementic versioning",
    @"CFBundleVersion" : expectedVersion
  };
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);
  OCMStub([bundleMock infoDictionary]).andReturn(plist);

  // Define release details.
  MSReleaseDetails *details = [MSReleaseDetails new];
  details.shortVersion = @" still different but not sementic versioning";
  details.version = expectedVersion;
  details.packageHashes = @[ @"4255f7a9-2ed1-35a6-b831-3d144e473ce9" ];

  /**
   * When
   */
  NSComparisonResult result = MSCompareCurrentReleaseWithRelease(details);

  /**
   * Then
   */
  assertThatInt(result, equalToInt(NSOrderedAscending));
  [bundleMock stopMocking];
  [parserMock stopMocking];
}

- (void)testCompareReleaseNoneSemVerButSameBuildUUIDs {

  /**
   * If.
   */

  // Mock current UUID.
  NSString *testUUID = @"CD55E7A9-7AD1-4CA6-B722-3D133F487DA9";
  id parserMock = OCMClassMock([MSBasicMachOParser class]);
  OCMStub([parserMock machOParserForMainBundle]).andReturn(parserMock);
  OCMStub([parserMock uuid]).andReturn([[NSUUID alloc] initWithUUIDString:testUUID]);

  // Mock current versions.
  NSString *expectedVersion = @"2.5.3.1";
  NSDictionary<NSString *, id> *plist = @{
    @"CFBundleShortVersionString" : @"not sementic versioning",
    @"CFBundleVersion" : expectedVersion
  };
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);
  OCMStub([bundleMock infoDictionary]).andReturn(plist);

  // Define release details.
  MSReleaseDetails *details = [MSReleaseDetails new];
  details.shortVersion = @" still different but not sementic versioning";
  details.version = expectedVersion;
  details.packageHashes = @[ [testUUID lowercaseString] ];

  /**
   * When
   */
  NSComparisonResult result = MSCompareCurrentReleaseWithRelease(details);

  /**
   * Then
   */
  assertThatInt(result, equalToInt(NSOrderedSame));
  [bundleMock stopMocking];
  [parserMock stopMocking];
}

- (void)testCompareReleaseSameShortVersionsDifferentVersions {

  /**
   * If.
   */

  // Mock current UUID.
  NSString *testUUID = @"CD55E7A9-7AD1-4CA6-B722-3D133F487DA9";
  id parserMock = OCMClassMock([MSBasicMachOParser class]);
  OCMStub([parserMock machOParserForMainBundle]).andReturn(parserMock);
  OCMStub([parserMock uuid]).andReturn([[NSUUID alloc] initWithUUIDString:testUUID]);

  // Mock current versions.
  NSString *expectedShortVer = @"2.5.3-alpha+EF69A";
  NSDictionary<NSString *, id> *plist = @{
    @"CFBundleShortVersionString" : expectedShortVer,
    @"CFBundleVersion" : @"2.5.3.1"
  };
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);
  OCMStub([bundleMock infoDictionary]).andReturn(plist);

  // Define release details.
  MSReleaseDetails *details = [MSReleaseDetails new];
  details.shortVersion = expectedShortVer;
  details.version = @"2.5.3.2";
  details.packageHashes = @[ [testUUID lowercaseString] ];

  /**
   * When
   */
  NSComparisonResult result = MSCompareCurrentReleaseWithRelease(details);

  /**
   * Then
   */
  assertThatInt(result, equalToInt(NSOrderedAscending));
  [bundleMock stopMocking];
  [parserMock stopMocking];
}

@end
