// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSChannelGroupProtocol.h"
#import "MSChannelUnitProtocol.h"
#import "MSDataStore.h"
#import "MSDataStoreInternal.h"
#import "MSDataStorePrivate.h"
#import "MSMockUserDefaults.h"
#import "MSServiceAbstract.h"
#import "MSServiceAbstractProtected.h"
#import "MSTestFrameworks.h"
#import "MSUserIdContextPrivate.h"

static NSString *const kMSTestAppSecret = @"TestAppSecret";

@interface MSDataStoreTests : XCTestCase

@property(nonatomic, strong) MSDataStore *sut;
@property(nonatomic) id settingsMock;

@end

@implementation MSDataStoreTests

- (void)setUp {
  [super setUp];
  self.settingsMock = [MSMockUserDefaults new];
  self.sut = [MSDataStore new];
}

- (void)tearDown {
  [super tearDown];
  [MSDataStore resetSharedInstance];
  [self.settingsMock stopMocking];
}

#pragma mark - Tests

- (void)testApplyEnabledStateWorks {

  // If
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];

   // When
  [self.sut setEnabled:YES];

  // Then
  XCTAssertTrue([self.sut isEnabled]);

  // When
  [self.sut setEnabled:NO];

  // Then
  XCTAssertFalse([self.sut isEnabled]);

  // When
  [self.sut setEnabled:YES];

  // Then
  XCTAssertTrue([self.sut isEnabled]);
}

- (void)testListDocumentsGoldenPath {
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                                            appSecret:kMSTestAppSecret
                              transmissionTargetToken:nil
                                      fromApplication:YES];
  
 
}

@end
