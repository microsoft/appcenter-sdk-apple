#import <Foundation/Foundation.h>

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#else
#import <UserNotifications/UserNotifications.h>
#endif

#import "MSChannelGroupProtocol.h"
#import "MSChannelUnitProtocol.h"
#import "MSPush.h"
#import "MSPushAppDelegate.h"
#import "MSPushLog.h"
#import "MSPushNotification.h"
#import "MSPushPrivate.h"
#import "MSPushTestUtil.h"
#import "MSTestFrameworks.h"
#import "MSUserIdContextPrivate.h"

static NSString *const kMSTestAppSecret = @"TestAppSecret";
static NSString *const kMSTestPushToken = @"TestPushToken";

@interface MSPushTests : XCTestCase

@property(nonatomic) MSPush *sut;
@property(nonatomic) id settingsMock;

@end

@interface MSPush ()

- (void)willSendLog:(id<MSLog>)log;

- (void)didSucceedSendingLog:(id<MSLog>)log;

- (void)didFailSendingLog:(id<MSLog>)log withError:(NSError *)error;

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;

#if TARGET_OS_OSX
- (BOOL)didReceiveUserNotification:(NSUserNotification *)notification;
#endif

- (BOOL)didReceiveRemoteNotification:(NSDictionary *)userInfo fromUserNotification:(BOOL)userNotification;

@end

@interface MSServiceAbstract ()

- (BOOL)isEnabled;

- (void)setEnabled:(BOOL)enabled;

@end

@implementation MSPushTests

- (void)setUp {
  [super setUp];
  [MSUserIdContext resetSharedInstance];
  self.sut = [MSPush new];

// Mock UNUserNotificationCenter since it not supported during tests.
#if TARGET_OS_IOS
  if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_x_Max) {

// Ignore the partial availability warning as the compiler doesn't get that we checked for pre-iOS 10 already.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
    id notificationCenterMock = OCMClassMock([UNUserNotificationCenter class]);
    OCMStub(ClassMethod([notificationCenterMock currentNotificationCenter])).andReturn(nil);
#pragma clang diagnostic pop
  }
#endif
}

- (void)tearDown {
  [super tearDown];
  [MSPush resetSharedInstance];
}

#pragma mark - Tests

- (void)testApplyEnabledStateWorks {

  // If
  [[MSPush sharedInstance] startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                                       appSecret:kMSTestAppSecret
                         transmissionTargetToken:nil
                                 fromApplication:YES];
  MSServiceAbstract *service = (MSServiceAbstract *)[MSPush sharedInstance];

  // When
  [service setEnabled:YES];

  // Then
  XCTAssertTrue([service isEnabled]);

  // When
  [service setEnabled:NO];

  // Then
  XCTAssertFalse([service isEnabled]);

  // When
  [service setEnabled:YES];

  // Then
  XCTAssertTrue([service isEnabled]);
}

- (void)testInitializationPriorityCorrect {

  // Then
  XCTAssertTrue(self.sut.initializationPriority == MSInitializationPriorityDefault);
}

- (void)testConvertTokenToString {

  // If
  NSString *originalToken = @"563084c4934486547307ea41c780b93e21fe98372dc902426e97390a84011f72";
  NSData *rawOriginalToken = [MSPushTestUtil convertPushTokenToNSData:originalToken];
  NSString *convertedToken = [self.sut convertTokenToString:rawOriginalToken];

  // Then
  XCTAssertEqualObjects(originalToken, convertedToken);

  // When
  convertedToken = [self.sut convertTokenToString:nil];

  // Then
  XCTAssertNil(convertedToken);
}

