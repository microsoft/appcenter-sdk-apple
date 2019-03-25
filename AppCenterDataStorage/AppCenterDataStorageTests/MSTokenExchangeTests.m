// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSTestFrameworks.h"
#import <Foundation/Foundation.h>

static NSString *const partitionName = @"TestAppSecret";
static NSString *const token = @"mockToken";

@interface MSTokenTests : XCTestCase

@end

@implementation MSTokenTests

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
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
