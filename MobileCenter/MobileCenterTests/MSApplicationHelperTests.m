#import "MSApplicationHelper.h"
#import "MSApplicationHelperPrivate.h"
#import "OCMock.h"
#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

@interface MSApplicationHelperTests : XCTestCase

@property(nonatomic) id appHelper;

@end

@implementation MSApplicationHelperTests

- (void)setUp {
  [super setUp];

  // Set up application mock.
  self.appHelper = OCMClassMock([MSApplicationHelper class]);
}

- (void)tearDown {
  [super tearDown];
  [self.appHelper stopMocking];
}

- (void)testMSAppStateMatchesUIAppStateWhenAvailable {

  // Then
  assertThat(@([MSApplicationHelper applicationState]), is(@([UIApplication sharedApplication].applicationState)));
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
  assertThat(@([MSApplicationHelper applicationState]), is(@(MSApplicationStateUnknown)));

  // Make sure the sharedApplication as not been called, it's forbidden within app extensions
  OCMReject([self.appHelper sharedAppState]);
  [bundleMock stopMocking];
}

- (void)testAppActive {

  // If
  UIApplicationState expectedState = UIApplicationStateActive;
  OCMStub([self.appHelper sharedAppState]).andReturn(expectedState);

  // When
  MSApplicationState state = [MSApplicationHelper applicationState];

  // Then
  assertThat(@(state), is(@(expectedState)));
}

- (void)testAppInactive {

  // If
  UIApplicationState expectedState = UIApplicationStateInactive;
  OCMStub([self.appHelper sharedAppState]).andReturn(expectedState);

  // When
  MSApplicationState state = [MSApplicationHelper applicationState];

  // Then
  assertThat(@(state), is(@(expectedState)));
}

- (void)testAppInBackground {

  // If
  UIApplicationState expectedState = UIApplicationStateBackground;
  OCMStub([self.appHelper sharedAppState]).andReturn(expectedState);

  // When
  MSApplicationState state = [MSApplicationHelper applicationState];

  // Then
  assertThat(@(state), is(@(expectedState)));
}

@end
