// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSBasicMachOParser.h"
#import "MSDistributePrivate.h"
#import "MSDistributeTestUtil.h"
#import "MSMockKeychainUtil.h"
#import "MSMockUserDefaults.h"
#import "MSTestFrameworks.h"

@interface MSDistributeCheckForUpdateTests : XCTestCase

@property(nonatomic) id settingsMock;
@property(nonatomic) id bundleMock;
@property(nonatomic) id keychainUtilMock;

@end

@implementation MSDistributeCheckForUpdateTests

- (void)setUp {
  [super setUp];
  self.settingsMock = [MSMockUserDefaults new];
  self.keychainUtilMock = [MSMockKeychainUtil new];
  
  // Mock NSBundle
  self.bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([self.bundleMock mainBundle]).andReturn(self.bundleMock);
}

- (void)tearDown {
  [super tearDown];
  [self.settingsMock stopMocking];
  [self.keychainUtilMock stopMocking];
  [self.bundleMock stopMocking];
}

- (void)testBypassCheckForUpdateIfNotEnabled {
  
  // If
  MSDistribute *distribute = [MSDistribute new];
  id distributeMock = OCMPartialMock(distribute);
  OCMStub([distributeMock canBeUsed]).andReturn(YES);
  [distributeMock setEnabled:NO];
  OCMReject([distributeMock startUpdate]);
  
  // When
  [distribute checkForUpdate];
  XCTAssertFalse(distribute.checkForUpdateFlag);
  
  // Clear
  [distributeMock stopMocking];
}

- (void)testBypassCheckForUpdateIfCantBeUsed {
  
  // If
  MSDistribute *distribute = [MSDistribute new];
  id distributeMock = OCMPartialMock(distribute);
  OCMStub([distributeMock canBeUsed]).andReturn(NO);
  OCMReject([distributeMock startUpdate]);
  
  // When
  [distribute checkForUpdate];
  XCTAssertFalse(distribute.checkForUpdateFlag);
  
  // Clear
  [distributeMock stopMocking];
}

- (void)testBypassCheckForUpdateIfUpdateRequestIdTokenExists {
  
  // If
  MSDistribute *distribute = [MSDistribute new];
  id distributeMock = OCMPartialMock(distribute);
  OCMStub([distributeMock canBeUsed]).andReturn(YES);
  [MS_USER_DEFAULTS setObject:@"testToken" forKey:kMSUpdateTokenRequestIdKey];
  OCMReject([distributeMock startUpdate]);
  
  // When
  [distribute checkForUpdate];
  XCTAssertFalse(distribute.checkForUpdateFlag);
  
  // Clear
  [distributeMock stopMocking];
}

- (void)testCheckForUpdateAuthenticateWhenItHasNotAuthenticated {
  
  // If
  NSDictionary<NSString *, id> *plist = @{@"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1"};
  OCMStub([self.bundleMock infoDictionary]).andReturn(plist);
  MSDistribute *distribute = [MSDistribute new];
  id distributeMock = OCMPartialMock(distribute);
  OCMStub([distributeMock canBeUsed]).andReturn(YES);
  id parserMock = OCMClassMock([MSBasicMachOParser class]);
  OCMStub([parserMock machOParserForMainBundle]).andReturn(parserMock);
  OCMStub([parserMock uuid]).andReturn([[NSUUID alloc] initWithUUIDString:@"CD55E7A9-7AD1-4CA6-B722-3D133F487DA9"]);
  
  // When
  [distribute setUpdateTrack:MSUpdateTrackPrivate];
  [distribute checkForUpdate];
  
  // Then
  XCTAssertTrue(distribute.checkForUpdateFlag);
  OCMVerify([distributeMock requestInstallInformationWith:OCMOCK_ANY]);
  
  // Clear
  [distributeMock stopMocking];
  [parserMock stopMocking];
}

- (void)testCheckForUpdateWhenItHasAuthenticated {
  
  // If
  NSDictionary<NSString *, id> *plist = @{@"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1"};
  OCMStub([self.bundleMock infoDictionary]).andReturn(plist);
  MSDistribute *distribute = [MSDistribute new];
  id distributeMock = OCMPartialMock(distribute);
  OCMStub([distributeMock canBeUsed]).andReturn(YES);
  id parserMock = OCMClassMock([MSBasicMachOParser class]);
  OCMStub([parserMock machOParserForMainBundle]).andReturn(parserMock);
  OCMStub([parserMock uuid]).andReturn([[NSUUID alloc] initWithUUIDString:@"CD55E7A9-7AD1-4CA6-B722-3D133F487DA9"]);
  
  // When
  //TODO unsure what needs to be done to simulate authentication in this case
  [distribute setUpdateTrack:MSUpdateTrackPublic];
  [distribute checkForUpdate];
  
  // Then
  XCTAssertTrue(distribute.checkForUpdateFlag);
  //TODO is this the right verify
  OCMVerify([distributeMock checkForUpdateWithUpdateToken:OCMOCK_ANY distributionGroupId:OCMOCK_ANY releaseHash:OCMOCK_ANY]);
  
  // Clear
  [distributeMock stopMocking];
  [parserMock stopMocking];
}

- (void)testCheckForUpdateEvenThoughAutomaticUpdateIsDisabled {
  
  // If
  NSDictionary<NSString *, id> *plist = @{@"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1"};
  OCMStub([self.bundleMock infoDictionary]).andReturn(plist);
  MSDistribute *distribute = [MSDistribute new];
  id distributeMock = OCMPartialMock(distribute);
  OCMStub([distributeMock canBeUsed]).andReturn(YES);
  id parserMock = OCMClassMock([MSBasicMachOParser class]);
  OCMStub([parserMock machOParserForMainBundle]).andReturn(parserMock);
  OCMStub([parserMock uuid]).andReturn([[NSUUID alloc] initWithUUIDString:@"CD55E7A9-7AD1-4CA6-B722-3D133F487DA9"]);
  
  // When
  [distribute setUpdateTrack:MSUpdateTrackPublic];
  distribute.distributeFlags ^= MSDistributeFlagsDisableAutomaticCheckForUpdate;
  [distribute checkForUpdate];
  
  // Then
  XCTAssertTrue(distribute.checkForUpdateFlag);
  OCMVerify([distributeMock checkForUpdateWithUpdateToken:OCMOCK_ANY distributionGroupId:OCMOCK_ANY releaseHash:OCMOCK_ANY]);
  
  // Clear
  [distributeMock stopMocking];
  [parserMock stopMocking];
}

- (void)testCheckForUpdateDoesNotUpdateWhenAutomaticAuthenticationIsDisabled {

  // TODO: This test should be written when a new flag is added.
}

@end
