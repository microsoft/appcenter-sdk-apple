// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSIdentityAppDelegate.h"
#import "MSIdentityPrivate.h"
#import "MSTestFrameworks.h"

@interface MSIdentityAppDelegateTests : XCTestCase

@end

@implementation MSIdentityAppDelegateTests

- (void)testOpenURLIsCalled {

  // If
  MSIdentityAppDelegate *appDelegate = [[MSIdentityAppDelegate alloc] init];
  id identityMock = OCMPartialMock([MSIdentity sharedInstance]);
  __block int count = 0;
  OCMStub([identityMock openURL:OCMOCK_ANY]).andDo(^(__unused NSInvocation *invocation) {
    count++;
  });
  NSURL *url = [[NSURL alloc] init];

  // When
  [appDelegate application:[UIApplication sharedApplication] openURL:url options:@{} returnedValue:YES];

  // Then
  OCMVerify([identityMock openURL:url]);

  // When
  [appDelegate application:[UIApplication sharedApplication] openURL:url sourceApplication:@"" annotation:@"" returnedValue:YES];

  // Then
  OCMVerify([identityMock openURL:url]);
  XCTAssertEqual(count, 2);
}

@end
