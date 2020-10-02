// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACDistribute.h"
#import "MSACDistributeAppDelegate.h"
#import "MSACDistributePrivate.h"
#import "MSACTestFrameworks.h"

@interface MSACDistributeAppDelegateTests : XCTestCase

@end

@implementation MSACDistributeAppDelegateTests

- (void)testOpenURLIsCalled {

  // If
  MSACDistributeAppDelegate *appDelegate = [[MSACDistributeAppDelegate alloc] init];
  id distributeMock = OCMPartialMock([MSACDistribute sharedInstance]);
  __block int count = 0;
  OCMStub([distributeMock openURL:OCMOCK_ANY]).andDo(^(__unused NSInvocation *invocation) {
    count++;
  });
  NSURL *url = [[NSURL alloc] init];

  // When
  [appDelegate application:[UIApplication sharedApplication] openURL:url options:@{} returnedValue:YES];

  // Then
  OCMVerify([distributeMock openURL:url]);

  // When
  [appDelegate application:[UIApplication sharedApplication] openURL:url sourceApplication:@"" annotation:@"" returnedValue:YES];

  // Then
  OCMVerify([distributeMock openURL:url]);
  XCTAssertEqual(count, 2);
}

@end
