#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSService.h"
#import "MSServiceAbstract.h"
#import "MSServiceInternal.h"
#import "MSPush.h"
#import "MSPushLog.h"
#import "MSPushNotification.h"
#import "MSPushPrivate.h"
#import "MSPushTestUtil.h"

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

- (void)testDidReceiveRemoteNotification {

  // If
  XCTestExpectation *didReceiveRemoteNotification =
      [self expectationWithDescription:@"didReceiveRemoteNotification Called."];
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

  // When
  BOOL result = [MSPush didReceiveRemoteNotification:userInfo];
  dispatch_async(dispatch_get_main_queue(), ^{
    [didReceiveRemoteNotification fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 OCMVerify(
                                     [pushMock didReceiveRemoteNotification:userInfo]);
                                 OCMVerify([pushDelegateMock push:self.sut didReceivePushNotification:OCMOCK_ANY]);
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

- (void)testDidReceiveRemoteNotificationForNonMobileCenterNotification {

  // If
  XCTestExpectation *didReceiveRemoteNotification =
      [self expectationWithDescription:@"didReceiveRemoteNotification Called."];
  id pushMock = OCMPartialMock(self.sut);
  OCMStub([pushMock sharedInstance]).andReturn(pushMock);
  [MSPush resetSharedInstance];
  id pushDelegateMock = OCMProtocolMock(@protocol(MSPushDelegate));
  __block MSPushNotification *pushNotification = nil;
  OCMStub([pushDelegateMock push:self.sut didReceivePushNotification:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&pushNotification atIndex:3];
  });
  [MSPush setDelegate:pushDelegateMock];

  NSArray *invalidUserInfos = @[
    @{ @"aps" : @{@"alert" : @{@"title" : @"notificationTitle", @"body" : @"notificationMessage"} } },
    @{ @"aps" : @{@"alert" : @"notificationMessage"} }
  ];

  // When
  for (NSDictionary *userInfo in invalidUserInfos) {
    BOOL result = [MSPush didReceiveRemoteNotification:userInfo];
    XCTAssertFalse(result);
  }
  dispatch_async(dispatch_get_main_queue(), ^{
    [didReceiveRemoteNotification fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 OCMReject([pushMock didReceiveRemoteNotification:OCMOCK_ANY]);
                                 OCMReject([pushDelegateMock push:self.sut didReceivePushNotification:OCMOCK_ANY]);
                                 XCTAssertNil(pushNotification);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

@end
