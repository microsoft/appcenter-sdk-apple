// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSALLoggerConfig.h"
#import "MSAuthAppDelegate.h"
#import "MSAuthPrivate.h"
#import "MSTestFrameworks.h"

@interface MSAuthAppDelegateTests : XCTestCase

@end

@implementation MSAuthAppDelegateTests

- (void)testOpenURLIsCalled {

  // If
  MSAuthAppDelegate *appDelegate = [[MSAuthAppDelegate alloc] init];
  id authMock = OCMPartialMock([MSAuth sharedInstance]);
  __block int count = 0;
  OCMStub([authMock openURL:OCMOCK_ANY options:OCMOCK_ANY]).andDo(^(__unused NSInvocation *invocation) {
    count++;
  });
  NSURL *url = [[NSURL alloc] init];
  NSDictionary *options = @{UIApplicationOpenURLOptionsSourceApplicationKey : @"valid_app"};

  // When
  [appDelegate application:[UIApplication sharedApplication] openURL:url options:options returnedValue:YES];

  // Then
  OCMVerify([authMock openURL:url options:options]);

  // When
  [appDelegate application:[UIApplication sharedApplication] openURL:url sourceApplication:@"" annotation:@"" returnedValue:YES];

  // Then
  OCMVerify([authMock openURL:url options:options]);
  XCTAssertEqual(count, 2);
  [MSAuth resetSharedInstance];
}

@end
