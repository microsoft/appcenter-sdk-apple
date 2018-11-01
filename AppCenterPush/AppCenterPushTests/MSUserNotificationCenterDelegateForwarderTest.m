#import <Foundation/Foundation.h>
#if !TARGET_OS_OSX
#import <UserNotifications/UserNotifications.h>
#endif

#import "MSDelegateForwarderPrivate.h"
#import "MSDelegateForwarderTestUtil.h"
#import "MSPush.h"
#import "MSTestFrameworks.h"
#import "MSUserNotificationCenterDelegateForwarder.h"

#define MS_RETURN_IF_USER_NOTIFICATION_CENTER_NOT_SUPPORTED                                                                                \
  if (!NSClassFromString(@"UNUserNotificationCenter")) {                                                                                   \
    return;                                                                                                                                \
  }

@interface MSUserNotificationCenterDelegateForwarderTest : XCTestCase

@property(nonatomic) MSUserNotificationCenterDelegateForwarder *sut;

@end

@implementation MSUserNotificationCenterDelegateForwarderTest

- (void)setUp {
  [super setUp];

  // The delegate forwarder is already set via the load method, reset it for testing.
  [MSUserNotificationCenterDelegateForwarder resetSharedInstance];
  self.sut = [MSUserNotificationCenterDelegateForwarder sharedInstance];
}

- (void)tearDown {
  [super tearDown];
  [MSUserNotificationCenterDelegateForwarder resetSharedInstance];
}

- (void)testSetEnabledYesFromPlist {

  // If
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock objectForInfoDictionaryKey:kMSUserNotificationCenterDelegateForwarderEnabledKey]).andReturn(@YES);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);

  // When
  [[self.sut class] load];

  // Then
  assertThatBool(self.sut.enabled, isTrue());
}

- (void)testSetEnabledNoFromPlist {

  // If
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock objectForInfoDictionaryKey:kMSUserNotificationCenterDelegateForwarderEnabledKey]).andReturn(@NO);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);

  // When
  [[self.sut class] load];

  // Then
  assertThatBool(self.sut.enabled, isFalse());
}

- (void)testSetEnabledNoneFromPlist {

  // If
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock objectForInfoDictionaryKey:kMSUserNotificationCenterDelegateForwarderEnabledKey]).andReturn(nil);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);

  // When
  [[self.sut class] load];

  // Then
  assertThatBool(self.sut.enabled, isTrue());
}

#if !TARGET_OS_OSX

- (void)testAllRequiredDelegateSwizzledWhenNoOriginalImplementation {
  MS_RETURN_IF_USER_NOTIFICATION_CENTER_NOT_SUPPORTED

  // If
  id pushMock = OCMClassMock([MSPush class]);
  NSDictionary *expectedUserInfo = @{@"aps" : @{@"alert" : @"message"}};
  id expectedNotificationCenter = OCMClassMock([UNUserNotificationCenter class]);
  UNNotificationContent *expectedNotificationContent = OCMClassMock([UNNotificationContent class]);
  UNNotificationRequest *expectedNotificationRequest = OCMClassMock([UNNotificationRequest class]);
  UNNotificationResponse *expectedNotificationResponse = OCMClassMock([UNNotificationResponse class]);
  UNNotification *expectedNotification = OCMClassMock([UNNotification class]);
  OCMStub([expectedNotification request]).andReturn(expectedNotificationRequest);
  OCMStub([expectedNotificationRequest content]).andReturn(expectedNotificationContent);
  OCMStub([expectedNotificationContent userInfo]).andReturn(expectedUserInfo);
  OCMStub([expectedNotificationResponse notification]).andReturn(expectedNotification);
  XCTestExpectation *presentationCompletionHandlerExpectation =
      [self expectationWithDescription:@"Presentation completion handler called."];
  XCTestExpectation *responseCompletionHandlerExpectation = [self expectationWithDescription:@"Response completion handler called."];
  void (^presentationCompletionHandler)(UNNotificationPresentationOptions) = ^void(UNNotificationPresentationOptions options) {
    assertThatInt(options, equalToInt(UNNotificationPresentationOptionNone));
    [presentationCompletionHandlerExpectation fulfill];
  };
  void (^responseCompletionHandler)(void) = ^void() {
    [responseCompletionHandlerExpectation fulfill];
  };

  // Original delegate doesn't implement anything.
  id<UNUserNotificationCenterDelegate> originalUserNotificationCenterDelegate = [self createOriginalUserNotificationCenterDelegateInstance];

  // When
  [[self.sut class] load];
  [self.sut swizzleOriginalDelegate:originalUserNotificationCenterDelegate];
  [originalUserNotificationCenterDelegate userNotificationCenter:expectedNotificationCenter
                                         willPresentNotification:expectedNotification
                                           withCompletionHandler:presentationCompletionHandler];
  [originalUserNotificationCenterDelegate userNotificationCenter:expectedNotificationCenter
                                  didReceiveNotificationResponse:expectedNotificationResponse
                                           withCompletionHandler:responseCompletionHandler];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(__unused NSError *error) {
                                 // In the end the completion handler must be
                                 // called with the forwarded value.
                                 if (error) {
                                   XCTFail(@"Failed to complete all delegate "
                                           @"invocations with error: %@",
                                           error.localizedDescription);
                                 } else {
                                   OCMVerify([pushMock didReceiveRemoteNotification:expectedUserInfo]);
                                 }
                               }];
}

