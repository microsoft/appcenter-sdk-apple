#import <OCMock/OCMock.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <XCTest/XCTest.h>
#import "MSUtility+ApplicationPrivate.h"
#import "MSUtility+Date.h"
#import "MSUtility+Environment.h"

@interface MSUtilTests : XCTestCase

@property(nonatomic) id utils;

@end

@implementation MSUtilTests

- (void)setUp {
  [super setUp];

  // Set up application mock.
  self.utils = OCMClassMock([MSUtility class]);
}

- (void)tearDown {
  [super tearDown];
  [self.utils stopMocking];
}

- (void)testMSAppStateMatchesUIAppStateWhenAvailable {

  // Then
  assertThat(@([MSUtility applicationState]), is(@([UIApplication sharedApplication].applicationState)));
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
  assertThat(@([MSUtility applicationState]), is(@(MSApplicationStateUnknown)));

  // Make sure the sharedApplication as not been called, it's forbidden within app extensions
  OCMReject([self.utils sharedAppState]);
  [bundleMock stopMocking];
}

- (void)testAppActive {

  // If
  UIApplicationState expectedState = UIApplicationStateActive;
  OCMStub([self.utils sharedAppState]).andReturn(expectedState);

  // When
  MSApplicationState state = [MSUtility applicationState];

  // Then
  assertThat(@(state), is(@(expectedState)));
}

- (void)testAppInactive {

  // If
  UIApplicationState expectedState = UIApplicationStateInactive;
  OCMStub([self.utils sharedAppState]).andReturn(expectedState);

  // When
  MSApplicationState state = [MSUtility applicationState];

  // Then
  assertThat(@(state), is(@(expectedState)));
}

- (void)testAppInBackground {

  // If
  UIApplicationState expectedState = UIApplicationStateBackground;
  OCMStub([self.utils sharedAppState]).andReturn(expectedState);

  // When
  MSApplicationState state = [MSUtility applicationState];

  // Then
  assertThat(@(state), is(@(expectedState)));
}

- (void)testNowInMilliseconds {

  /**
   * When
   */
  long long actual = [MSUtility nowInMilliseconds] / 10;
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
  MSEnvironment env = [MSUtility currentAppEnvironment];

  /**
   * Then
   */
  // Tests always run in simulators.
  XCTAssertEqual(env, MSEnvironmentOther);
}

- (void)testDebugConfiurationDetectionWorks {
  
  // When
  XCTAssertTrue([MSUtility isRunningInDebugConfiguration]);
}

- (void)testSharedAppOpenEmptyCallCallback {
  
  // If
  XCTestExpectation *openURLCalledExpectation = [self expectationWithDescription:@"openURL Called."];
  __block BOOL handlerHasBeenCalled = NO;
  
  // When
  [MSUtility sharedAppOpenUrl:[NSURL URLWithString:@""] options:@{} completionHandler:^(BOOL success) {
    handlerHasBeenCalled = YES;
    XCTAssertFalse(success);
  }];
  dispatch_async(dispatch_get_main_queue(), ^{
    [openURLCalledExpectation fulfill];
  });
  
  // Then
  [self
   waitForExpectationsWithTimeout:1
   handler:^(NSError *error) {
     XCTAssertTrue(handlerHasBeenCalled);
     if (error) {
       XCTFail(@"Expectation Failed with error: %@", error);
     }
   }];
}

@end
