#import <OCMock/OCMock.h>
#if TARGET_OS_IPHONE
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#else
#import <OCHamcrest/OCHamcrest.h>
#endif
#import <XCTest/XCTest.h>

#import "MSUtility+ApplicationPrivate.h"
#import "MSUtility+Date.h"
#import "MSUtility+Environment.h"
#import "MSUtility+StringFormatting.h"

@interface MSUtilityTests : XCTestCase

@property(nonatomic) id utils;

@end

@implementation MSUtilityTests

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
  long long actual = (long long)([MSUtility nowInMilliseconds] / 10);
  long long expected = (long long)([[NSDate date] timeIntervalSince1970] * 100);

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

- (void)testSharedAppOpenEmptyCallCallback {

  // If
  XCTestExpectation *openURLCalledExpectation = [self expectationWithDescription:@"openURL Called."];
  __block BOOL handlerHasBeenCalled = NO;

  // When
  [MSUtility sharedAppOpenUrl:[NSURL URLWithString:@""]
      options:@{}
      completionHandler:^(MSOpenURLState status) {
        handlerHasBeenCalled = YES;
        XCTAssertEqual(status, MSOpenURLStateFailed);
      }];
  dispatch_async(dispatch_get_main_queue(), ^{
    [openURLCalledExpectation fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 XCTAssertTrue(handlerHasBeenCalled);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testCreateSha256 {

  // When
  NSString *test = @"TestString";
  NSString *result = [MSUtility sha256:test];

  // Then
  XCTAssertTrue([result isEqualToString:@"6dd79f2770a0bb38073b814a5ff000647b37be5abbde71ec9176c6ce0cb32a27"]);
}

@end
