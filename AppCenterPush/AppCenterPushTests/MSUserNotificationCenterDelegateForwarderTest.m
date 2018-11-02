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

#if !TARGET_OS_OSX
@interface MSUserNotificationCenterDelegateForwarderTest : XCTestCase

@property(nonatomic) MSUserNotificationCenterDelegateForwarder *sut;
@property(nonatomic) UNNotificationResponse *notificationResponseMock;
@property(nonatomic) UNUserNotificationCenter *notificationCenterMock;
@property(nonatomic) NSDictionary *expectedUserInfo;
@property(nonatomic) id pushMock;

@end

@implementation MSUserNotificationCenterDelegateForwarderTest

- (void)setUp {
  [super setUp];

  // The delegate forwarder is already set via the load method, reset it for testing.
  [MSUserNotificationCenterDelegateForwarder resetSharedInstance];
  self.sut = [MSUserNotificationCenterDelegateForwarder sharedInstance];
  self.pushMock = OCMClassMock([MSPush class]);
  self.expectedUserInfo = @{@"aps" : @{@"alert" : @"message"}};

  // Mock notification center and notification response.
  MS_RETURN_IF_USER_NOTIFICATION_CENTER_NOT_SUPPORTED
  self.notificationCenterMock = OCMClassMock([UNUserNotificationCenter class]);
  UNNotificationContent *notificationContentMock = OCMClassMock([UNNotificationContent class]);
  UNNotificationRequest *notificationRequestMock = OCMClassMock([UNNotificationRequest class]);
  UNNotification *notificationMock = OCMClassMock([UNNotification class]);
  self.notificationResponseMock = OCMClassMock([UNNotificationResponse class]);
  OCMStub([notificationMock request]).andReturn(notificationRequestMock);
  OCMStub([notificationRequestMock content]).andReturn(notificationContentMock);
  OCMStub([notificationContentMock userInfo]).andReturn(self.expectedUserInfo);
  OCMStub([self.notificationResponseMock notification]).andReturn(notificationMock);
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

- (void)testWillPresentNotificationSwizzledWhenNoOriginalImplementation {
  MS_RETURN_IF_USER_NOTIFICATION_CENTER_NOT_SUPPORTED

  // If
  XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"Completion handler called."];
  void (^completionHandler)(UNNotificationPresentationOptions) = ^void(UNNotificationPresentationOptions options) {
    assertThatInt(options, equalToInt(UNNotificationPresentationOptionNone));
    [completionHandlerExpectation fulfill];
  };

  // Original delegate doesn't implement anything.
  id<UNUserNotificationCenterDelegate> originalUserNotificationCenterDelegate = [self createOriginalUserNotificationCenterDelegateInstance];

  // Swizzle.
  [[self.sut class] load];
  [self.sut swizzleOriginalDelegate:originalUserNotificationCenterDelegate];

  // When
  [originalUserNotificationCenterDelegate userNotificationCenter:self.notificationCenterMock
                                         willPresentNotification:self.notificationResponseMock.notification
                                           withCompletionHandler:completionHandler];

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
                                   OCMVerify([self.pushMock didReceiveRemoteNotification:self.expectedUserInfo]);
                                 }
                               }];
}

- (void)testDidReceiveNotificationResponseSwizzledWhenNoOriginalImplementation {
  MS_RETURN_IF_USER_NOTIFICATION_CENTER_NOT_SUPPORTED

  // If
  XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"Completion handler called."];
  void (^completionHandler)(void) = ^void() {
    [completionHandlerExpectation fulfill];
  };

  // Original delegate doesn't implement anything.
  id<UNUserNotificationCenterDelegate> originalUserNotificationCenterDelegate = [self createOriginalUserNotificationCenterDelegateInstance];

  // Swizzle.
  [[self.sut class] load];
  [self.sut swizzleOriginalDelegate:originalUserNotificationCenterDelegate];

  // When
  [originalUserNotificationCenterDelegate userNotificationCenter:self.notificationCenterMock
                                  didReceiveNotificationResponse:self.notificationResponseMock
                                           withCompletionHandler:completionHandler];

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
                                   OCMVerify([self.pushMock didReceiveRemoteNotification:self.expectedUserInfo]);
                                 }
                               }];
}

