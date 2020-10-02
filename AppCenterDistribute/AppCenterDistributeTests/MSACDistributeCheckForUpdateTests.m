// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACBasicMachOParser.h"
#import "MSACChannelGroupProtocol.h"
#import "MSACDistributeIngestion.h"
#import "MSACDistributePrivate.h"
#import "MSACMockKeychainUtil.h"
#import "MSACMockUserDefaults.h"
#import "MSACTestFrameworks.h"
#import "MSACUtility+StringFormatting.h"

static NSString *const kMSACTestAppSecret = @"IAMSACECRET";

@interface MSACDistributeCheckForUpdateTests : XCTestCase

@property(nonatomic) MSACDistribute *sut;
@property(nonatomic) id settingsMock;
@property(nonatomic) id keychainUtilMock;
@property(nonatomic) id bundleMock;
@property(nonatomic) id parserMock;
@property(nonatomic) id utilityMock;

@end

@implementation MSACDistributeCheckForUpdateTests

- (void)setUp {
  [super setUp];
  self.settingsMock = [MSACMockUserDefaults new];
  self.keychainUtilMock = [MSACMockKeychainUtil new];

  // Utility mock.
  self.utilityMock = OCMClassMock([MSACUtility class]);
  OCMStub(ClassMethod([self.utilityMock sha256:OCMOCK_ANY])).andReturn(@"RELEASEHASH");

  // Bundle mock.
  self.bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([self.bundleMock mainBundle]).andReturn(self.bundleMock);

  // Parser mock.
  id parserMock = OCMClassMock([MSACBasicMachOParser class]);
  OCMStub([parserMock machOParserForMainBundle]).andReturn(parserMock);
  OCMStub([parserMock uuid]).andReturn([[NSUUID alloc] initWithUUIDString:@"CD55E7A9-7AD1-4CA6-B722-3D133F487DA9"]);

  // Distribute instance.
  [MSACDistribute resetSharedInstance];
  self.sut = [MSACDistribute sharedInstance];
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
  [self.settingsMock removeObjectForKey:kMSACUpdateTokenRequestIdKey];
  OCMReject([distributeMock startUpdate]);

  // When
  [MSACDistribute checkForUpdate];

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
  [self.settingsMock removeObjectForKey:kMSACUpdateTokenRequestIdKey];
  OCMReject([distributeMock startUpdate]);

  // When
  [MSACDistribute checkForUpdate];

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
  [self.settingsMock setObject:@"testToken" forKey:kMSACUpdateTokenRequestIdKey];
  OCMReject([distributeMock startUpdate]);

  // When
  [MSACDistribute checkForUpdate];

  // Then
  OCMVerifyAll(distributeMock);

  // Clear
  [distributeMock stopMocking];
}

- (void)testDisableAutomaticCheckForUpdateBeforeStart {

  // If
  self.sut.automaticCheckForUpdateDisabled = NO;

  // When
  [MSACDistribute disableAutomaticCheckForUpdate];

  // Then
  XCTAssertTrue(self.sut.automaticCheckForUpdateDisabled);
}

