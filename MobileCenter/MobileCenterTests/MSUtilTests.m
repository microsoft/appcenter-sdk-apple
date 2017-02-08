#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import "OCMock.h"
#import "MSUtil.h"
#import "MSUtilPrivate.h"

@import XCTest;

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

@end
