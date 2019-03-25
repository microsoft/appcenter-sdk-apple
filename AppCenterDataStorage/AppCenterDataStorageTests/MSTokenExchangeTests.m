// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSMockKeychainUtil.h"
#import "MSMockUserDefaults.h"
#import "MSTestFrameworks.h"

static NSString *const cachedToken = @"mockCachedToken";

@interface MSTokenExchangeTests : XCTestCase

@property(nonatomic) MSMockUserDefaults *settingsMock;
@property(nonatomic) id keychainUtilMock;

@end

@implementation MSTokenExchangeTests

- (void)setUp {
  [super setUp];
  self.settingsMock = [MSMockUserDefaults new];
  self.keychainUtilMock = [MSMockKeychainUtil new];
}

- (void)tearDown {
  [super tearDown];
  [self.settingsMock stopMocking];
  [self.keychainUtilMock stopMocking];
}

- (void)testWhenNoCachedTokenNewTokenIsCached {
}

- (void)testValidCachedTokenExists {
}

- (void)testRemoveAllTokens {
}

- (void)testCachedTokenIsExpired {
}

- (void)testCachedTokenNotFoundInKeychain {
}

- (void)testExchangeServiceSerializationFails {
}

- (void)testExchangeServiceReturnsError {
}

- (void)testExchangeServiceReturnsHTTPError {
}
@end