- (void)testAutomaticCheckForUpdateDisabledDoesNotChangeAfterStart {

  // If
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSACChannelGroupProtocol))
                        appSecret:kMSACTestAppSecret
          transmissionTargetToken:nil
                  fromApplication:YES];

  // When
  [MSACDistribute disableAutomaticCheckForUpdate];

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
  [self.settingsMock removeObjectForKey:kMSACUpdateTokenRequestIdKey];
  OCMStub([distributeMock checkForUpdatesAllowed]).andReturn(YES);
  OCMStub([distributeMock buildTokenRequestURLWithAppSecret:OCMOCK_ANY releaseHash:OCMOCK_ANY isTesterApp:false])
      .andReturn([NSURL URLWithString:@"https://some_url"]);
  OCMStub([distributeMock buildTokenRequestURLWithAppSecret:OCMOCK_ANY releaseHash:OCMOCK_ANY isTesterApp:true])
      .andReturn([NSURL URLWithString:@"some_url://"]);
  OCMStub([distributeMock openUrlUsingSharedApp:OCMOCK_ANY]).andReturn(NO);
  OCMStub([distributeMock openUrlInAuthenticationSessionOrSafari:OCMOCK_ANY]).andDo(nil);
  XCTestExpectation *expectation = [self expectationWithDescription:@"Start update processed"];

  // When
  [MSACDistribute disableAutomaticCheckForUpdate];
  MSACDistribute.updateTrack = MSACUpdateTrackPrivate;
  [MSACDistribute checkForUpdate];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 // Then
                                 OCMVerify([distributeMock startUpdate]);
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
  [self.settingsMock removeObjectForKey:kMSACUpdateTokenRequestIdKey];
  OCMStub([distributeMock checkForUpdatesAllowed]).andReturn(YES);
  XCTestExpectation *expectation = [self expectationWithDescription:@"Start update processed"];

  // Ingestion mock.
  __block id ingestionMock = OCMClassMock([MSACDistributeIngestion class]);
  OCMStub([ingestionMock checkForPublicUpdateWithQueryStrings:OCMOCK_ANY completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __unsafe_unretained void (^handler)(NSString *callId, NSHTTPURLResponse *_Nullable response, NSData *_Nullable data,
                                        NSError *_Nullable error);
    [invocation getArgument:&handler atIndex:3];

    // Passing nil response would consider the ingestion call as failure but we don't care in this unit test.
    handler(nil, nil, nil, nil);
    [expectation fulfill];
  });
  [distributeMock setValue:ingestionMock forKey:@"ingestion"];

  // When
  [MSACDistribute disableAutomaticCheckForUpdate];
  MSACDistribute.updateTrack = MSACUpdateTrackPublic;
  [MSACDistribute checkForUpdate];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 // Then
                                 OCMVerify([distributeMock startUpdate]);
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

- (void)testCheckForUpdateBeforeApplicationDidBecomeActive {

  // If
  NSDictionary<NSString *, id> *plist = @{@"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1"};
  OCMStub([self.bundleMock infoDictionary]).andReturn(plist);

  // Notification center mock.
  id notificationCenterMock = OCMPartialMock([NSNotificationCenter new]);
  OCMStub([notificationCenterMock defaultCenter]).andReturn(notificationCenterMock);

  // Re-initialize to use notification center mock.
  [MSACDistribute resetSharedInstance];
  self.sut = [MSACDistribute sharedInstance];

  // Distribute mock.
  __block id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock canBeUsed]).andReturn(YES);
  OCMStub([distributeMock isEnabled]).andReturn(YES);
  [self.settingsMock removeObjectForKey:kMSACUpdateTokenRequestIdKey];
  OCMStub([distributeMock checkForUpdatesAllowed]).andReturn(YES);

  // Ingestion mock.
  __block id ingestionMock = OCMClassMock([MSACDistributeIngestion class]);
  [distributeMock setValue:ingestionMock forKey:@"ingestion"];

  // When
  [MSACDistribute disableAutomaticCheckForUpdate];
  MSACDistribute.updateTrack = MSACUpdateTrackPublic;
  [MSACDistribute checkForUpdate];

  // Notify that an application did become active.
  [notificationCenterMock postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];

  // Then
  XCTAssertTrue(self.sut.updateFlowInProgress);

  // Cleanup
  [distributeMock stopMocking];
  [ingestionMock stopMocking];
  [notificationCenterMock stopMocking];
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
  [MSACDistribute disableAutomaticCheckForUpdate];
  MSACDistribute.updateTrack = MSACUpdateTrackPublic;
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSACChannelGroupProtocol))
                        appSecret:kMSACTestAppSecret
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
  [MSACDistribute disableAutomaticCheckForUpdate];
  MSACDistribute.updateTrack = MSACUpdateTrackPrivate;
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSACChannelGroupProtocol))
                        appSecret:kMSACTestAppSecret
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
