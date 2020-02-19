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

@property(nonatomic) MSDistribute *sut;
@property(nonatomic) id settingsMock;
@property(nonatomic) id bundleMock;
@property(nonatomic) id keychainUtilMock;
@property(nonatomic) id parserMock;

@end

@implementation MSDistributeCheckForUpdateTests

- (void)setUp {
  [super setUp];
  self.settingsMock = [MSMockUserDefaults new];
  self.keychainUtilMock = [MSMockKeychainUtil new];

  // Mock NSBundle.
  self.bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([self.bundleMock mainBundle]).andReturn(self.bundleMock);

  // Parser mock.
  id parserMock = OCMClassMock([MSBasicMachOParser class]);
  OCMStub([parserMock machOParserForMainBundle]).andReturn(parserMock);
  OCMStub([parserMock uuid]).andReturn([[NSUUID alloc] initWithUUIDString:@"CD55E7A9-7AD1-4CA6-B722-3D133F487DA9"]);

  // Distribute instance.
  [MSDistribute resetSharedInstance];
  self.sut = [MSDistribute sharedInstance];
}

- (void)tearDown {
  [super tearDown];
  [self.settingsMock stopMocking];
  [self.keychainUtilMock stopMocking];
  [self.bundleMock stopMocking];
  [self.parserMock stopMocking];
  self.sut = nil;
}

- (void)testBypassCheckForUpdateWhenDistributeIsDisabled {

  // If
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock canBeUsed]).andReturn(YES);
  OCMStub([distributeMock isEnabled]).andReturn(NO);
  [self.settingsMock removeObjectForKey:kMSUpdateTokenRequestIdKey];
  OCMReject([distributeMock startUpdateOnStart:OCMOCK_ANY]);

  // When
  [MSDistribute checkForUpdate];

  // Then
  OCMVerifyAll(distributeMock);

  // Clear
  [distributeMock stopMocking];
}

- (void)testBypassCheckForUpdateWhenDistributeCanNotBeUsed {

  // If
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock canBeUsed]).andReturn(NO);
  OCMStub([distributeMock isEnabled]).andReturn(YES);
  [self.settingsMock removeObjectForKey:kMSUpdateTokenRequestIdKey];
  OCMReject([distributeMock startUpdateOnStart:OCMOCK_ANY]);

  // When
  [MSDistribute checkForUpdate];

  // Then
  OCMVerifyAll(distributeMock);

  // Clear
  [distributeMock stopMocking];
}

- (void)testBypassCheckForUpdateIfUpdateRequestIdTokenExists {

  // If
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock canBeUsed]).andReturn(YES);
  OCMStub([distributeMock isEnabled]).andReturn(YES);
  [self.settingsMock setObject:@"testToken" forKey:kMSUpdateTokenRequestIdKey];
  OCMReject([distributeMock startUpdateOnStart:OCMOCK_ANY]);

  // When
  [MSDistribute checkForUpdate];

  // Then
  OCMVerifyAll(distributeMock);

  // Clear
  [distributeMock stopMocking];
}

- (void)testDisableAutomaticCheckForUpdateBeforeStart {

  // If
  self.sut.automaticCheckForUpdateDisabled = NO;

  // When
  [MSDistribute disableAutomaticCheckForUpdate];

  // Then
  XCTAssertTrue(self.sut.automaticCheckForUpdateDisabled);
}

- (void)testAutomaticCheckForUpdateDisabledDoesNotChangeAfterStart {

  // If
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                        appSecret:kMSTestAppSecret
          transmissionTargetToken:nil
                  fromApplication:YES];

  // When
  [MSDistribute disableAutomaticCheckForUpdate];

  // Then
  XCTAssertFalse(self.sut.automaticCheckForUpdateDisabled);
}

