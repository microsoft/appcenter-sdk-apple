#import "MSCrashesUtil.h"
#import "MSCrashesUtilPrivate.h"
#import "MSTestFrameworks.h"

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
  NSString *crashesDir = [[MSCrashesUtil crashesDir] path];
  NSString *expectedDir;
  XCTAssertNotNil(crashesDir);
#if TARGET_OS_OSX
  expectedDir = @"/Library/Caches/com.test.app/com.microsoft.azure.mobile.mobilecenter/crashes";
#else
  expectedDir = @"/Library/Caches/com.microsoft.azure.mobile.mobilecenter/crashes";
#endif
  XCTAssertTrue([crashesDir containsString:expectedDir]);
  BOOL isDir = YES;
  BOOL dirExists = [[NSFileManager defaultManager] fileExistsAtPath:crashesDir isDirectory:&isDir];
  XCTAssertTrue(dirExists);
}

- (void)testCreateLogBufferDir {
  NSString *bufferDir = [[MSCrashesUtil logBufferDir] path];
  NSString *expectedDir;
  XCTAssertNotNil(bufferDir);
#if TARGET_OS_OSX
  expectedDir = @"/Library/Caches/com.test.app/com.microsoft.azure.mobile.mobilecenter/crasheslogbuffer";
#else
  expectedDir = @"/Library/Caches/com.microsoft.azure.mobile.mobilecenter/crasheslogbuffer";
#endif
  XCTAssertTrue([bufferDir containsString:expectedDir]);
  BOOL isDir = YES;
  BOOL dirExists = [[NSFileManager defaultManager] fileExistsAtPath:bufferDir isDirectory:&isDir];
  XCTAssertTrue(dirExists);
}

@end
