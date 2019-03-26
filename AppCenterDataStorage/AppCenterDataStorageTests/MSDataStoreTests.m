// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDataStore.h"
#import "MSDataStoreInternal.h"
#import "MSTestFrameworks.h"

@interface MSDataStoreTests : XCTestCase

@property(nonatomic) id settingsMock;

@end

@implementation MSDataStoreTests

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - Tests
- (void)testSetOfflineMode {
  // when
  [MSDataStore setOfflineMode:YES];
  // then
  XCTAssertTrue([MSDataStore isOfflineMode]);
}

@end