- (void)testCheckForUpdateOpenBrowserEvenThoughAutomaticUpdateIsDisabled {

  // If
  id utilityMock = OCMClassMock([MSUtility class]);
  OCMStub(ClassMethod([utilityMock sha256:OCMOCK_ANY])).andReturn(@"RELEASEHASH");
  NSDictionary<NSString *, id> *plist = @{@"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1"};

  // Bundle mock
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);
  OCMStub([bundleMock infoDictionary]).andReturn(plist);

  // Distribute Mock
  __block id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock canBeUsed]).andReturn(YES);
  OCMStub([distributeMock isEnabled]).andReturn(YES);
  [self.settingsMock removeObjectForKey:kMSUpdateTokenRequestIdKey];
  OCMStub([distributeMock checkForUpdatesAllowed]).andReturn(YES);
  OCMStub([distributeMock buildTokenRequestURLWithAppSecret:OCMOCK_ANY releaseHash:OCMOCK_ANY isTesterApp:false])
      .andReturn([NSURL URLWithString:@"https://some_url"]);
  OCMStub([distributeMock buildTokenRequestURLWithAppSecret:OCMOCK_ANY releaseHash:OCMOCK_ANY isTesterApp:true])
      .andReturn([NSURL URLWithString:@"some_url://"]);
  OCMStub([distributeMock openUrlUsingSharedApp:OCMOCK_ANY]).andReturn(NO);
  OCMStub([distributeMock openUrlInAuthenticationSessionOrSafari:OCMOCK_ANY]).andDo(nil);
  XCTestExpectation *expectation = [self expectationWithDescription:@"Start update processed"];

  // When
  [MSDistribute disableAutomaticCheckForUpdate];
  MSDistribute.updateTrack = MSUpdateTrackPrivate;
  [MSDistribute checkForUpdate];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 // Then
                                 OCMVerify([distributeMock startUpdateOnStart:NO]);
                                 OCMVerify([distributeMock openUrlInAuthenticationSessionOrSafari:OCMOCK_ANY]);

                                 // We expect update flow isn't completed yet as this test doesn't simulate openURL.
                                 XCTAssertTrue(self.sut.updateFlowInProgress);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  // Cleanup
  [distributeMock stopMocking];
  [bundleMock stopMocking];
  [utilityMock stopMocking];
}

- (void)testCheckForUpdateGetsLatestReleaseEvenThoughAutomaticUpdateIsDisabled {

  // If
  id utilityMock = OCMClassMock([MSUtility class]);
  OCMStub(ClassMethod([utilityMock sha256:OCMOCK_ANY])).andReturn(@"RELEASEHASH");
  NSDictionary<NSString *, id> *plist = @{@"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1"};

  // Bundle mock
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);
  OCMStub([bundleMock infoDictionary]).andReturn(plist);

  // Distribute Mock
  __block id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock canBeUsed]).andReturn(YES);
  OCMStub([distributeMock isEnabled]).andReturn(YES);
  [self.settingsMock removeObjectForKey:kMSUpdateTokenRequestIdKey];
  XCTestExpectation *expectation = [self expectationWithDescription:@"Start update processed"];

  // When
  [MSDistribute disableAutomaticCheckForUpdate];
  MSDistribute.updateTrack = MSUpdateTrackPublic;
  [MSDistribute checkForUpdate];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 // Then
                                 OCMVerify([distributeMock startUpdateOnStart:NO]);
                                 OCMVerify([distributeMock checkLatestRelease:OCMOCK_ANY
                                                          distributionGroupId:OCMOCK_ANY
                                                                  releaseHash:OCMOCK_ANY]);
                                 XCTAssertFalse(self.sut.updateFlowInProgress);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  // Cleanup
  [distributeMock stopMocking];
  [bundleMock stopMocking];
  [utilityMock stopMocking];
}

- (void)testDoesNotCheckUpdateOnStartWhenAutomaticCheckIsDisabled {

  // If
  id utilityMock = OCMClassMock([MSUtility class]);
  OCMStub(ClassMethod([utilityMock sha256:OCMOCK_ANY])).andReturn(@"RELEASEHASH");
  NSDictionary<NSString *, id> *plist = @{@"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1"};

  // Bundle mock
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);
  OCMStub([bundleMock infoDictionary]).andReturn(plist);

  // Distribute Mock
  __block id distributeMock = OCMPartialMock(self.sut);
  OCMReject([distributeMock checkLatestRelease:OCMOCK_ANY distributionGroupId:OCMOCK_ANY releaseHash:OCMOCK_ANY]);
  XCTestExpectation *expectation = [self expectationWithDescription:@"Start update processed"];

  // When
  [MSDistribute disableAutomaticCheckForUpdate];
  MSDistribute.updateTrack = MSUpdateTrackPublic;
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
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
                                 XCTAssertFalse(self.sut.updateFlowInProgress);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  // Cleanup
  [distributeMock stopMocking];
  [bundleMock stopMocking];
  [utilityMock stopMocking];
}

- (void)testDoesNotOpenBrowserOrTesterAppOnStartWhenDisabled {

  // If
  id utilityMock = OCMClassMock([MSUtility class]);
  OCMStub(ClassMethod([utilityMock sha256:OCMOCK_ANY])).andReturn(@"RELEASEHASH");
  NSDictionary<NSString *, id> *plist = @{@"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1"};

  // Bundle mock
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);
  OCMStub([bundleMock infoDictionary]).andReturn(plist);

  // Distribute Mock
  __block id distributeMock = OCMPartialMock(self.sut);
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
  MSDistribute.updateTrack = MSUpdateTrackPrivate;
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
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
                                 XCTAssertFalse(self.sut.updateFlowInProgress);
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
