// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAppCenterInternal.h"
#import "MSCrashesCategory.h"
#import "MSCrashesPrivate.h"
#import "MSMockUserDefaults.h"
#import "MSTestFrameworks.h"
#import "MSUtility+Application.h"

#if TARGET_OS_OSX

@interface NSApplication (CrashException)

- (void)ms_reportException:(NSException *)exception;
- (void)ms_sendEvent:(NSEvent *)theEvent;

@end

#endif

static NSException *lastException;
static void exceptionHandler(NSException *exception) {
  lastException = exception;
}

@interface MSCrashesCategoryTests : XCTestCase

@end

@implementation MSCrashesCategoryTests

- (void)testActivateCategory {

  // If
#if TARGET_OS_OSX
  MSMockUserDefaults *settings = [MSMockUserDefaults new];
  [settings setObject:@YES forKey:@"NSApplicationCrashOnExceptions"];
  id applicationMock = OCMPartialMock([NSApplication sharedApplication]);
  id appCenterMock = OCMClassMock([MSAppCenter class]);
  OCMStub([appCenterMock isDebuggerAttached]).andReturn(NO);
  id crashesMock = OCMPartialMock([MSCrashes sharedInstance]);
  OCMStub([crashesMock exceptionHandler]).andReturn((NSUncaughtExceptionHandler *)exceptionHandler);
#endif
  // When
  [MSCrashesCategory activateCategory];
#if TARGET_OS_OSX
  NSException *e = [NSException new];
  [applicationMock reportException:e];
#endif

  // Then
#if TARGET_OS_OSX
  XCTAssertEqual(lastException, e);
  [settings stopMocking];
  [applicationMock stopMocking];
  [appCenterMock stopMocking];
  [crashesMock stopMocking];
#endif
}

@end
