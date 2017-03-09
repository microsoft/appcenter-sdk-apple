#import "MSUtil.h"
#import "MSUtilPrivate.h"
#import "OCMock.h"
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <XCTest/XCTest.h>

@interface MSUtilTests : XCTestCase

@property(nonatomic) id utils;

@end

@implementation MSUtilTests

- (void)setUp {
  [super setUp];

  // Set up application mock.
  self.utils = OCMClassMock([MSUtil class]);
}

- (void)tearDown {
  [super tearDown];
  [self.utils stopMocking];
}

- (void)testMSAppStateMatchesUIAppStateWhenAvailable {

  // Then
  assertThat(@([MSUtil applicationState]), is(@([UIApplication sharedApplication].applicationState)));
}

- (void)testMSAppReturnsUnknownOnAppExtensions {

  /**
   * If
   */

  // Mock the helper itself to monitor method calls.
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock executablePath]).andReturn(@"/apath/coolappext.appex/coolappext");
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);

  /**
   * Then
   */
  assertThat(@([MSUtil applicationState]), is(@(MSApplicationStateUnknown)));

  // Make sure the sharedApplication as not been called, it's forbidden within app extensions
  OCMReject([self.utils sharedAppState]);
  [bundleMock stopMocking];
}

- (void)testAppActive {

  // If
  UIApplicationState expectedState = UIApplicationStateActive;
  OCMStub([self.utils sharedAppState]).andReturn(expectedState);

  // When
  MSApplicationState state = [MSUtil applicationState];

  // Then
  assertThat(@(state), is(@(expectedState)));
}

- (void)testAppInactive {

  // If
  UIApplicationState expectedState = UIApplicationStateInactive;
  OCMStub([self.utils sharedAppState]).andReturn(expectedState);

  // When
  MSApplicationState state = [MSUtil applicationState];

  // Then
  assertThat(@(state), is(@(expectedState)));
}

- (void)testAppInBackground {

  // If
  UIApplicationState expectedState = UIApplicationStateBackground;
  OCMStub([self.utils sharedAppState]).andReturn(expectedState);

  // When
  MSApplicationState state = [MSUtil applicationState];

  // Then
  assertThat(@(state), is(@(expectedState)));
}

- (void)testNowInMilliseconds {

  /**
   * When
   */
  long long actual = [MSUtil nowInMilliseconds] / 10;
  long long expected = [[NSDate date] timeIntervalSince1970] * 100;

  /**
   * Then
   */
  XCTAssertEqual(actual, expected);

  // Negative in case of cast issue.
  XCTAssertGreaterThan(actual, 0);
}

- (void)testCurrentAppEnvironment {

  /**
   * When
   */
  MSEnvironment env = [MSUtil currentAppEnvironment];

  /**
   * Then
   */
  // Tests always run in simulators.
  XCTAssertEqual(env, MSEnvironmentOther);
}

- (void)testDebugConfiurationDetectionWorks {
  
  // When
  XCTAssertTrue([MSUtil isRunningInDebugConfiguration]);
}

- (void)TestFormatToUUIDString {

  // When
  NSString *tooShort = [MSUtil formatToUUIDString:@"a12e234b"];

  // Then
  assertThat(tooShort, nilValue());

  // When
  NSString *badFormat = [MSUtil formatToUUIDString:@"thisbuildidcontainsforbiddenchar"];

  // Then
  assertThat(badFormat, nilValue());

  // When
  NSString *goodFormat = [MSUtil formatToUUIDString:@"ef039a0a0f7f3c1d87e26bfc87acf1b9"];

  // Then
  assertThat(goodFormat, is(@"ef039a0a-0f7f-3c1d-87e2-6bfc87acf1b9"));
}

- (void)testSharedAppOpenEmptyCallCallback {
  __block BOOL handlerHasBeenCalled = NO;
  [MSUtil sharedAppOpenUrl:[NSURL URLWithString:@""] options:@{} completionHandler:^(BOOL success) {
    handlerHasBeenCalled = YES;
    XCTAssertFalse(success);
  }];
  XCTAssertTrue(handlerHasBeenCalled);
}

@end
