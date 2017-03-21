#import <XCTest/XCTest.h>
#import "MSCrashesCXXExceptionHandler.h"


static void handler1(__attribute__((unused)) const MSCrashesUncaughtCXXExceptionInfo *__nonnull info) {
}

static void handler2(__attribute__((unused)) const MSCrashesUncaughtCXXExceptionInfo *__nonnull info) {
}

@interface MSCrashesCXXExceptionHandlerTests : XCTestCase

@end

@implementation MSCrashesCXXExceptionHandlerTests

- (void)testHandlersCount {
  XCTAssertEqual([MSCrashesUncaughtCXXExceptionHandlerManager countCXXExceptionHandler], 0U);
  [MSCrashesUncaughtCXXExceptionHandlerManager addCXXExceptionHandler:handler1];
  XCTAssertEqual([MSCrashesUncaughtCXXExceptionHandlerManager countCXXExceptionHandler], 1U);
  [MSCrashesUncaughtCXXExceptionHandlerManager addCXXExceptionHandler:handler2];
  XCTAssertEqual([MSCrashesUncaughtCXXExceptionHandlerManager countCXXExceptionHandler], 2U);
  [MSCrashesUncaughtCXXExceptionHandlerManager removeCXXExceptionHandler:handler1];
  XCTAssertEqual([MSCrashesUncaughtCXXExceptionHandlerManager countCXXExceptionHandler], 1U);
  [MSCrashesUncaughtCXXExceptionHandlerManager removeCXXExceptionHandler:handler1];
  XCTAssertEqual([MSCrashesUncaughtCXXExceptionHandlerManager countCXXExceptionHandler], 1U);
  [MSCrashesUncaughtCXXExceptionHandlerManager removeCXXExceptionHandler:handler2];
  XCTAssertEqual([MSCrashesUncaughtCXXExceptionHandlerManager countCXXExceptionHandler], 0U);
  [MSCrashesUncaughtCXXExceptionHandlerManager removeCXXExceptionHandler:handler2];
}

@end
