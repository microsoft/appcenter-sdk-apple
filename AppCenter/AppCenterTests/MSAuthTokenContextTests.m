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
  MSUserInformation *expectedUser = [[MSUserInformation alloc] initWithAccountId:@"account1"];
  id<MSAuthTokenContextDelegate> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut setAuthToken:expectedAuthToken withUserInformation:expectedUser];

  // Then
  XCTAssertEqualObjects([self.sut authToken], expectedAuthToken);
  XCTAssertEqualObjects([self.sut homeUser], expectedUser);
  OCMVerify([delegateMock authTokenContext:self.sut didUpdateUserInformation:expectedUser]);
}

- (void)testSetAuthTokenDoesNotTriggerNewUserOnSameAccount {

  // If
  NSString *expectedAuthToken = @"authToken1";
  MSUserInformation *expectedUser = [[MSUserInformation alloc] initWithAccountId:@"account1"];
  id<MSAuthTokenContextDelegate> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut setAuthToken:expectedAuthToken withUserInformation:expectedUser];

  // Then
  OCMVerify([delegateMock authTokenContext:self.sut didUpdateUserInformation:expectedUser]);
  OCMVerify([delegateMock authTokenContext:self.sut didUpdateAuthToken:expectedAuthToken]);

  // When
  [self.sut setAuthToken:expectedAuthToken withUserInformation:expectedUser];

  // Then
  OCMVerify([delegateMock authTokenContext:self.sut didUpdateAuthToken:expectedAuthToken]);
  OCMReject([delegateMock authTokenContext:self.sut didUpdateUserInformation:expectedUser]);
}

- (void)testSetAuthTokenDoesTriggerNewUserOnNewAccount {

  // If
  NSString *expectedAuthToken = @"authToken1";
  MSUserInformation *expectedUser = [[MSUserInformation alloc] initWithAccountId:@"account1"];
  MSUserInformation *expectedUser2 = [[MSUserInformation alloc] initWithAccountId:@"account2"];
  id<MSAuthTokenContextDelegate> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut setAuthToken:expectedAuthToken withUserInformation:expectedUser];
  [self.sut setAuthToken:expectedAuthToken withUserInformation:expectedUser2];

  // Then
  OCMVerify([delegateMock authTokenContext:self.sut didUpdateUserInformation:expectedUser]);
  OCMVerify([delegateMock authTokenContext:self.sut didUpdateUserInformation:expectedUser2]);
}

- (void)testClearAuthToken {

  // If
  id<MSAuthTokenContextDelegate> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [self.sut addDelegate:delegateMock];

  // Then
  XCTAssertFalse([self.sut clearAuthToken]);

  // When
  MSUserInformation *user = [[MSUserInformation alloc] initWithAccountId:@"some-id"];
  [self.sut setAuthToken:@"some-token" withUserInformation:user];
  XCTAssertTrue([self.sut clearAuthToken]);

  // Then
  XCTAssertNil([self.sut authToken]);
  XCTAssertNil([[self.sut homeUser] accountId]);
  OCMVerify([delegateMock authTokenContext:self.sut didUpdateAuthToken:nil]);
  OCMVerify([delegateMock authTokenContext:self.sut didUpdateUserInformation:user]);
}

- (void)testRemoveDelegate {

  // If
  id<MSAuthTokenContextDelegate> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [self.sut addDelegate:delegateMock];

  // Then
  OCMReject([delegateMock authTokenContext:self.sut didUpdateAuthToken:OCMOCK_ANY]);

  // When
  [self.sut removeDelegate:delegateMock];
  [self.sut setAuthToken:@"something" withUserInformation:[[MSUserInformation alloc] initWithAccountId:@"someome"]];
}

@end
