// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSBasicMachOParser.h"
#import "MSChannelGroupProtocol.h"
#import "MSDistributeIngestion.h"
#import "MSDistributePrivate.h"
#import "MSMockKeychainUtil.h"
#import "MSMockUserDefaults.h"
#import "MSTestFrameworks.h"
#import "MSUtility+StringFormatting.h"

static NSString *const kMSTestAppSecret = @"IAMSECRET";

@interface MSDistributeCheckForUpdateTests : XCTestCase

@property(nonatomic) MSDistribute *sut;
@property(nonatomic) id settingsMock;
@property(nonatomic) id keychainUtilMock;
@property(nonatomic) id bundleMock;
@property(nonatomic) id parserMock;
@property(nonatomic) id utilityMock;

@end

@implementation MSDistributeCheckForUpdateTests

- (void)setUp {
  [super setUp];
  self.settingsMock = [MSMockUserDefaults new];
  self.keychainUtilMock = [MSMockKeychainUtil new];

  // Utility mock.
  self.utilityMock = OCMClassMock([MSUtility class]);
  OCMStub(ClassMethod([self.utilityMock sha256:OCMOCK_ANY])).andReturn(@"RELEASEHASH");

  // Bundle mock.
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
  [self.settingsMock stopMocking];
  [self.keychainUtilMock stopMocking];
  [self.bundleMock stopMocking];
  [self.parserMock stopMocking];
  [self.utilityMock stopMocking];
  [super tearDown];
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
  NSDictionary<NSString *, id> *plist = @{@"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1"};
  OCMStub([self.bundleMock infoDictionary]).andReturn(plist);

  // Distribute mock.
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
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  // Cleanup
  [distributeMock stopMocking];
}

- (void)testCheckForUpdateGetsLatestReleaseEvenThoughAutomaticUpdateIsDisabled {

  // If
  NSDictionary<NSString *, id> *plist = @{@"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1"};
  OCMStub([self.bundleMock infoDictionary]).andReturn(plist);

  // Distribute mock.
  __block id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock canBeUsed]).andReturn(YES);
  OCMStub([distributeMock isEnabled]).andReturn(YES);
  [self.settingsMock removeObjectForKey:kMSUpdateTokenRequestIdKey];
  OCMStub([distributeMock checkForUpdatesAllowed]).andReturn(YES);
  XCTestExpectation *expectation = [self expectationWithDescription:@"Start update processed"];

  // Ingestion mock.
  __block id ingestionMock = OCMClassMock([MSDistributeIngestion class]);
  OCMStub([ingestionMock checkForPublicUpdateWithQueryStrings:OCMOCK_ANY completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __unsafe_unretained  void (^handler)(NSString *callId, NSHTTPURLResponse *_Nullable response, NSData *_Nullable data, NSError *_Nullable error);
    [invocation getArgument:&handler atIndex:3];

    // Passing nil response would consider the ingestion call as failure but we don't care in this unit test.
    handler(nil, nil, nil, nil);
    [expectation fulfill];
  });
  [distributeMock setValue:ingestionMock forKey:@"ingestion"];

  // When
  [MSDistribute disableAutomaticCheckForUpdate];
  MSDistribute.updateTrack = MSUpdateTrackPublic;
  [MSDistribute checkForUpdate];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 // Then
                                 OCMVerify([distributeMock startUpdateOnStart:NO]);
                                 OCMVerify([distributeMock checkLatestRelease:OCMOCK_ANY
                                                          distributionGroupId:OCMOCK_ANY
                                                                  releaseHash:OCMOCK_ANY]);
                                 OCMVerify([ingestionMock checkForPublicUpdateWithQueryStrings:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  // Cleanup
  [distributeMock stopMocking];
  [ingestionMock stopMocking];
}

- (void)testDoesNotCheckUpdateOnStartWhenAutomaticCheckIsDisabled {

  // If
  NSDictionary<NSString *, id> *plist = @{@"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1"};
  OCMStub([self.bundleMock infoDictionary]).andReturn(plist);

  // Distribute mock.
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
}

- (void)testDoesNotOpenBrowserOrTesterAppOnStartWhenDisabled {

  // If
  NSDictionary<NSString *, id> *plist = @{@"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1"};
  OCMStub([self.bundleMock infoDictionary]).andReturn(plist);

  // Distribute mock.
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
}

@end
