// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAppCenterInternal.h"
#import "MSBasicMachOParser.h"
#import "MSChannelGroupProtocol.h"
#import "MSDistributePrivate.h"
#import "MSGuidedAccessUtil.h"
#import "MSTestFrameworks.h"
#import "MSUtility+StringFormatting.h"
#import "MS_Reachability.h"

static NSString *const kMSTestAppSecret = @"IAMSECRET";

@interface MSDistributeConfigureTests : XCTestCase

@end

@implementation MSDistributeConfigureTests

- (void)testConfigureFlagsBeforeStart {

  // If
  [MSDistribute sharedInstance].distributeFlags = -1;

  // When
  [MSDistribute configure:MSDistributeFlagsDisableAutomaticCheckForUpdate];

  // Then
  XCTAssertEqual(MSDistributeFlagsDisableAutomaticCheckForUpdate, [MSDistribute sharedInstance].distributeFlags);
}

- (void)testConfigureFlagsDoesNotChangeAfterStart {

  // If
  MSDistribute *distribute = [MSDistribute new];
  distribute.distributeFlags = MSDistributeFlagsDisableAutomaticCheckForUpdate;

  // When
  [distribute startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                          appSecret:kMSTestAppSecret
            transmissionTargetToken:nil
                    fromApplication:YES];
  [distribute configure:MSDistributeFlagsNone];

  // Then
  XCTAssertEqual(MSDistributeFlagsDisableAutomaticCheckForUpdate, distribute.distributeFlags);
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

- (void)testCheckForUpdateDoesNotCheckWhenDisabled {

  // If
  NSString *updateToken = @"UpdateToken";
  NSString *distributionGroupId = @"DistributionGroupId";
  NSString *releaseHash = @"ReleaseHash";
  MSDistribute *distribute = [MSDistribute new];
  id distributeMock = OCMPartialMock(distribute);
  [distributeMock setValue:@(YES) forKey:@"updateFlowInProgress"];
  [distributeMock setValue:@(MSDistributeFlagsDisableAutomaticCheckForUpdate) forKey:@"distributeFlags"];
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
  id reachabilityMock = OCMClassMock([MS_Reachability class]);
  OCMStub([reachabilityMock reachabilityForInternetConnection]).andReturn(reachabilityMock);
  OCMStub([reachabilityMock currentReachabilityStatus]).andReturn(ReachableViaWiFi);
  id appCenterMock = OCMClassMock([MSAppCenter class]);
  OCMStub([appCenterMock isConfigured]).andReturn(YES);
  id guidedAccessMock = OCMClassMock([MSGuidedAccessUtil class]);
  OCMStub([guidedAccessMock isGuidedAccessEnabled]).andReturn(NO);
  OCMStub([appCenterMock isDebuggerAttached]).andReturn(NO);
  NSDictionary<NSString *, id> *plist = @{@"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1"};
  id utilityMock = OCMClassMock([MSUtility class]);
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wcast-qual"
  OCMStub(ClassMethod([utilityMock sha256:OCMOCK_ANY])).andReturn(@"RELEASEHASH");
#pragma GCC diagnostic pop
  OCMStub([utilityMock currentAppEnvironment]).andReturn(MSEnvironmentOther);
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);
  OCMStub([bundleMock infoDictionary]).andReturn(plist);
  id parserMock = OCMClassMock([MSBasicMachOParser class]);
  OCMStub([parserMock machOParserForMainBundle]).andReturn(parserMock);
  OCMStub([parserMock uuid]).andReturn([[NSUUID alloc] initWithUUIDString:@"CD55E7A9-7AD1-4CA6-B722-3D133F487DA9"]);
  MSDistribute *distribute = [MSDistribute new];
  id distributeMock = OCMPartialMock(distribute);
  OCMStub([distributeMock sharedInstance]).andReturn(distributeMock);
  OCMStub([distributeMock buildTokenRequestURLWithAppSecret:OCMOCK_ANY releaseHash:OCMOCK_ANY isTesterApp:false])
      .andReturn([NSURL URLWithString:@"https://some_url"]);
  OCMStub([distributeMock buildTokenRequestURLWithAppSecret:OCMOCK_ANY releaseHash:OCMOCK_ANY isTesterApp:true])
      .andReturn([NSURL URLWithString:@"some_url://"]);
  OCMReject([distributeMock openUrlUsingSharedApp:OCMOCK_ANY]);
  OCMReject([distributeMock openUrlInAuthenticationSessionOrSafari:OCMOCK_ANY]);
  XCTestExpectation *expectation = [self expectationWithDescription:@"Start update processed"];

  // When
  MSDistribute.updateTrack = MSUpdateTrackPrivate;
  [MSDistribute configure:MSDistributeFlagsDisableAutomaticCheckForUpdate];
  [distributeMock startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
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
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  // Cleanup
  [distributeMock stopMocking];
  [parserMock stopMocking];
  [bundleMock stopMocking];
  [utilityMock stopMocking];
  [guidedAccessMock stopMocking];
  [appCenterMock stopMocking];
  [reachabilityMock stopMocking];
}

@end
