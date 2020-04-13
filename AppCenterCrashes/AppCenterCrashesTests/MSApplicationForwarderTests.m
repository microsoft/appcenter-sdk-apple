// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAppCenterInternal.h"
#import "MSApplicationForwarder.h"
#import "MSCrashesPrivate.h"
#import "MSMockNSUserDefaults.h"
#import "MSTestFrameworks.h"
#import "MSUtility+Application.h"

#if TARGET_OS_OSX
static NSException *lastException;
static void exceptionHandler(NSException *exception) { lastException = exception; }
#endif

@interface MSApplicationForwarderTests : XCTestCase

@end

@implementation MSApplicationForwarderTests

- (void)tearDown {
  [super tearDown];
  [MSCrashes resetSharedInstance];
}

#if TARGET_OS_OSX
- (void)testRegisterForwarding {
  NSException *testException = [NSException new];

  // If
  id applicationMock = OCMPartialMock([NSApplication sharedApplication]);
  id appCenterMock = OCMClassMock([MSAppCenter class]);
  OCMStub([appCenterMock isDebuggerAttached]).andReturn(NO);
  id crashesMock = OCMPartialMock([MSCrashes sharedInstance]);
  OCMStub([crashesMock exceptionHandler]).andReturn((NSUncaughtExceptionHandler *)exceptionHandler);

  // When
  [MSApplicationForwarder registerForwarding];
  [applicationMock reportException:testException];

  // Then
  XCTAssertNil(lastException);

  // Disable swizzling.
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock objectForInfoDictionaryKey:@"AppCenterApplicationForwarderEnabled"]).andReturn(@NO);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);

  // When
  [MSApplicationForwarder registerForwarding];
  [applicationMock reportException:testException];

  // Then
  XCTAssertNil(lastException);

  // Enable crash on exсeptions.
  MSMockNSUserDefaults *settings = [MSMockNSUserDefaults new];
  [settings setObject:@YES forKey:@"NSApplicationCrashOnExceptions"];

  // When
  [MSApplicationForwarder registerForwarding];
  [applicationMock reportException:testException];

  // Then
  XCTAssertNil(lastException);

  // Enable swizzling
  [bundleMock stopMocking];

  // When
  [MSApplicationForwarder registerForwarding];
  [applicationMock reportException:testException];

  // Then
  XCTAssertEqual(lastException, testException);
  [settings stopMocking];
  [applicationMock stopMocking];
  [appCenterMock stopMocking];
  [crashesMock stopMocking];
}
#endif

@end
