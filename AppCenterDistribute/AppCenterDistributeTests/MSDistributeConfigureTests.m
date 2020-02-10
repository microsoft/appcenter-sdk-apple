// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSChannelGroupProtocol.h"
#import "MSDistributePrivate.h"
#import "MSTestFrameworks.h"

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

@end