- (void)testWillPresentNotificationSwizzledWhenAlsoImplementatedByOriginalDelegate {
  MS_RETURN_IF_USER_NOTIFICATION_CENTER_NOT_SUPPORTED

  // If
  __block short pushCallCounter;
  OCMStub([self.pushMock didReceiveRemoteNotification:self.expectedUserInfo]).andDo(^(__unused NSInvocation *invocation) {
    pushCallCounter++;
  });
  XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"Completion handler called."];
  void (^completionHandler)(UNNotificationPresentationOptions) = ^void(UNNotificationPresentationOptions options) {
    assertThatInt(options, equalToInt(UNNotificationPresentationOptionAlert));
    [completionHandlerExpectation fulfill];
  };

  // Original delegate implements the callback.
  id<UNUserNotificationCenterDelegate> originalUserNotificationCenterDelegate = [self createOriginalUserNotificationCenterDelegateInstance];
  SEL willPresentNotificationSel = @selector(userNotificationCenter:willPresentNotification:withCompletionHandler:);
  id originalWillPresentNotificationImp =
      ^(__attribute__((unused)) id itSelf, __attribute__((unused)) UNUserNotificationCenter *notificationCenter,
        __attribute__((unused)) UNNotification *notification, void (^handler)(UNNotificationPresentationOptions)) {
        assertThat(notification, is(self.notificationResponseMock.notification));
        assertThat(notificationCenter, is(self.notificationCenterMock));

        // Push callback must be called after the original implementation.
        assertThatShort(pushCallCounter, equalToShort(0));
        handler(UNNotificationPresentationOptionAlert);
      };
  [MSDelegateForwarderTestUtil addSelector:willPresentNotificationSel
                            implementation:originalWillPresentNotificationImp
                                toInstance:originalUserNotificationCenterDelegate];

  // Swizzle.
  [[self.sut class] load];
  [self.sut swizzleOriginalDelegate:originalUserNotificationCenterDelegate];

  // When
  [originalUserNotificationCenterDelegate userNotificationCenter:self.notificationCenterMock
                                         willPresentNotification:self.notificationResponseMock.notification
                                           withCompletionHandler:completionHandler];

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
                                   assertThatShort(pushCallCounter, equalToShort(1));
                                 }
                               }];
}

- (void)testDidReceiveNotificationResponseSwizzledWhenAlsoImplementatedByOriginalDelegate {
  MS_RETURN_IF_USER_NOTIFICATION_CENTER_NOT_SUPPORTED

  // If
  __block short pushCallCounter;
  OCMStub([self.pushMock didReceiveRemoteNotification:self.expectedUserInfo]).andDo(^(__unused NSInvocation *invocation) {
    pushCallCounter++;
  });
  XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"Completion handler called."];
  void (^completionHandler)(void) = ^void() {
    [completionHandlerExpectation fulfill];
  };

  // Original delegate implements the callback.
  id<UNUserNotificationCenterDelegate> originalUserNotificationCenterDelegate = [self createOriginalUserNotificationCenterDelegateInstance];
  SEL didReceiveNotificationResponseSel = @selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:);
  id originalDidReceiveNotificationResponseImp =
      ^(__attribute__((unused)) id itSelf, __attribute__((unused)) UNUserNotificationCenter *notificationCenter,
        __attribute__((unused)) UNNotificationResponse *notificationResponse, void (^handler)(void)) {
        assertThat(notificationResponse, is(self.notificationResponseMock));
        assertThat(notificationCenter, is(self.notificationCenterMock));

        // Push callback must be called after the original implementation.
        assertThatShort(pushCallCounter, equalToShort(0));
        handler();
      };
  [MSDelegateForwarderTestUtil addSelector:didReceiveNotificationResponseSel
                            implementation:originalDidReceiveNotificationResponseImp
                                toInstance:originalUserNotificationCenterDelegate];

  // Swizzle.
  [[self.sut class] load];
  [self.sut swizzleOriginalDelegate:originalUserNotificationCenterDelegate];

  // When
  [originalUserNotificationCenterDelegate userNotificationCenter:self.notificationCenterMock
                                  didReceiveNotificationResponse:self.notificationResponseMock
                                           withCompletionHandler:completionHandler];

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
                                   assertThatShort(pushCallCounter, equalToShort(1));
                                 }
                               }];
}

- (id<UNUserNotificationCenterDelegate>)createOriginalUserNotificationCenterDelegateInstance {
  return [MSDelegateForwarderTestUtil createInstanceConformingToProtocol:@protocol(UNUserNotificationCenterDelegate)];
}

@end
#endif
