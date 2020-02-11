// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDistributePrivate.h"
#import "MSMockUserDefaults.h"
#import "MSTestFrameworks.h"

@interface MSDistributeCheckForUpdateTests : XCTestCase

@property(nonatomic) id settingsMock;

@end

@implementation MSDistributeCheckForUpdateTests

- (void)setUp {
  [super setUp];
  self.settingsMock = [MSMockUserDefaults new];
}

- (void)tearDown {
  [super tearDown];
  [self.settingsMock stopMocking];
}

- (void)testCheckForUpdateAuthenticateWhenItHasNotAuthenticated {
  
  // If
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
