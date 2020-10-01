// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACBasicMachOParser.h"
#import "MSACDistributePrivate.h"
#import "MSACDistributeUtil.h"
#import "MSACMockUserDefaults.h"
#import "MSACReleaseDetailsPrivate.h"
#import "MSACTestFrameworks.h"

@interface MSACDistributeUtilTests : XCTestCase

@property(nonatomic) id parserMock;
@property(nonatomic) id settingsMock;

@end

@implementation MSACDistributeUtilTests

- (void)setUp {
  [super setUp];
  self.settingsMock = [MSACMockUserDefaults new];
}

- (void)tearDown {
  [super tearDown];
  [self.settingsMock stopMocking];
}

- (void)testGetMainBundle {

  // When
  NSBundle *bundle = MSACDistributeBundle();

  // Then
  XCTAssertNotNil(bundle);
}

- (void)testLocalizedString {

  // When
  NSString *test = MSACDistributeLocalizedString(@"");

  // Then
  XCTAssertTrue([test isEqualToString:@""]);

  // When
  test = MSACDistributeLocalizedString(nil);

  // Then
  XCTAssertTrue([test isEqualToString:@""]);

  // When
  test = MSACDistributeLocalizedString(@"NonExistentString");

  // Then
  XCTAssertTrue([test isEqualToString:@"NonExistentString"]);

  // When
  test = MSACDistributeLocalizedString(@"Ignore");

  // Then
  XCTAssertTrue([test isEqualToString:@"Ignore"]);
}

- (void)testCompareReleaseSameVersion {

  // If
  // Mock current UUID.
  NSString *testUUID = @"CD55E7A9-7AD1-4CA6-B722-3D133F487DA9";
  id parserMock = OCMClassMock([MSACBasicMachOParser class]);
  OCMStub([parserMock machOParserForMainBundle]).andReturn(parserMock);
  OCMStub([parserMock uuid]).andReturn([[NSUUID alloc] initWithUUIDString:testUUID]);

  // Mock current versions.
  NSString *expectedShortVer = @"2.5.3-alpha+EF69A";
  NSString *expectedVersion = @"2.5.3.1";
  NSDictionary<NSString *, id> *plist = @{@"CFBundleShortVersionString" : expectedShortVer, @"CFBundleVersion" : expectedVersion};
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);
  OCMStub([bundleMock infoDictionary]).andReturn(plist);

  // Define release details.
  MSACReleaseDetails *details = [MSACReleaseDetails new];
  details.shortVersion = expectedShortVer;
  details.version = expectedVersion;
  details.packageHashes = @[ @"a965a640740e37f8f21bb8ea232048a5984293cec32c36ea77cf19a030c8e5f2" ];

  // When
  NSComparisonResult result = MSACCompareCurrentReleaseWithRelease(details);

  // Then
  assertThatInt(result, equalToInt(NSOrderedSame));
  [bundleMock stopMocking];
  [parserMock stopMocking];
}

- (void)testCompareReleaseDifferentPackageHashes {

  // If
  // Mock current UUID.
  id parserMock = OCMClassMock([MSACBasicMachOParser class]);
  OCMStub([parserMock machOParserForMainBundle]).andReturn(parserMock);
  OCMStub([parserMock uuid]).andReturn([[NSUUID alloc] initWithUUIDString:@"CD55E7A9-7AD1-4CA6-B722-3D133F487DA9"]);

  // Mock current versions.
  NSString *expectedShortVer = @"2.5.3-alpha+EF69A";
  NSString *expectedVersion = @"2.5.3.1";
  NSDictionary<NSString *, id> *plist = @{@"CFBundleShortVersionString" : expectedShortVer, @"CFBundleVersion" : expectedVersion};
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);
  OCMStub([bundleMock infoDictionary]).andReturn(plist);

  // Define release details.
  MSACReleaseDetails *details = [MSACReleaseDetails new];
  details.shortVersion = expectedShortVer;
  details.version = expectedVersion;
  details.packageHashes = @[ @"Something different package hash" ];

  // When
  NSComparisonResult result = MSACCompareCurrentReleaseWithRelease(details);

  // Then
  assertThatInt(result, equalToInt(NSOrderedAscending));
  [bundleMock stopMocking];
  [parserMock stopMocking];
}

- (void)testCompareReleaseCurrentReleaseNotSemVer {

  // If
  // Mock current versions.
  NSString *expectedShortVer = @"not semantic versioning";
  NSDictionary<NSString *, id> *plist = @{@"CFBundleShortVersionString" : expectedShortVer};
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);
  OCMStub([bundleMock infoDictionary]).andReturn(plist);

  // Define release details.
  MSACReleaseDetails *details = [MSACReleaseDetails new];
  details.shortVersion = @"2.5.3-alpha+EF69A";

  // When
  NSComparisonResult result = MSACCompareCurrentReleaseWithRelease(details);

  // Then
  assertThatInt(result, equalToInt(NSOrderedAscending));
  [bundleMock stopMocking];
}

