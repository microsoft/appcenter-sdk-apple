// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSCrashesUtil.h"
#import "MSCrashesUtilPrivate.h"
#import "MSTestFrameworks.h"
#import "MSUtility+File.h"

@interface MSCrashesUtilTests : XCTestCase

@property(nonatomic) id bundleMock;

@end

@implementation MSCrashesUtilTests

#pragma mark - Housekeeping

- (void)setUp {
  [super setUp];
  self.bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([self.bundleMock mainBundle]).andReturn(self.bundleMock);
  OCMStub([self.bundleMock bundleIdentifier]).andReturn(@"com.test.app");
  [MSCrashesUtil resetDirectory];
}

- (void)tearDown {
  [self.bundleMock stopMocking];
  [MSCrashesUtil resetDirectory];
  [super tearDown];
}

#pragma mark - Tests

- (void)testCreateCrashesDir {

  // If
  NSString *expectedDir;
#if TARGET_OS_TV
  expectedDir = @"/Library/Caches/com.microsoft.appcenter/crashes";
#else
#if TARGET_OS_OSX || TARGET_OS_MACCATALYST
  expectedDir = [self getPathWithBundleIdentifier:@"/Library/Application%%20Support/%@/com.microsoft.appcenter/crashes"];
#else
  expectedDir = @"/Library/Application%20Support/com.microsoft.appcenter/crashes";
#endif
#endif

  // When
  [MSCrashesUtil crashesDir];

  // Then
  NSString *crashesDir = [[MSUtility fullURLForPathComponent:kMSCrashesDirectory] absoluteString];
  XCTAssertNotNil(crashesDir);
  XCTAssertTrue([crashesDir rangeOfString:expectedDir].location != NSNotFound);
  BOOL dirExists = [MSUtility fileExistsForPathComponent:kMSCrashesDirectory];
  XCTAssertTrue(dirExists);
}

- (void)testCreateLogBufferDir {

  // If
  NSString *expectedDir;
#if TARGET_OS_TV
  expectedDir = @"/Library/Caches/com.microsoft.appcenter/crasheslogbuffer";
#else
#if TARGET_OS_OSX || TARGET_OS_MACCATALYST
  expectedDir =  [self getPathWithBundleIdentifier:@"/Library/Application%%20Support/%@/com.microsoft.appcenter/crasheslogbuffer"];
#else
  expectedDir = @"/Library/Application%20Support/com.microsoft.appcenter/crasheslogbuffer";
#endif
#endif

  // When
  [MSCrashesUtil logBufferDir];

  // Then
  NSString *bufferDir = [[MSUtility fullURLForPathComponent:@"crasheslogbuffer"] absoluteString];
  XCTAssertNotNil(bufferDir);
  XCTAssertTrue([bufferDir rangeOfString:expectedDir].location != NSNotFound);
  BOOL dirExists = [MSUtility fileExistsForPathComponent:@"crasheslogbuffer"];
  XCTAssertTrue(dirExists);
}

- (void)testCreateWrapperExceptionDir {

  // If
  NSString *expectedDir;
#if TARGET_OS_TV
  expectedDir = @"/Library/Caches/com.microsoft.appcenter/crasheswrapperexceptions";
#else
#if TARGET_OS_OSX || TARGET_OS_MACCATALYST
  expectedDir =  [self getPathWithBundleIdentifier:@"/Library/Application%%20Support/%@/com.microsoft.appcenter/crasheswrapperexceptions"];
#else
  expectedDir = @"/Library/Application%20Support/com.microsoft.appcenter/crasheswrapperexceptions";
#endif
#endif

  // When
  [MSCrashesUtil wrapperExceptionsDir];

  // Then
  NSString *crashesWrapperExceptionDir = [[MSUtility fullURLForPathComponent:kMSWrapperExceptionsDirectory] absoluteString];
  XCTAssertNotNil(crashesWrapperExceptionDir);
  XCTAssertTrue([crashesWrapperExceptionDir rangeOfString:expectedDir].location != NSNotFound);
  BOOL dirExists = [MSUtility fileExistsForPathComponent:kMSWrapperExceptionsDirectory];
  XCTAssertTrue(dirExists);
}

// Before SDK 12.2 (bundled with Xcode 10.*) when running in a unit test bundle the bundle identifier is null.
// 12.2 and after the above bundle identifier is com.apple.dt.xctest.tool.
- (NSString *)getPathWithBundleIdentifier:(NSString *)path {
    NSString* bundleId;
#if ((defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 120200) || \
    (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 101404))
    bundleId = @"com.apple.dt.xctest.tool";
#else
    bundleId = @"(null)";
#endif
    return [NSString stringWithFormat:path, bundleId];
}

@end