- (void)testDidRegisterForRemoteNotificationsWithDeviceToken {

  // If
  id pushMock = OCMPartialMock(self.sut);
  OCMStub([pushMock sharedInstance]).andReturn(pushMock);
  [MSPush resetSharedInstance];
  NSData *deviceToken = [@"deviceToken" dataUsingEncoding:NSUTF8StringEncoding];
  NSString *pushToken = @"ConvertedPushToken";
  OCMStub([pushMock convertTokenToString:deviceToken]).andReturn(pushToken);
  __block MSPushLog *log;
  id channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  id channelGroupMock = OCMProtocolMock(@protocol(MSChannelGroupProtocol));
  OCMStub([channelGroupMock addChannelUnitWithConfiguration:OCMOCK_ANY]).andReturn(channelUnitMock);
  OCMStub([channelUnitMock enqueueItem:[OCMArg isKindOfClass:[MSPushLog class]] flags:MSFlagsDefault]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&log atIndex:2];
  });

  // Then
  XCTAssertNil(self.sut.pushToken);

  // When
  [[MSPush sharedInstance] startWithChannelGroup:channelGroupMock
                                       appSecret:kMSTestAppSecret
                         transmissionTargetToken:nil
                                 fromApplication:YES];
  [MSPush didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];

  // Then
  XCTAssertEqualObjects(self.sut.pushToken, pushToken);
  OCMVerify([pushMock didRegisterForRemoteNotificationsWithDeviceToken:deviceToken]);
  OCMVerify([pushMock convertTokenToString:deviceToken]);
  OCMVerify([pushMock sendPushToken:pushToken]);
  XCTAssertNotNil(log);
  XCTAssertEqual(pushToken, log.pushToken);
  XCTAssertNil(log.userId);

  // When
  deviceToken = [@"otherToken" dataUsingEncoding:NSUTF8StringEncoding];
  pushToken = @"ConvertedOtherToken";
  OCMStub([pushMock convertTokenToString:deviceToken]).andReturn(pushToken);
  [[MSUserIdContext sharedInstance] setUserId:@"alice"];
  [MSPush didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];

  // Then
  XCTAssertEqualObjects(self.sut.pushToken, pushToken);
  OCMVerify([pushMock didRegisterForRemoteNotificationsWithDeviceToken:deviceToken]);
  OCMVerify([pushMock convertTokenToString:deviceToken]);
  OCMVerify([pushMock sendPushToken:pushToken]);
  XCTAssertNotNil(log);
  XCTAssertEqual(pushToken, log.pushToken);
  XCTAssertEqual(@"alice", log.userId);

  // When
  OCMReject([pushMock sendPushToken:OCMOCK_ANY]);
  [MSPush didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];

  // Then
  [pushMock verify];
  [pushMock stopMocking];
}

- (void)testDidFailToRegisterForRemoteNotificationsWithError {

  // If
  id pushMock = OCMPartialMock(self.sut);
  OCMStub([pushMock sharedInstance]).andReturn(pushMock);
  [MSPush resetSharedInstance];
  NSError *errorMock = OCMClassMock([NSError class]);

  // When
  [MSPush didFailToRegisterForRemoteNotificationsWithError:errorMock];

  // Then
  OCMVerify([pushMock didFailToRegisterForRemoteNotificationsWithError:errorMock]);
  [pushMock stopMocking];
}

- (void)testNotificationReceivedWithMobileCenterCustomData {

  // If
  XCTestExpectation *notificationReceived = [self expectationWithDescription:@"Valid notification received."];
  id pushMock = OCMPartialMock(self.sut);
  OCMStub([pushMock sharedInstance]).andReturn(pushMock);
  OCMStub([pushMock canBeUsed]).andReturn(YES);
  [MSPush resetSharedInstance];
  id pushDelegateMock = OCMProtocolMock(@protocol(MSPushDelegate));
  __block MSPushNotification *pushNotification = nil;
  OCMStub([pushDelegateMock push:self.sut didReceivePushNotification:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&pushNotification atIndex:3];
  });
  [MSPush setDelegate:pushDelegateMock];
  __block NSString *title = @"notification title";
  __block NSString *message = @"notification message";
  __block NSDictionary *customData = @{@"key" : @"value"};
  NSDictionary *userInfo = @{
    kMSPushNotificationApsKey :
        @{kMSPushNotificationAlertKey : @{kMSPushNotificationTitleKey : title, kMSPushNotificationMessageKey : message}},
    @"mobile_center" : customData
  };
#if TARGET_OS_OSX
  id userNotificationUserInfoMock = OCMClassMock([NSUserNotification class]);
  id notificationMock = OCMClassMock([NSNotification class]);
  NSDictionary *notificationUserInfo = @{NSApplicationLaunchUserNotificationKey : userNotificationUserInfoMock};
  OCMStub([notificationMock userInfo]).andReturn(notificationUserInfo);
  OCMStub([userNotificationUserInfoMock userInfo]).andReturn(userInfo);
#endif