- (void)testAllRequiredDelegateSwizzledWhenOriginalImplementations {
  MS_RETURN_IF_USER_NOTIFICATION_CENTER_NOT_SUPPORTED

  // If
  id pushMock = OCMClassMock([MSPush class]);
  NSDictionary *expectedUserInfo = @{@"aps" : @{@"alert" : @"message"}};
  id expectedNotificationCenter = OCMClassMock([UNUserNotificationCenter class]);
  UNNotificationContent *expectedNotificationContent = OCMClassMock([UNNotificationContent class]);
  UNNotificationRequest *expectedNotificationRequest = OCMClassMock([UNNotificationRequest class]);
  UNNotificationResponse *expectedNotificationResponse = OCMClassMock([UNNotificationResponse class]);
  UNNotification *expectedNotification = OCMClassMock([UNNotification class]);
  OCMStub([expectedNotification request]).andReturn(expectedNotificationRequest);
  OCMStub([expectedNotificationRequest content]).andReturn(expectedNotificationContent);
  OCMStub([expectedNotificationContent userInfo]).andReturn(expectedUserInfo);
  OCMStub([expectedNotificationResponse notification]).andReturn(expectedNotification);
  XCTestExpectation *presentationCompletionHandlerExpectation =
      [self expectationWithDescription:@"Presentation completion handler called."];
  XCTestExpectation *responseCompletionHandlerExpectation = [self expectationWithDescription:@"Response completion handler called."];
  void (^presentationCompletionHandler)(UNNotificationPresentationOptions) = ^void(UNNotificationPresentationOptions options) {
    assertThatInt(options, equalToInt(UNNotificationPresentationOptionAlert));
    [presentationCompletionHandlerExpectation fulfill];
  };
  void (^responseCompletionHandler)(void) = ^void() {
    [responseCompletionHandlerExpectation fulfill];
  };

  // Original delegate implements the callbacks.
  id<UNUserNotificationCenterDelegate> originalUserNotificationCenterDelegate = [self createOriginalUserNotificationCenterDelegateInstance];
  SEL willPresentNotificationSel = @selector(userNotificationCenter:willPresentNotification:withCompletionHandler:);
  id originalWillPresentNotificationImp =
      ^(__attribute__((unused)) id itSelf, __attribute__((unused)) UNUserNotificationCenter *notificationCenter,
        __attribute__((unused)) UNNotification *notification, void (^handler)(UNNotificationPresentationOptions)) {
        assertThat(notification, is(expectedNotification));
        assertThat(notificationCenter, is(expectedNotificationCenter));
        handler(UNNotificationPresentationOptionAlert);
      };
  [MSDelegateForwarderTestUtil addSelector:willPresentNotificationSel
                            implementation:originalWillPresentNotificationImp
                                toInstance:originalUserNotificationCenterDelegate];
  SEL didReceiveNotificationResponseSel = @selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:);
  id originalDidReceiveNotificationResponseImp =
      ^(__attribute__((unused)) id itSelf, __attribute__((unused)) UNUserNotificationCenter *notificationCenter,
        __attribute__((unused)) UNNotificationResponse *notificationResponse, void (^handler)(void)) {
        assertThat(notificationResponse, is(expectedNotificationResponse));
        assertThat(notificationCenter, is(expectedNotificationCenter));
        handler();
      };
  [MSDelegateForwarderTestUtil addSelector:didReceiveNotificationResponseSel
                            implementation:originalDidReceiveNotificationResponseImp
                                toInstance:originalUserNotificationCenterDelegate];

  // When
  [[self.sut class] load];
  [self.sut swizzleOriginalDelegate:originalUserNotificationCenterDelegate];
  [originalUserNotificationCenterDelegate userNotificationCenter:expectedNotificationCenter
                                         willPresentNotification:expectedNotification
                                           withCompletionHandler:presentationCompletionHandler];
  [originalUserNotificationCenterDelegate userNotificationCenter:expectedNotificationCenter
                                  didReceiveNotificationResponse:expectedNotificationResponse
                                           withCompletionHandler:responseCompletionHandler];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(__unused NSError *error) {
                                 // In the end the completion handler must be
                                 // called with the forwarded value.
                                 if (error) {
                                   XCTFail(@"Failed to complete all delegate "
                                           @"invocations with error: %@",
                                           error.localizedDescription);
                                 } else {
                                   OCMVerify([pushMock didReceiveRemoteNotification:expectedUserInfo]);
                                 }
                               }];
}

#pragma mark - Helper

- (id<UNUserNotificationCenterDelegate>)createOriginalUserNotificationCenterDelegateInstance {
  return [MSDelegateForwarderTestUtil createInstanceConformingToProtocol:@protocol(UNUserNotificationCenterDelegate)];
}

#endif

@end
