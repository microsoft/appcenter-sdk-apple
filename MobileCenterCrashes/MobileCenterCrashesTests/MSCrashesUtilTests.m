#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "MSCrashesUtil.h"

@interface MSCrashesUtilTests : XCTestCase

@end

@implementation MSCrashesUtilTests

#pragma mark - Housekeeping

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - Tests

- (void)testCreateCrashesDir {
  NSString *crashesDir = [[MSCrashesUtil crashesDir] path];
  XCTAssertNotNil(crashesDir);
  XCTAssertTrue([crashesDir containsString:@"data/Library/Caches/com.microsoft.azure.mobile.mobilecenter/crashes"]);
  BOOL isDir = YES;
  BOOL dirExists = [[NSFileManager defaultManager] fileExistsAtPath:crashesDir isDirectory:&isDir];
  XCTAssertTrue(dirExists);
}

- (void)testCreateLogBufferDir {
  NSString *bufferDir = [[MSCrashesUtil logBufferDir] path];
  XCTAssertNotNil(bufferDir);
  XCTAssertTrue(
      [bufferDir containsString:@"data/Library/Caches/com.microsoft.azure.mobile.mobilecenter/crasheslogbuffer"]);
  BOOL isDir = YES;
  BOOL dirExists = [[NSFileManager defaultManager] fileExistsAtPath:bufferDir isDirectory:&isDir];
  XCTAssertTrue(dirExists);
}

@end
