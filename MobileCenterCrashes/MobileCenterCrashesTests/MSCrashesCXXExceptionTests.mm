#import <XCTest/XCTest.h>
#import "MSCrashesCXXExceptionHandler.h"
#import "MSCrashesCXXExceptionWrapperException.h"


static void handler1(__attribute__((unused)) const MSCrashesUncaughtCXXExceptionInfo *__nonnull info) {
}

static void handler2(__attribute__((unused)) const MSCrashesUncaughtCXXExceptionInfo *__nonnull info) {
}

@interface MSCrashesCXXExceptionWrapperException()

@property (readonly,nonatomic) const MSCrashesUncaughtCXXExceptionInfo *info;

@end

@interface MSCrashesCXXExceptionTests : XCTestCase

@end

@implementation MSCrashesCXXExceptionTests

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

- (void)testWrapperExceptionInit {
  MSCrashesUncaughtCXXExceptionInfo info = {
    .exception = nullptr,
    .exception_type_name = nullptr,
    .exception_message = nullptr,
    .exception_frames_count = 0,
    .exception_frames = nullptr,
  };
  MSCrashesCXXExceptionWrapperException *wrapperException = [[MSCrashesCXXExceptionWrapperException alloc] initWithCXXExceptionInfo:&info];
  XCTAssertNotNil(wrapperException);
  XCTAssertEqual(&info, wrapperException.info);
}

@end
