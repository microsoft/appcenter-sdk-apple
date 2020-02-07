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

@end
