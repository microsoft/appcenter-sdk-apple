#import <XCTest/XCTest.h>

#import "MSCrashesCXXExceptionHandler.h"
#import "MSCrashesCXXExceptionWrapperException.h"

static void handler1(__attribute__((unused)) const MSCrashesUncaughtCXXExceptionInfo *__nonnull info) {}

static void handler2(__attribute__((unused)) const MSCrashesUncaughtCXXExceptionInfo *__nonnull info) {}

@interface MSCrashesCXXExceptionWrapperException ()

@property(readonly, nonatomic) const MSCrashesUncaughtCXXExceptionInfo *info;

- (NSArray *)callStackReturnAddresses;

@end

@interface MSCrashesCXXExceptionTests : XCTestCase

@end

@implementation MSCrashesCXXExceptionTests

- (void)testHandlersCount {
  // Then
  XCTAssertEqual([MSCrashesUncaughtCXXExceptionHandlerManager countCXXExceptionHandler], 0U);

  // When
  [MSCrashesUncaughtCXXExceptionHandlerManager addCXXExceptionHandler:handler1];

  // Then
  XCTAssertEqual([MSCrashesUncaughtCXXExceptionHandlerManager countCXXExceptionHandler], 1U);

  // When
  [MSCrashesUncaughtCXXExceptionHandlerManager addCXXExceptionHandler:handler2];

  // Then
  XCTAssertEqual([MSCrashesUncaughtCXXExceptionHandlerManager countCXXExceptionHandler], 2U);

  // When
  [MSCrashesUncaughtCXXExceptionHandlerManager removeCXXExceptionHandler:handler1];

  // Then
  XCTAssertEqual([MSCrashesUncaughtCXXExceptionHandlerManager countCXXExceptionHandler], 1U);

  // When
  [MSCrashesUncaughtCXXExceptionHandlerManager removeCXXExceptionHandler:handler1];

  // Then
  XCTAssertEqual([MSCrashesUncaughtCXXExceptionHandlerManager countCXXExceptionHandler], 1U);

  // When
  [MSCrashesUncaughtCXXExceptionHandlerManager removeCXXExceptionHandler:handler2];

  // Then
  XCTAssertEqual([MSCrashesUncaughtCXXExceptionHandlerManager countCXXExceptionHandler], 0U);

  // When
  [MSCrashesUncaughtCXXExceptionHandlerManager removeCXXExceptionHandler:handler2];
}

- (void)testWrapperException {
  // If
  const uintptr_t frames[2] = {0x123, 0x234};
  MSCrashesUncaughtCXXExceptionInfo info = {
      .exception = nullptr,
      .exception_type_name = nullptr,
      .exception_message = nullptr,
      .exception_frames_count = 2,
      .exception_frames = frames,
  };

  // When
  MSCrashesCXXExceptionWrapperException *wrapperException =
      [[MSCrashesCXXExceptionWrapperException alloc] initWithCXXExceptionInfo:&info];

  // Then
  XCTAssertNotNil(wrapperException);
  XCTAssertEqual(&info, wrapperException.info);

  // When
  NSArray *callStackReturnAddresses = [wrapperException callStackReturnAddresses];

  // Then
  XCTAssertTrue(callStackReturnAddresses.count == 2);
}

@end
