// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSBasicMachOParser.h"
#import "MSChannelGroupProtocol.h"
#import "MSDistributePrivate.h"
#import "MSMockKeychainUtil.h"
#import "MSMockUserDefaults.h"
#import "MSTestFrameworks.h"
#import "MSUtility+StringFormatting.h"

static NSString *const kMSTestAppSecret = @"IAMSECRET";

@interface MSDistributeCheckForUpdateTests : XCTestCase

@property(nonatomic) id settingsMock;
@property(nonatomic) id bundleMock;
@property(nonatomic) id keychainUtilMock;
@property(nonatomic) id parserMock;

@end

@implementation MSDistributeCheckForUpdateTests

- (void)setUp {
  [super setUp];
  [MSDistribute resetSharedInstance];
  self.settingsMock = [MSMockUserDefaults new];
  self.keychainUtilMock = [MSMockKeychainUtil new];
  
  // Mock NSBundle
  self.bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([self.bundleMock mainBundle]).andReturn(self.bundleMock);
  
  // Parser mock
  id parserMock = OCMClassMock([MSBasicMachOParser class]);
  OCMStub([parserMock machOParserForMainBundle]).andReturn(parserMock);
  OCMStub([parserMock uuid]).andReturn([[NSUUID alloc] initWithUUIDString:@"CD55E7A9-7AD1-4CA6-B722-3D133F487DA9"]);
}

