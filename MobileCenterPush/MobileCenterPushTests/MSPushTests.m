#import <Foundation/Foundation.h>
#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#endif
#import "MSService.h"
#import "MSServiceAbstract.h"
#import "MSServiceInternal.h"
#import "MSPush.h"
#import "MSPushAppDelegate.h"
#import "MSPushLog.h"
#import "MSPushNotification.h"
#import "MSPushPrivate.h"
#import "MSPushTestUtil.h"
#import "MSTestFrameworks.h"

static NSString *const kMSTestAppSecret = @"TestAppSecret";
static NSString *const kMSTestPushToken = @"TestPushToken";

@interface MSPushTests : XCTestCase

@property(nonatomic) MSPush *sut;
@property(nonatomic) id settingsMock;

@end

@interface MSPush ()

- (void)channel:(id)channel willSendLog:(id<MSLog>)log;

- (void)channel:(id<MSChannel>)channel didSucceedSendingLog:(id<MSLog>)log;

- (void)channel:(id<MSChannel>)channel didFailSendingLog:(id<MSLog>)log withError:(NSError *)error;

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
  self.sut = [MSPush new];
}

- (void)tearDown {
  [super tearDown];
  [MSPush resetSharedInstance];
}

#pragma mark - Tests

- (void)testApplyEnabledStateWorks {

  // If
  [[MSPush sharedInstance] startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];
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

- (void)testSendPushTokenMethod {

  // Then
  XCTAssertFalse(self.sut.pushTokenHasBeenSent);

  // When
  [self.sut sendPushToken:kMSTestPushToken];

  // Then
  XCTAssertTrue(self.sut.pushTokenHasBeenSent);
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

  // When
  [MSPush didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];

  // Then
  OCMVerify([pushMock didRegisterForRemoteNotificationsWithDeviceToken:deviceToken]);
  OCMVerify([pushMock convertTokenToString:deviceToken]);
  OCMVerify([pushMock sendPushToken:pushToken]);
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

- (void)testNotificationReceivedWithAlertObject {

  // If
  XCTestExpectation *notificationReceived = [self expectationWithDescription:@"Valid notification received."];
  id pushMock = OCMPartialMock(self.sut);
  OCMStub([pushMock sharedInstance]).andReturn(pushMock);
  [MSPush resetSharedInstance];
  id pushDelegateMock = OCMProtocolMock(@protocol(MSPushDelegate));
  __block MSPushNotification *pushNotification = nil;
  OCMStub([pushDelegateMock push:self.sut didReceivePushNotification:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&pushNotification atIndex:3];
  });
  [MSPush setDelegate:pushDelegateMock];
  __block NSString *title = @"notificationTitle";
  __block NSString *message = @"notificationMessage";
  __block NSDictionary *customData = @{ @"key" : @"value" };
  NSDictionary *userInfo =
      @{ @"aps" : @{@"alert" : @{@"title" : title, @"body" : message}},
         @"mobile_center" : customData };
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

- (void)testNotificationReceivedWithAlertString {

  // If
  XCTestExpectation *notificationReceived = [self expectationWithDescription:@"Valid notification received."];
  id pushMock = OCMPartialMock(self.sut);
  OCMStub([pushMock sharedInstance]).andReturn(pushMock);
  [MSPush resetSharedInstance];
  id pushDelegateMock = OCMProtocolMock(@protocol(MSPushDelegate));
  __block MSPushNotification *pushNotification = nil;
  OCMStub([pushDelegateMock push:self.sut didReceivePushNotification:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&pushNotification atIndex:3];
  });
  [MSPush setDelegate:pushDelegateMock];
  __block NSString *message = @"notificationMessage";
  __block NSDictionary *customData = @{ @"key" : @"value" };
  NSDictionary *userInfo = @{ @"aps" : @{@"alert" : message}, @"mobile_center" : customData };
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

- (void)testNotificationReceivedForNonMobileCenterNotification {

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
  NSDictionary *invalidUserInfo =
      @{ @"aps" : @{@"alert" : @{@"title" : @"notificationTitle", @"body" : @"notificationMessage"}} };
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

@end
