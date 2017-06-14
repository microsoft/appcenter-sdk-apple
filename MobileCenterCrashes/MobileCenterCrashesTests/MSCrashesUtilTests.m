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

  XCTAssertNotNil(crashesDir);
  XCTAssertTrue([crashesDir containsString:@"/Library/Caches/com.test.app/com.microsoft.azure.mobile.mobilecenter/crashes"]);
  BOOL isDir = YES;
  BOOL dirExists = [[NSFileManager defaultManager] fileExistsAtPath:crashesDir isDirectory:&isDir];
  XCTAssertTrue(dirExists);
}

- (void)testCreateLogBufferDir {
  NSString *bufferDir = [[MSCrashesUtil logBufferDir] path];
  XCTAssertNotNil(bufferDir);
  XCTAssertTrue([bufferDir containsString:@"/Library/Caches/com.test.app/com.microsoft.azure.mobile.mobilecenter/crasheslogbuffer"]);
  BOOL isDir = YES;
  BOOL dirExists = [[NSFileManager defaultManager] fileExistsAtPath:bufferDir isDirectory:&isDir];
  XCTAssertTrue(dirExists);
}

@end
