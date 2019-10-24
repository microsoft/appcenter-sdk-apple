// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAppCenter.h"
#import "MSAppCenterInternal.h"
#import "MSServiceNotificationDelegate.h"
#import "MSTestFrameworks.h"

@interface MSServiceNotificationDelegateTests : XCTestCase

@end

@implementation MSServiceNotificationDelegateTests

- (void)testNoRegisteredDelegate {
  id appCenterMock = OCMPartialMock([MSAppCenter sharedInstance]);
  // creating delegates
  id delegate = OCMProtocolMock(@protocol(MSServiceNotificationDelegate));

  // notification data
  NSDictionary<NSString *, NSString *> *data = @{@"key" : @"value"};

  // When
  [appCenterMock receiveServiceNotification:data];

  // Then
  OCMReject([delegate appCenter:[MSAppCenter sharedInstance] didReceiveServiceNotification:data]);
}

- (void)testAddDelegate {
  id appCenterMock = OCMPartialMock([MSAppCenter sharedInstance]);
  // creating delegates
  id delegate1 = OCMProtocolMock(@protocol(MSServiceNotificationDelegate));
  id delegate2 = OCMProtocolMock(@protocol(MSServiceNotificationDelegate));

  // registering delegates
  [appCenterMock addServiceNotificationDelegate:delegate1];
  [appCenterMock addServiceNotificationDelegate:delegate2];

  // notification data
  NSDictionary<NSString *, NSString *> *data = @{@"key" : @"value"};

  // When
  [appCenterMock receiveServiceNotification:data];

  // Then
  OCMVerify([delegate1 appCenter:[MSAppCenter sharedInstance] didReceiveServiceNotification:data]);
  OCMVerify([delegate2 appCenter:[MSAppCenter sharedInstance] didReceiveServiceNotification:data]);
}

- (void)testRemoveAllDelegate {
  id appCenterMock = OCMPartialMock([MSAppCenter sharedInstance]);
  // creating delegates
  id delegate1 = OCMProtocolMock(@protocol(MSServiceNotificationDelegate));
  id delegate2 = OCMProtocolMock(@protocol(MSServiceNotificationDelegate));

  // registering delegates
  [appCenterMock addServiceNotificationDelegate:delegate1];
  [appCenterMock addServiceNotificationDelegate:delegate2];

  // unregistering delegates
  [appCenterMock removeServiceNotificationDelegate:delegate1];
  [appCenterMock removeServiceNotificationDelegate:delegate2];

  // notification data
  NSDictionary<NSString *, NSString *> *data = @{@"key" : @"value"};

  // When
  [appCenterMock receiveServiceNotification:data];

  // Then
  OCMReject([delegate1 appCenter:[MSAppCenter sharedInstance] didReceiveServiceNotification:data]);
  OCMReject([delegate2 appCenter:[MSAppCenter sharedInstance] didReceiveServiceNotification:data]);
}

- (void)testRemoveSomeDelegate {
  id appCenterMock = OCMPartialMock([MSAppCenter sharedInstance]);
  // creating delegates
  id delegate1 = OCMProtocolMock(@protocol(MSServiceNotificationDelegate));
  id delegate2 = OCMProtocolMock(@protocol(MSServiceNotificationDelegate));

  // registering delegates
  [appCenterMock addServiceNotificationDelegate:delegate1];
  [appCenterMock addServiceNotificationDelegate:delegate2];

  // unregistering delegates
  [appCenterMock removeServiceNotificationDelegate:delegate2];

  // notification data
  NSDictionary<NSString *, NSString *> *data = @{@"key" : @"value"};

  // When
  [appCenterMock receiveServiceNotification:data];

  // Then
  OCMVerify([delegate1 appCenter:[MSAppCenter sharedInstance] didReceiveServiceNotification:data]);
  OCMReject([delegate2 appCenter:[MSAppCenter sharedInstance] didReceiveServiceNotification:data]);
}

- (void)testRemoveDelegateThatDoesnotExist {

  id appCenterMock = OCMPartialMock([MSAppCenter sharedInstance]);
  // creating delegates
  id delegate = OCMProtocolMock(@protocol(MSServiceNotificationDelegate));

  // unregistering delegates
  [appCenterMock removeServiceNotificationDelegate:delegate];

  // notification data
  NSDictionary<NSString *, NSString *> *data = @{@"key" : @"value"};

  // When
  [appCenterMock receiveServiceNotification:data];

  // Then
  OCMReject([delegate appCenter:[MSAppCenter sharedInstance] didReceiveServiceNotification:data]);
}

@end
