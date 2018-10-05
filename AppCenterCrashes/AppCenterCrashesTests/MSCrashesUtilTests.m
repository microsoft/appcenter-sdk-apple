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
#if TARGET_OS_OSX
  expectedDir = @"/Library/Application%20Support/(null)/com.microsoft.appcenter/crashes";
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
#if TARGET_OS_OSX
  expectedDir = @"/Library/Application%20Support/(null)/com.microsoft.appcenter/crasheslogbuffer";
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
#if TARGET_OS_OSX
  expectedDir = @"/Library/Application%20Support/(null)/com.microsoft.appcenter/crasheswrapperexceptions";
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

@end
