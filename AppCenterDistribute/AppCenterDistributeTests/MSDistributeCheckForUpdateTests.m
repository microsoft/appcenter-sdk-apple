// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDistributePrivate.h"
#import "MSMockUserDefaults.h"
#import "MSTestFrameworks.h"

@interface MSDistributeCheckForUpdateTests : XCTestCase

@property(nonatomic) id settingsMock;
@property(nonatomic) id bundleMock;

@end

@implementation MSDistributeCheckForUpdateTests

- (void)setUp {
  [super setUp];
  self.settingsMock = [MSMockUserDefaults new];
  
  // Mock NSBundle
  self.bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([self.bundleMock mainBundle]).andReturn(self.bundleMock);
}

- (void)tearDown {
  [super tearDown];
  [self.settingsMock stopMocking];
  [self.bundleMock stopMocking];
}

- (void)testCheckForUpdateAuthenticateWhenItHasNotAuthenticated {
  
  // If
  NSDictionary<NSString *, id> *plist = @{@"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1"};
  OCMStub([self.bundleMock infoDictionary]).andReturn(plist);
  MSDistribute *distribute = [MSDistribute new];
  id distributeMock = OCMPartialMock(distribute);
  OCMStub([distributeMock canBeUsed]).andReturn(YES);
  
  // When
  [distribute checkForUpdate];
  
  // Then
  XCTAssertTrue(distribute.checkForUpdateFlag);
  OCMVerify([distributeMock requestInstallInformationWith:OCMOCK_ANY]);
}

- (void)testCheckForUpdateWhenItHasAuthenticated {
}

- (void)testCheckForUpdateEvenThoughAutomaticUpdateIsDisabled {
}

- (void)testCheckForUpdateDoesNotUpdateWhenAutomaticAuthenticationIsDisabled {

  // TODO: This test should be written when a new flag is added.
}

@end