- (void)testCompareReleaseTestedReleaseNotSemVer {

  // If
  // Mock current versions.
  NSString *expectedShortVer = @"2.5.3-alpha+EF69A";
  NSDictionary<NSString *, id> *plist = @{@"CFBundleShortVersionString" : expectedShortVer};
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);
  OCMStub([bundleMock infoDictionary]).andReturn(plist);

  // Define release details.
  MSACReleaseDetails *details = [MSACReleaseDetails new];
  details.shortVersion = @"not semantic versioning";

  // When
  NSComparisonResult result = MSACCompareCurrentReleaseWithRelease(details);

  // Then
  assertThatInt(result, equalToInt(NSOrderedDescending));
  [bundleMock stopMocking];
}

- (void)testCompareReleaseNoneSemVerButDifferentPackageHashes {

  // If
  // Mock current UUID.
  id parserMock = OCMClassMock([MSACBasicMachOParser class]);
  OCMStub([parserMock machOParserForMainBundle]).andReturn(parserMock);
  OCMStub([parserMock uuid]).andReturn([[NSUUID alloc] initWithUUIDString:@"CD55E7A9-7AD1-4CA6-B722-3D133F487DA9"]);

  // Mock current versions.
  NSString *expectedVersion = @"2.5.3.1";
  NSDictionary<NSString *, id> *plist = @{@"CFBundleShortVersionString" : @"not semantic versioning", @"CFBundleVersion" : expectedVersion};
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);
  OCMStub([bundleMock infoDictionary]).andReturn(plist);

  // Define release details.
  MSACReleaseDetails *details = [MSACReleaseDetails new];
  details.shortVersion = @" still different but not semantic versioning";
  details.version = expectedVersion;
  details.packageHashes = @[ @"Something different package hash" ];

  // When
  NSComparisonResult result = MSACCompareCurrentReleaseWithRelease(details);

  // Then
  assertThatInt(result, equalToInt(NSOrderedAscending));
  [bundleMock stopMocking];
  [parserMock stopMocking];
}

- (void)testCompareReleaseNoneSemVerButSamePackageHashes {

  // If
  // Mock current UUID.
  NSString *testUUID = @"CD55E7A9-7AD1-4CA6-B722-3D133F487DA9";
  id parserMock = OCMClassMock([MSACBasicMachOParser class]);
  OCMStub([parserMock machOParserForMainBundle]).andReturn(parserMock);
  OCMStub([parserMock uuid]).andReturn([[NSUUID alloc] initWithUUIDString:testUUID]);

  // Mock current versions.
  NSString *expectedVersion = @"2.5.3.1";
  NSDictionary<NSString *, id> *plist = @{@"CFBundleShortVersionString" : @"not semantic versioning", @"CFBundleVersion" : expectedVersion};
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);
  OCMStub([bundleMock infoDictionary]).andReturn(plist);

  // Define release details.
  MSACReleaseDetails *details = [MSACReleaseDetails new];
  details.shortVersion = @" still different but not semantic versioning";
  details.version = expectedVersion;
  details.packageHashes = @[ MSACPackageHash() ];

  // When
  NSComparisonResult result = MSACCompareCurrentReleaseWithRelease(details);

  // Then
  assertThatInt(result, equalToInt(NSOrderedSame));
  [bundleMock stopMocking];
  [parserMock stopMocking];
}

- (void)testCompareReleaseSameShortVersionsDifferentVersions {

  // If
  // Mock current UUID.
  NSString *testUUID = @"CD55E7A9-7AD1-4CA6-B722-3D133F487DA9";
  id parserMock = OCMClassMock([MSACBasicMachOParser class]);
  OCMStub([parserMock machOParserForMainBundle]).andReturn(parserMock);
  OCMStub([parserMock uuid]).andReturn([[NSUUID alloc] initWithUUIDString:testUUID]);

  // Mock current versions.
  NSString *expectedShortVer = @"2.5.3-alpha+EF69A";
  NSDictionary<NSString *, id> *plist = @{@"CFBundleShortVersionString" : expectedShortVer, @"CFBundleVersion" : @"2.5.3.1"};
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);
  OCMStub([bundleMock infoDictionary]).andReturn(plist);

  // Define release details.
  MSACReleaseDetails *details = [MSACReleaseDetails new];
  details.shortVersion = expectedShortVer;
  details.version = @"2.5.3.2";
  details.packageHashes = @[ MSACPackageHash() ];

  // When
  NSComparisonResult result = MSACCompareCurrentReleaseWithRelease(details);

  // Then
  assertThatInt(result, equalToInt(NSOrderedAscending));
  [bundleMock stopMocking];
  [parserMock stopMocking];
}

@end