// When
#if TARGET_OS_OSX
  [self.sut applicationDidFinishLaunching:notificationMock];
#else
  BOOL result = [MSPush didReceiveRemoteNotification:userInfo];
#endif
  dispatch_async(dispatch_get_main_queue(), ^{
    [notificationReceived fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
#if TARGET_OS_OSX
                                 OCMVerify([pushMock didReceiveUserNotification:userNotificationUserInfoMock]);
#else
        OCMVerify([pushMock didReceiveRemoteNotification:userInfo]);
#endif
                                 OCMVerify([pushDelegateMock push:self.sut didReceivePushNotification:OCMOCK_ANY]);
                                 XCTAssertNotNil(pushNotification);
                                 XCTAssertEqual(pushNotification.title, title);
                                 XCTAssertEqual(pushNotification.message, message);
                                 XCTAssertEqual(pushNotification.customData, customData);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
#if !TARGET_OS_OSX
  XCTAssertTrue(result);
#endif
  [pushMock stopMocking];
}

- (void)testNotificationReceivedWithAlertObject {

  // If
  XCTestExpectation *notificationReceived = [self expectationWithDescription:@"Valid notification received."];
  id pushMock = OCMPartialMock(self.sut);
  OCMStub([pushMock sharedInstance]).andReturn(pushMock);
  OCMStub([pushMock canBeUsed]).andReturn(YES);
  [MSPush resetSharedInstance];
  id pushDelegateMock = OCMProtocolMock(@protocol(MSPushDelegate));
  __block MSPushNotification *pushNotification = nil;
  OCMStub([pushDelegateMock push:self.sut didReceivePushNotification:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&pushNotification atIndex:3];
  });
  [MSPush setDelegate:pushDelegateMock];
  __block NSString *title = @"notification title";
  __block NSString *message = @"notification message";
  __block NSDictionary *customData = @{@"key" : @"value"};
  NSDictionary *userInfo = @{
    kMSPushNotificationApsKey :
        @{kMSPushNotificationAlertKey : @{kMSPushNotificationTitleKey : title, kMSPushNotificationMessageKey : message}},
    kMSPushNotificationCustomDataKey : customData
  };
#if TARGET_OS_OSX
  id userNotificationUserInfoMock = OCMClassMock([NSUserNotification class]);
  id notificationMock = OCMClassMock([NSNotification class]);
  NSDictionary *notificationUserInfo = @{NSApplicationLaunchUserNotificationKey : userNotificationUserInfoMock};
  OCMStub([notificationMock userInfo]).andReturn(notificationUserInfo);
  OCMStub([userNotificationUserInfoMock userInfo]).andReturn(userInfo);
#endif

// When
#if TARGET_OS_OSX
  [self.sut applicationDidFinishLaunching:notificationMock];
#else
  BOOL result = [MSPush didReceiveRemoteNotification:userInfo];
#endif
  dispatch_async(dispatch_get_main_queue(), ^{
    [notificationReceived fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
#if TARGET_OS_OSX
                                 OCMVerify([pushMock didReceiveUserNotification:userNotificationUserInfoMock]);
#else
        OCMVerify([pushMock didReceiveRemoteNotification:userInfo]);
#endif
                                 OCMVerify([pushDelegateMock push:self.sut didReceivePushNotification:OCMOCK_ANY]);
                                 XCTAssertNotNil(pushNotification);
                                 XCTAssertEqual(pushNotification.title, title);
                                 XCTAssertEqual(pushNotification.message, message);
                                 XCTAssertEqual(pushNotification.customData, customData);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
#if !TARGET_OS_OSX
  XCTAssertTrue(result);
#endif
  [pushMock stopMocking];
}

- (void)testNotificationReceivedWithAlertObjectWithoutTitleMessagesAndCustomData {

  // If
  XCTestExpectation *notificationReceived = [self expectationWithDescription:@"Valid notification received."];
  id pushMock = OCMPartialMock(self.sut);
  OCMStub([pushMock sharedInstance]).andReturn(pushMock);
  OCMStub([pushMock canBeUsed]).andReturn(YES);
  [MSPush resetSharedInstance];
  id pushDelegateMock = OCMProtocolMock(@protocol(MSPushDelegate));
  __block MSPushNotification *pushNotification = nil;
  OCMStub([pushDelegateMock push:self.sut didReceivePushNotification:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&pushNotification atIndex:3];
  });
  [MSPush setDelegate:pushDelegateMock];
  __block NSString *title = nil;
  __block NSNull *message = [NSNull new];
  __block NSDictionary *customData = @{};
  NSDictionary *userInfo = @{
    kMSPushNotificationApsKey : @{kMSPushNotificationAlertKey : @{kMSPushNotificationMessageKey : message}},
    @"mobile_center" : customData
  };
#if TARGET_OS_OSX
  id userNotificationUserInfoMock = OCMClassMock([NSUserNotification class]);
  id notificationMock = OCMClassMock([NSNotification class]);
  NSDictionary *notificationUserInfo = @{NSApplicationLaunchUserNotificationKey : userNotificationUserInfoMock};
  OCMStub([notificationMock userInfo]).andReturn(notificationUserInfo);
  OCMStub([userNotificationUserInfoMock userInfo]).andReturn(userInfo);
#endif

// When
#if TARGET_OS_OSX
  [self.sut applicationDidFinishLaunching:notificationMock];
#else
  BOOL result = [MSPush didReceiveRemoteNotification:userInfo];
#endif
  dispatch_async(dispatch_get_main_queue(), ^{
    [notificationReceived fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
#if TARGET_OS_OSX
                                 OCMVerify([pushMock didReceiveUserNotification:userNotificationUserInfoMock]);
#else
        OCMVerify([pushMock didReceiveRemoteNotification:userInfo]);
#endif
                                 OCMVerify([pushDelegateMock push:self.sut didReceivePushNotification:OCMOCK_ANY]);
                                 XCTAssertNotNil(pushNotification);
                                 XCTAssertEqual(pushNotification.title, title);
                                 XCTAssertEqual(pushNotification.message, nil);
                                 XCTAssertEqual(pushNotification.customData, customData);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
#if !TARGET_OS_OSX
  XCTAssertTrue(result);
#endif
  [pushMock stopMocking];
}

- (void)testNotificationReceivedWithAlertString {

  // If
  XCTestExpectation *notificationReceived = [self expectationWithDescription:@"Valid notification received."];
  id pushMock = OCMPartialMock(self.sut);
  OCMStub([pushMock sharedInstance]).andReturn(pushMock);
  OCMStub([pushMock canBeUsed]).andReturn(YES);
  [MSPush resetSharedInstance];
  id pushDelegateMock = OCMProtocolMock(@protocol(MSPushDelegate));
  __block MSPushNotification *pushNotification = nil;
  OCMStub([pushDelegateMock push:self.sut didReceivePushNotification:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&pushNotification atIndex:3];
  });
  [MSPush setDelegate:pushDelegateMock];
  __block NSString *message = @"notification message";
  __block NSDictionary *customData = @{@"key" : @"value"};
  NSDictionary *userInfo =
      @{kMSPushNotificationApsKey : @{kMSPushNotificationAlertKey : message}, kMSPushNotificationCustomDataKey : customData};
#if TARGET_OS_OSX
  id userNotificationUserInfoMock = OCMClassMock([NSUserNotification class]);
  id notificationMock = OCMClassMock([NSNotification class]);
  NSDictionary *notificationUserInfo = @{NSApplicationLaunchUserNotificationKey : userNotificationUserInfoMock};
  OCMStub([notificationMock userInfo]).andReturn(notificationUserInfo);
  OCMStub([userNotificationUserInfoMock userInfo]).andReturn(userInfo);
#endif

// When
#if TARGET_OS_OSX
  [self.sut applicationDidFinishLaunching:notificationMock];
#else
  BOOL result = [MSPush didReceiveRemoteNotification:userInfo];
#endif
  dispatch_async(dispatch_get_main_queue(), ^{
    [notificationReceived fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
#if TARGET_OS_OSX
                                 OCMVerify([pushMock didReceiveUserNotification:userNotificationUserInfoMock]);
#else
        OCMVerify([pushMock didReceiveRemoteNotification:userInfo]);
#endif
                                 OCMVerify([pushDelegateMock push:self.sut didReceivePushNotification:OCMOCK_ANY]);
                                 XCTAssertNotNil(pushNotification);
                                 XCTAssertEqual(pushNotification.title, @"");
                                 XCTAssertEqual(pushNotification.message, message);
                                 XCTAssertEqual(pushNotification.customData, customData);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
#if !TARGET_OS_OSX
  XCTAssertTrue(result);
#endif
  [pushMock stopMocking];
}

- (void)testNotificationReceivedForNonAppCenterNotification {

  // If
  XCTestExpectation *notificationReceived = [self expectationWithDescription:@"Invalid notification received."];
  id pushMock = OCMPartialMock(self.sut);
  OCMStub([pushMock sharedInstance]).andReturn(pushMock);
  [MSPush resetSharedInstance];
  id pushDelegateMock = OCMProtocolMock(@protocol(MSPushDelegate));
  OCMReject([pushDelegateMock push:self.sut didReceivePushNotification:OCMOCK_ANY]);
  __block MSPushNotification *pushNotification = nil;
  OCMStub([pushDelegateMock push:self.sut didReceivePushNotification:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&pushNotification atIndex:3];
  });
  [MSPush setDelegate:pushDelegateMock];
  NSDictionary *invalidUserInfo = @{
    kMSPushNotificationApsKey : @{
      kMSPushNotificationAlertKey :
          @{kMSPushNotificationTitleKey : @"notification title", kMSPushNotificationMessageKey : @"notification message"}
    }
  };
#if TARGET_OS_OSX
  id userNotificationUserInfoMock = OCMClassMock([NSUserNotification class]);
  id notificationMock = OCMClassMock([NSNotification class]);
  NSDictionary *notificationUserInfo = @{NSApplicationLaunchUserNotificationKey : userNotificationUserInfoMock};
  OCMStub([notificationMock userInfo]).andReturn(notificationUserInfo);
  OCMStub([userNotificationUserInfoMock userInfo]).andReturn(invalidUserInfo);
#endif

// When
#if TARGET_OS_OSX
  [self.sut applicationDidFinishLaunching:notificationMock];
#else
  BOOL result = [MSPush didReceiveRemoteNotification:invalidUserInfo];
  XCTAssertFalse(result);
#endif
  dispatch_async(dispatch_get_main_queue(), ^{
    [notificationReceived fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 // Then
                                 OCMVerifyAll(pushDelegateMock);
                                 XCTAssertNil(pushNotification);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
  [pushMock stopMocking];
}

- (void)testPushAppDelegateCallbacks {

// If
#if TARGET_OS_OSX
  id applicationMock = OCMClassMock([NSApplication class]);
#else
  id applicationMock = OCMClassMock([UIApplication class]);
#endif
  id pushMock = OCMPartialMock(self.sut);
  OCMStub([pushMock sharedInstance]).andReturn(pushMock);
  [MSPush resetSharedInstance];
  MSPushAppDelegate *delegate = [MSPushAppDelegate new];

  // When
  id deviceTokenMock = OCMClassMock([NSData class]);
  [delegate application:applicationMock didRegisterForRemoteNotificationsWithDeviceToken:deviceTokenMock];

  // Then
  OCMVerify([pushMock didRegisterForRemoteNotificationsWithDeviceToken:deviceTokenMock]);

  // When
  id errorMock = OCMClassMock([NSError class]);
  [delegate application:applicationMock didFailToRegisterForRemoteNotificationsWithError:errorMock];

  // Then
  OCMVerify([pushMock didFailToRegisterForRemoteNotificationsWithError:errorMock]);

  // When
  id userInfoMock = OCMClassMock([NSDictionary class]);
  [delegate application:applicationMock didReceiveRemoteNotification:userInfoMock];

  // Then
  OCMVerify([pushMock didReceiveRemoteNotification:userInfoMock]);

#if !TARGET_OS_OSX

  // When
  XCTestExpectation *notificationReceived = [self expectationWithDescription:@"Valid notification received."];
  [delegate application:applicationMock
      didReceiveRemoteNotification:userInfoMock
            fetchCompletionHandler:^(__unused UIBackgroundFetchResult result) {
              [notificationReceived fulfill];
            }];

  // Then
  OCMVerify([pushMock didReceiveRemoteNotification:userInfoMock]);
  [self waitForExpectations:@[ notificationReceived ] timeout:0];
#endif

  [pushMock stopMocking];
}

#if TARGET_OS_OSX

- (void)testUserNotificationCenterDelegateBeforePushStart {

  // If
  id userNotificationMock = OCMClassMock([NSUserNotification class]);
  id userNotificationCenterDelegateMock = OCMProtocolMock(@protocol(NSUserNotificationCenterDelegate));
  id userNotificationCenterMock = OCMClassMock([NSUserNotificationCenter class]);
  OCMStub([userNotificationCenterMock defaultUserNotificationCenter]).andReturn(userNotificationCenterMock);
  OCMStub([userNotificationCenterMock delegate]).andReturn(userNotificationCenterDelegateMock);
  self.sut = [MSPush new];
  id pushMock = OCMPartialMock(self.sut);

  // When
  [pushMock userNotificationCenter:userNotificationCenterMock didActivateNotification:userNotificationMock];

  // Then
  OCMVerify([pushMock didReceiveUserNotification:userNotificationMock]);
  OCMVerify([userNotificationCenterDelegateMock userNotificationCenter:userNotificationCenterMock
                                               didActivateNotification:userNotificationMock]);

  [pushMock stopMocking];
}

- (void)testUserNotificationCenterDelegateAfterPushStart {

  // If
  id userNotificationMock = OCMClassMock([NSUserNotification class]);
  id userNotificationCenterDelegateMock = OCMProtocolMock(@protocol(NSUserNotificationCenterDelegate));
  id userNotificationCenterMock = OCMClassMock([NSUserNotificationCenter class]);
  OCMStub([userNotificationCenterMock defaultUserNotificationCenter]).andReturn(userNotificationCenterMock);
  self.sut = [MSPush new];
  id pushMock = OCMPartialMock(self.sut);

  // When
  [pushMock userNotificationCenter:userNotificationCenterMock didActivateNotification:userNotificationMock];

  // Then
  OCMVerify([pushMock didReceiveUserNotification:userNotificationMock]);

  // When
  [pushMock observeValueForKeyPath:@"delegate"
                          ofObject:nil
                            change:@{@"new" : userNotificationCenterDelegateMock}
                           context:[MSPush userNotificationCenterDelegateContext]];
  [pushMock userNotificationCenter:userNotificationCenterMock didActivateNotification:userNotificationMock];

  // Then
  OCMVerify([pushMock didReceiveUserNotification:userNotificationMock]);
  OCMVerify([userNotificationCenterDelegateMock userNotificationCenter:userNotificationCenterMock
                                               didActivateNotification:userNotificationMock]);

  [pushMock stopMocking];
}

- (void)testForwardInvocationWithUserNotificationCenterDelegateSelector {

  // If
  id invocationMock = OCMClassMock([NSInvocation class]);
  OCMStub([invocationMock selector]).andReturn(@selector(userNotificationCenter:didDeliverNotification:));
  id userNotificationCenterDelegateMock = OCMProtocolMock(@protocol(NSUserNotificationCenterDelegate));
  id userNotificationCenterMock = OCMClassMock([NSUserNotificationCenter class]);
  OCMStub([userNotificationCenterMock defaultUserNotificationCenter]).andReturn(userNotificationCenterMock);
  OCMStub([userNotificationCenterMock delegate]).andReturn(userNotificationCenterDelegateMock);

  // forwardInvocation is used by OCMock. Shouldn't mock MSPush for success test.
  self.sut = [MSPush new];

  // When
  [self.sut forwardInvocation:invocationMock];

  // Then
  OCMVerify([invocationMock invokeWithTarget:userNotificationCenterDelegateMock]);

  [invocationMock stopMocking];
}

- (void)testForwardInvocationWithInvalidSelector {

  // If
  id invocationMock = OCMClassMock([NSInvocation class]);
  OCMStub([invocationMock selector]).andReturn(NSSelectorFromString(@"something:"));
  id userNotificationCenterDelegateMock = OCMProtocolMock(@protocol(NSUserNotificationCenterDelegate));
  id userNotificationCenterMock = OCMClassMock([NSUserNotificationCenter class]);
  OCMStub([userNotificationCenterMock defaultUserNotificationCenter]).andReturn(userNotificationCenterMock);
  OCMStub([userNotificationCenterMock delegate]).andReturn(userNotificationCenterDelegateMock);

  // forwardInvocation is used by OCMock. Shouldn't mock MSPush for success test.
  self.sut = [MSPush new];

  // When/Then
  XCTAssertThrows([self.sut forwardInvocation:invocationMock]);

  [invocationMock stopMocking];
}

#endif

@end
