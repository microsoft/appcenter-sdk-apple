// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAppCenter.h"
#import "MSChannelGroupProtocol.h"
#import "MSConstants+Internal.h"
#import "MSCosmosDb.h"
#import "MSCosmosDbPrivate.h"
#import "MSDataStore.h"
#import "MSDataStoreInternal.h"
#import "MSHttpClient.h"
#import "MSTestFrameworks.h"
#import "MSTokenResult.h"

@interface MSDataStoreTests : XCTestCase

@end

@implementation MSDataStoreTests

- (void)testApplyEnabledStatePropagatesToHttpClient {

  // If
  id httpClientMock = OCMProtocolMock(@protocol(MSHttpClientProtocol));
  [MSAppCenter start:@"app-secret" withServices:@ [[MSDataStore class]]];

  // The httpClient must be re-set *after* the start method is called because it will call "applyEnabledState", but the test must isolate
  // the call.
  [MSDataStore sharedInstance].httpClient = httpClientMock;

  // When
  [MSDataStore setEnabled:NO];

  // Then
  OCMVerify([httpClientMock setEnabled:NO]);

  // When
  [MSDataStore setEnabled:YES];

  // Then
  OCMVerify([httpClientMock setEnabled:YES]);
}

- (void)testSetOfflineMode {

  // Then
  XCTAssertFalse([MSDataStore isOfflineMode]);

  // When
  [MSDataStore setOfflineMode:YES];

  // Then
  XCTAssertTrue([MSDataStore isOfflineMode]);

  // When
  [MSDataStore setOfflineMode:NO];

  // Then
  XCTAssertFalse([MSDataStore isOfflineMode]);
}

@end
