// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSChannelGroupProtocol.h"
#import "MSChannelUnitProtocol.h"
#import "MSDataStore.h"
#import "MSDataStoreInternal.h"
#import "MSMockUserDefaults.h"
#import "MSServiceAbstract.h"
#import "MSServiceAbstractProtected.h"
#import "MSTestFrameworks.h"
#import "MSUserIdContextPrivate.h"

static NSString *const kMSTestAppSecret = @"TestAppSecret";

@interface MSDataStoreTests : XCTestCase

@property(nonatomic) id settingsMock;
@property(nonatomic) MSDataStore *sut;

@end

@implementation MSDataStoreTests

- (void)setUp {
  [super setUp];
  self.settingsMock = [MSMockUserDefaults new];
  self.sut = [MSDataStore new];
}

- (void)tearDown {
  [super tearDown];
  //[MSDataStore resetSharedInstance];
  [self.settingsMock stopMocking];
}

#pragma mark - Tests

- (void)testApplyEnabledStateWorks {

  // If
  [[MSDataStore sharedInstance] startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];
  MSServiceAbstract *service = [MSDataStore sharedInstance];

   // When
  [service setEnabled:YES];

  // Then
  XCTAssertTrue([service isEnabled]);

  // When
  [service setEnabled:NO];

  // Then
  XCTAssertFalse([service isEnabled]);

  // When
  [service setEnabled:YES];

  // Then
  XCTAssertTrue([service isEnabled]);
}

@end