- (void)tearDown {
  [super tearDown];
  [self.settingsMock stopMocking];
  [self.keychainUtilMock stopMocking];
  [self.bundleMock stopMocking];
  [self.parserMock stopMocking];
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

- (void)testDisableAutomaticCheckForUpdateBeforeStart {

  // If
  MSDistribute *distribute = [MSDistribute sharedInstance];
  distribute.automaticCheckForUpdateDisabled = NO;

  // When
  [MSDistribute disableAutomaticCheckForUpdate];

  // Then
  XCTAssertTrue(distribute.automaticCheckForUpdateDisabled);
}

- (void)testAutomaticCheckForUpdateDisabledDoesNotChangeAfterStart {

  // If
  MSDistribute *distribute = [MSDistribute sharedInstance];
  [distribute startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                          appSecret:kMSTestAppSecret
            transmissionTargetToken:nil
                    fromApplication:YES];

  // When
  [MSDistribute disableAutomaticCheckForUpdate];

  // Then
  XCTAssertFalse(distribute.automaticCheckForUpdateDisabled);
}

- (void)testCheckForUpdate {

  // If
  NSString *updateToken = @"UpdateToken";
  NSString *distributionGroupId = @"DistributionGroupId";
  NSString *releaseHash = @"ReleaseHash";
  id distributeMock = OCMPartialMock([MSDistribute new]);

  // When
  [distributeMock checkForUpdateWithUpdateToken:updateToken distributionGroupId:distributionGroupId releaseHash:releaseHash];

  // Then
  OCMVerify([distributeMock checkLatestRelease:updateToken distributionGroupId:distributionGroupId releaseHash:releaseHash]);

  // Cleanup
  [distributeMock stopMocking];
}


- (void)testCheckForUpdateAuthenticateWhenItHasNotAuthenticated {
  
  // If
  NSDictionary<NSString *, id> *plist = @{@"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1"};
  OCMStub([self.bundleMock infoDictionary]).andReturn(plist);
  MSDistribute *distribute = [MSDistribute new];
  id distributeMock = OCMPartialMock(distribute);
  OCMStub([distributeMock canBeUsed]).andReturn(YES);
  
  // When
  [distribute setUpdateTrack:MSUpdateTrackPrivate];
  [distribute checkForUpdate];
  
  // Then
  XCTAssertTrue(distribute.checkForUpdateFlag);
  OCMVerify([distributeMock requestInstallInformationWith:OCMOCK_ANY]);
  
  // Clear
  [distributeMock stopMocking];
}

- (void)testCheckForUpdateWhenItHasAuthenticated {
  
  // If
  NSDictionary<NSString *, id> *plist = @{@"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1"};
  OCMStub([self.bundleMock infoDictionary]).andReturn(plist);
  MSDistribute *distribute = [MSDistribute new];
  id distributeMock = OCMPartialMock(distribute);
  OCMStub([distributeMock canBeUsed]).andReturn(YES);
  
  // When
  //TODO unsure what needs to be done to simulate authentication in this case
  [distribute setUpdateTrack:MSUpdateTrackPublic];
  [distribute checkForUpdate];
  
  // Then
  XCTAssertTrue(distribute.checkForUpdateFlag);
  //TODO is this the right verify?
  OCMVerify([distributeMock checkForUpdateWithUpdateToken:OCMOCK_ANY distributionGroupId:OCMOCK_ANY releaseHash:OCMOCK_ANY]);
  
  // Clear
  [distributeMock stopMocking];
}

- (void)testCheckForUpdateEvenThoughAutomaticUpdateIsDisabled {
  
  // If
  NSDictionary<NSString *, id> *plist = @{@"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1"};
  OCMStub([self.bundleMock infoDictionary]).andReturn(plist);
  MSDistribute *distribute = [MSDistribute new];
  id distributeMock = OCMPartialMock(distribute);
  OCMStub([distributeMock canBeUsed]).andReturn(YES);
  
  // When
  [distribute setUpdateTrack:MSUpdateTrackPublic];
  [distribute disableAutomaticCheckForUpdate];
  [distribute checkForUpdate];
  
  // Then
  XCTAssertTrue(distribute.checkForUpdateFlag);
  OCMVerify([distributeMock checkForUpdateWithUpdateToken:OCMOCK_ANY distributionGroupId:OCMOCK_ANY releaseHash:OCMOCK_ANY]);
  
  // Clear
  [distributeMock stopMocking];
}

- (void)testCheckForUpdateDoesNotUpdateWhenAutomaticAuthenticationIsDisabled {
  
  // TODO: This test should be written when a new flag is added.
}

- (void)testCheckForUpdateDoesNotCheckWhenDisabled {

  // If
  NSString *updateToken = @"UpdateToken";
  NSString *distributionGroupId = @"DistributionGroupId";
  NSString *releaseHash = @"ReleaseHash";
  MSDistribute *distribute = [MSDistribute sharedInstance];
  id distributeMock = OCMPartialMock(distribute);
  [distributeMock setValue:@(YES) forKey:@"updateFlowInProgress"];
  [distributeMock setValue:@(YES) forKey:@"automaticCheckForUpdateDisabled"];
  OCMReject([distributeMock checkLatestRelease:updateToken distributionGroupId:distributionGroupId releaseHash:releaseHash]);

  // When
  [distributeMock checkForUpdateWithUpdateToken:updateToken distributionGroupId:distributionGroupId releaseHash:releaseHash];

  // Then
  XCTAssertFalse(distribute.updateFlowInProgress);
  OCMVerifyAll(distributeMock);

  // Cleanup
  [distributeMock stopMocking];
}

- (void)testCheckForUpdateDoesNotOpenBrowserOrTesterAppAtStartWhenDisabled {

  // If
  id utilityMock = OCMClassMock([MSUtility class]);
  OCMStub(ClassMethod([utilityMock sha256:OCMOCK_ANY])).andReturn(@"RELEASEHASH");
  NSDictionary<NSString *, id> *plist = @{@"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1"};
  
  // Bundle mock
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);
  OCMStub([bundleMock infoDictionary]).andReturn(plist);
  
  // Distribute Mock
  MSDistribute *distribute = [MSDistribute sharedInstance];
  __block id distributeMock = OCMPartialMock(distribute);
  OCMStub([distributeMock checkForUpdatesAllowed]).andReturn(YES);
  OCMStub([distributeMock buildTokenRequestURLWithAppSecret:OCMOCK_ANY releaseHash:OCMOCK_ANY isTesterApp:false])
      .andReturn([NSURL URLWithString:@"https://some_url"]);
  OCMStub([distributeMock buildTokenRequestURLWithAppSecret:OCMOCK_ANY releaseHash:OCMOCK_ANY isTesterApp:true])
      .andReturn([NSURL URLWithString:@"some_url://"]);
  OCMStub([distributeMock openUrlUsingSharedApp:OCMOCK_ANY]).andReturn(NO);
  OCMReject([distributeMock openUrlInAuthenticationSessionOrSafari:OCMOCK_ANY]);
  XCTestExpectation *expectation = [self expectationWithDescription:@"Start update processed"];

  // When
  [MSDistribute disableAutomaticCheckForUpdate];
  distribute.updateTrack = MSUpdateTrackPrivate;
  [distribute startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                          appSecret:kMSTestAppSecret
            transmissionTargetToken:nil
                    fromApplication:YES];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 // Then
                                 OCMVerifyAll(distributeMock);
                                 XCTAssertFalse(distribute.updateFlowInProgress);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  // Cleanup
  [distributeMock stopMocking];
  [bundleMock stopMocking];
  [utilityMock stopMocking];
}

@end
