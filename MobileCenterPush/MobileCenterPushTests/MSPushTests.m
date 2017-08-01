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
}

- (void)testNotificationReceivedWithAlertObject {

  // If
  XCTestExpectation *notificationReceived = [self expectationWithDescription:@"Valid notification received."];
  id pushMock = OCMPartialMock(self.sut);
  OCMStub([pushMock sharedInstance]).andReturn(pushMock);
  [MSPush resetSharedInstance];
  id pushDelegateMock = OCMProtocolMock(@protocol(MSPushDelegate));
  __block MSPushNotification *pushNotification = nil;
  OCMStub([pushDelegateMock push:self.sut didReceivePushNotification:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
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
  BOOL result = [MSPush didReceiveNotification:notificationMock];
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
                                 OCMVerify([pushMock didReceiveNotification:notificationMock]);
#else
        OCMVerify([pushMock didReceiveRemoteNotification:userInfo]);
#endif
                                 OCMVerify([pushDelegateMock push:self.sut didReceivePushNotification:[OCMArg any]]);
                                 XCTAssertNotNil(pushNotification);
                                 XCTAssertEqual(pushNotification.title, title);
                                 XCTAssertEqual(pushNotification.message, message);
                                 XCTAssertEqual(pushNotification.customData, customData);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
  XCTAssertTrue(result);
}

- (void)testNotificationReceivedWithAlertString {

  // If
  XCTestExpectation *notificationReceived = [self expectationWithDescription:@"Valid notification received."];
  id pushMock = OCMPartialMock(self.sut);
  OCMStub([pushMock sharedInstance]).andReturn(pushMock);
  [MSPush resetSharedInstance];
  id pushDelegateMock = OCMProtocolMock(@protocol(MSPushDelegate));
  __block MSPushNotification *pushNotification = nil;
  OCMStub([pushDelegateMock push:self.sut didReceivePushNotification:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
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
  BOOL result = [MSPush didReceiveNotification:notificationMock];
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
                                 OCMVerify([pushMock didReceiveNotification:notificationMock]);
#else
        OCMVerify([pushMock didReceiveRemoteNotification:userInfo]);
#endif
                                 OCMVerify([pushDelegateMock push:self.sut didReceivePushNotification:[OCMArg any]]);
                                 XCTAssertNotNil(pushNotification);
                                 XCTAssertEqual(pushNotification.title, @"");
                                 XCTAssertEqual(pushNotification.message, message);
                                 XCTAssertEqual(pushNotification.customData, customData);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
  XCTAssertTrue(result);
}

- (void)testNotificationReceivedForNonMobileCenterNotification {

  // If
  XCTestExpectation *notificationReceived = [self expectationWithDescription:@"Invalid notification received."];
  id pushMock = OCMPartialMock(self.sut);
  OCMStub([pushMock sharedInstance]).andReturn(pushMock);
  [MSPush resetSharedInstance];
  id pushDelegateMock = OCMProtocolMock(@protocol(MSPushDelegate));
  __block MSPushNotification *pushNotification = nil;
  OCMStub([pushDelegateMock push:self.sut didReceivePushNotification:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
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
  BOOL result = [MSPush didReceiveNotification:notificationMock];
#else
  BOOL result = [MSPush didReceiveRemoteNotification:invalidUserInfo];
#endif
  XCTAssertFalse(result);
  dispatch_async(dispatch_get_main_queue(), ^{
    [notificationReceived fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
#if TARGET_OS_OSX
                                 OCMReject([pushMock didReceiveNotification:[OCMArg any]]);
#else
        OCMReject([pushMock didReceiveRemoteNotification:[OCMArg any]]);
#endif
                                 OCMReject([pushDelegateMock push:self.sut didReceivePushNotification:[OCMArg any]]);
                                 XCTAssertNil(pushNotification);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

#if TARGET_OS_OSX
- (void)testUserNotificationCenterDelegateBySwizzle {

  // If
  id userNotificationCenterMock = OCMClassMock([NSUserNotificationCenter class]);
  id notificationMock = OCMClassMock([NSNotification class]);
  id pushMock = OCMPartialMock(self.sut);
  OCMStub([userNotificationCenterMock defaultUserNotificationCenter]).andReturn(userNotificationCenterMock);
  OCMStub([pushMock sharedInstance]).andReturn(pushMock);
  [MSPush resetSharedInstance];

  // When
  MSPushAppDelegate *delegate = [MSPushAppDelegate new];
  [delegate applicationDidFinishLaunching:notificationMock];

  // Then
  OCMVerify([userNotificationCenterMock setDelegate:delegate]);
  OCMVerify([pushMock didReceiveNotification:notificationMock]);
}
#endif

@end
