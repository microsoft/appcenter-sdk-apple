// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthTokenContext.h"
#import "MSAuthTokenContextDelegate.h"
#import "MSTestFrameworks.h"
#import "MSUserInformation.h"

@interface MSAuthTokenContext ()

+ (void)resetSharedInstance;

@end

@interface MSAuthTokenContextTests : XCTestCase

@property(nonatomic) MSAuthTokenContext *sut;

@end

@implementation MSAuthTokenContextTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
  self.sut = [MSAuthTokenContext sharedInstance];
}

- (void)tearDown {
  [MSAuthTokenContext resetSharedInstance];
  [super tearDown];
}

#pragma mark - Tests

- (void)testSetAuthToken {

  // If
  NSString *expectedAuthToken = @"authToken1";
  NSString *expectedAccountId = @"0d619014-65f6-485d-add1-73a3fb772cdc";
  NSString *expectedHomeAccountId = [expectedAccountId stringByAppendingString:@"-b2c_some_other_information"];
  id<MSAuthTokenContextDelegate> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut setAuthToken:expectedAuthToken withAccountId:expectedHomeAccountId];

  // Then
  XCTAssertEqualObjects([self.sut authToken], expectedAuthToken);
  OCMVerify([delegateMock authTokenContext:self.sut
                  didUpdateUserInformation:[OCMArg checkWithBlock:^BOOL(id obj) {
                    return [((MSUserInformation *)obj).accountId isEqualToString:expectedAccountId];
                  }]]);
}

- (void)testSetAuthTokenDoesNotTriggerNewUserOnSameAccount {

  // If
  NSString *expectedAuthToken = @"authToken1";
  NSString *expectedAccountId = @"account1";
  id<MSAuthTokenContextDelegate> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut setAuthToken:expectedAuthToken withAccountId:expectedAccountId];

  // Then
  OCMVerify([delegateMock authTokenContext:self.sut
                  didUpdateUserInformation:[OCMArg checkWithBlock:^BOOL(id obj) {
                    return [((MSUserInformation *)obj).accountId isEqualToString:expectedAccountId];
                  }]]);

  OCMVerify([delegateMock authTokenContext:self.sut didUpdateAuthToken:expectedAuthToken]);

  // When
  [self.sut setAuthToken:expectedAuthToken withAccountId:expectedAccountId];

  // Then
  OCMVerify([delegateMock authTokenContext:self.sut didUpdateAuthToken:expectedAuthToken]);
  OCMReject([delegateMock authTokenContext:self.sut didUpdateUserInformation:OCMOCK_ANY]);
}

- (void)testSetAuthTokenDoesTriggerNewUserOnNewAccount {

  // If
  NSString *expectedAuthToken = @"authToken1";
  NSString *expectedAuthToken2 = @"authToken2";
  NSString *expectedAccountId = @"account1";
  NSString *expectedAccountId2 = @"account2";
  id<MSAuthTokenContextDelegate> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut setAuthToken:expectedAuthToken withAccountId:expectedAccountId];

  // Then
  OCMVerify([delegateMock authTokenContext:self.sut
                  didUpdateUserInformation:[OCMArg checkWithBlock:^BOOL(id obj) {
                    return [((MSUserInformation *)obj).accountId isEqualToString:expectedAccountId];
                  }]]);

  // When
  [self.sut setAuthToken:expectedAuthToken2 withAccountId:expectedAccountId2];

  // Then
  OCMVerify([delegateMock authTokenContext:self.sut
                  didUpdateUserInformation:[OCMArg checkWithBlock:^BOOL(id obj) {
                    return [((MSUserInformation *)obj).accountId isEqualToString:expectedAccountId2];
                  }]]);
}

- (void)testClearAuthToken {

  // If
  id<MSAuthTokenContextDelegate> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [self.sut addDelegate:delegateMock];

  // Then
  XCTAssertFalse([self.sut clearAuthToken]);

  // When
  [self.sut setAuthToken:@"some-token" withAccountId:@"some-id"];
  XCTAssertTrue([self.sut clearAuthToken]);

  // Then
  XCTAssertNil([self.sut authToken]);
  OCMVerify([delegateMock authTokenContext:self.sut didUpdateAuthToken:nil]);
  OCMVerify([delegateMock authTokenContext:self.sut didUpdateUserInformation:nil]);
}

- (void)testRemoveDelegate {

  // If
  id<MSAuthTokenContextDelegate> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [self.sut addDelegate:delegateMock];

  // Then
  OCMReject([delegateMock authTokenContext:self.sut didUpdateAuthToken:OCMOCK_ANY]);

  // When
  [self.sut removeDelegate:delegateMock];
  [self.sut setAuthToken:@"something" withAccountId:@"someome"];
}

@end
