// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthTokenContext.h"
#import "MSAuthTokenContextDelegate.h"
#import "MSAuthTokenInfo.h"
#import "MSConstants.h"
#import "MSMockKeychainUtil.h"
#import "MSMockUserDefaults.h"
#import "MSTestFrameworks.h"
#import "MSUtility+File.h"

@interface MSAuthTokenContext ()

+ (void)resetSharedInstance;

@end

@interface MSAuthTokenContextTests : XCTestCase

@property(nonatomic) MSAuthTokenContext *sut;
@property(nonatomic) MSMockUserDefaults *settingsMock;
@property(nonatomic) id utilityMock;
@property(nonatomic) id keychainUtilMock;

@end

@implementation MSAuthTokenContextTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
  self.sut = [MSAuthTokenContext sharedInstance];
  self.settingsMock = [MSMockUserDefaults new];
  self.utilityMock = OCMClassMock([MSUtility class]);
  self.keychainUtilMock = [MSMockKeychainUtil new];
}

- (void)tearDown {
  [MSAuthTokenContext resetSharedInstance];
  [super tearDown];
  [self.settingsMock stopMocking];
  [self.utilityMock stopMocking];
  [self.keychainUtilMock stopMocking];
}

#pragma mark - Tests

- (void)testSetAuthToken {

  // If
  NSString *expectedAuthToken = @"authToken1";
  NSString *expectedAccountId = @"account1";
  id<MSAuthTokenContextDelegate> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut setAuthToken:expectedAuthToken withAccountId:expectedAccountId expiresOn:nil];

  // Then
  XCTAssertEqualObjects([self.sut authToken], expectedAuthToken);
  XCTAssertEqualObjects([self.sut accountId], expectedAccountId);
  OCMVerify([delegateMock authTokenContext:self.sut didSetNewAccountIdWithAuthToken:expectedAuthToken]);
}

- (void)testSetAuthTokenDoesNotTriggerNewUserOnSameAccount {

  // If
  NSString *expectedAuthToken = @"authToken1";
  NSString *expectedAccountId = @"account1";
  id<MSAuthTokenContextDelegate> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut setAuthToken:expectedAuthToken withAccountId:expectedAccountId expiresOn:nil];
  [self.sut setAuthToken:expectedAuthToken withAccountId:expectedAccountId expiresOn:nil];

  // Then
  OCMVerify([delegateMock authTokenContext:self.sut didSetNewAccountIdWithAuthToken:expectedAuthToken]);
  OCMVerify([delegateMock authTokenContext:self.sut didSetNewAuthToken:expectedAuthToken]);
}

- (void)testSetAuthTokenDoesTriggerNewUserOnNewAccount {

  // If
  NSString *expectedAuthToken = @"authToken1";
  NSString *expectedAccountId = @"account1";
  NSString *expectedAccountId2 = @"account2";
  id<MSAuthTokenContextDelegate> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut setAuthToken:expectedAuthToken withAccountId:expectedAccountId expiresOn:nil];
  [self.sut setAuthToken:expectedAuthToken withAccountId:expectedAccountId2 expiresOn:nil];

  // Then
  OCMVerify([delegateMock authTokenContext:self.sut didSetNewAccountIdWithAuthToken:expectedAuthToken]);
  OCMVerify([delegateMock authTokenContext:self.sut didSetNewAccountIdWithAuthToken:expectedAuthToken]);
}

- (void)testRemoveDelegate {

  // If
  id delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [self.sut addDelegate:delegateMock];

  // Then
  OCMReject([delegateMock authTokenContext:self.sut didSetNewAuthToken:OCMOCK_ANY]);

  // When
  [self.sut removeDelegate:delegateMock];
  [self.sut setAuthToken:@"something" withAccountId:@"someome" expiresOn:nil];

  // Then
  OCMVerifyAll(delegateMock);
}

- (void)testSaveAuthToken {

  // If
  NSString *expectedToken = @"someToken";
  NSString *expectedAccount = @"someAccountData";

  // When
  [self.sut saveAuthToken:expectedToken withAccountId:expectedAccount expiresOn:nil];
  MSAuthTokenInfo *actualAuthTokenInfo = [[MSMockKeychainUtil arrayForKey:kMSAuthTokenArrayKey] lastObject];

  // Then
  XCTAssertEqual(actualAuthTokenInfo.authToken, expectedToken);
  XCTAssertNotNil(actualAuthTokenInfo.startTime);
  XCTAssertNil(actualAuthTokenInfo.endTime);
  XCTAssertTrue([expectedAccount isEqualToString:actualAuthTokenInfo.accountId]);
}

- (void)testSaveAuthTokenWhenTokenIsEmpty {

  // If
  MSAuthTokenInfo *authTokenInfo = [[MSAuthTokenInfo alloc] initWithAuthToken:@"someToken"
                                                                 andAccountId:@"someAccountId"
                                                                 andStartTime:nil
                                                                   andEndTime:nil];
  NSMutableArray<MSAuthTokenInfo *> *authTokenHistory = [NSMutableArray<MSAuthTokenInfo *> new];
  [authTokenHistory addObject:authTokenInfo];
  [MSMockKeychainUtil storeArray:authTokenHistory forKey:kMSAuthTokenArrayKey];
  [self.settingsMock setObject:@"someAccountData" forKey:kMSHomeAccountKey];

  // When
  [self.sut saveAuthToken:nil withAccountId:@"someNewAccountData" expiresOn:nil];
  MSAuthTokenInfo *actualAuthTokenInfo = [[MSMockKeychainUtil arrayForKey:kMSAuthTokenArrayKey] lastObject];

  // Then
  XCTAssertNil(actualAuthTokenInfo.authToken);
}

- (void)testSaveAuthTokenWhenAccountIsEmpty {

  // If
  NSString *expectedToken = @"someNewToken";
  [self.settingsMock setObject:@"someAccountData" forKey:kMSHomeAccountKey];

  // When
  [self.sut saveAuthToken:expectedToken withAccountId:nil expiresOn:nil];
  MSAuthTokenInfo *actualAuthTokenInfo = [[MSMockKeychainUtil arrayForKey:kMSAuthTokenArrayKey] lastObject];

  // Then
  XCTAssertEqual(actualAuthTokenInfo.authToken, expectedToken);
  XCTAssertNotNil(actualAuthTokenInfo.startTime);
  XCTAssertNil(actualAuthTokenInfo.endTime);
  XCTAssertNil(actualAuthTokenInfo.accountId);
}

- (void)testRetrieveAuthTokenReturnsLatestHistoryElement {

  // If
  NSString *expectedAuthToken = @"expectedAuthToken";
  MSAuthTokenInfo *authTokenInfo1 = [[MSAuthTokenInfo alloc] initWithAuthToken:@"someAuthToken"
                                                                  andAccountId:@"someAccountId"
                                                                  andStartTime:nil
                                                                    andEndTime:nil];
  MSAuthTokenInfo *authTokenInfo2 = [[MSAuthTokenInfo alloc] initWithAuthToken:expectedAuthToken
                                                                  andAccountId:@"someAccountId"
                                                                  andStartTime:nil
                                                                    andEndTime:nil];
  NSMutableArray<MSAuthTokenInfo *> *authTokenHistory = [NSMutableArray<MSAuthTokenInfo *> new];
  [authTokenHistory addObject:authTokenInfo1];
  [authTokenHistory addObject:authTokenInfo2];
  [MSMockKeychainUtil storeArray:authTokenHistory forKey:kMSAuthTokenArrayKey];

  // When
  NSString *actualAuthToken = [self.sut authToken];

  // Then
  XCTAssertEqual(actualAuthToken, expectedAuthToken);
}

- (void)testGetAuthTokenValidityArray {

  // If
  NSString *expectedAuthToken = @"expectedAuthToken";
  [self.sut saveAuthToken:@"unexpectedAuthToken" withAccountId:@"someAccountId" expiresOn:nil];
  [self.sut saveAuthToken:expectedAuthToken withAccountId:@"anotherAccountId" expiresOn:nil];

  // When
  NSMutableArray<MSAuthTokenValidityInfo *> *actualAuthTokenValidityArray = [self.sut authTokenValidityArray];

  // Then
  XCTAssertEqual(expectedAuthToken, actualAuthTokenValidityArray.lastObject.authToken);
}

- (void)testRemoveAuthToken {

  // If
  NSString *tokenExpectedToBeDeleted = @"someAuthToken";
  [self.sut saveAuthToken:tokenExpectedToBeDeleted withAccountId:@"someAccountId" expiresOn:nil];
  [self.sut saveAuthToken:@"someNewAuthToken" withAccountId:@"anotherAccountId" expiresOn:nil];

  // When
  [self.sut removeAuthToken:nil];
  [self.sut removeAuthToken:tokenExpectedToBeDeleted];
  NSArray<MSAuthTokenInfo *> *actualAuthTokenArray = [self.sut authTokenHistory];

  // Then
  XCTAssertEqual(actualAuthTokenArray.count, 1);
}

- (void)testDoNotRemoveNotOldestAuthToken {

  // If
  NSString *tokenExpectedNotToBeDeleted = @"someAuthToken";
  [self.sut saveAuthToken:tokenExpectedNotToBeDeleted withAccountId:@"someAccountId" expiresOn:nil];

  // When
  [self.sut removeAuthToken:tokenExpectedNotToBeDeleted];
  NSArray<MSAuthTokenInfo *> *actualAuthTokenArray = [self.sut authTokenHistory];

  // Then
  XCTAssertEqual(actualAuthTokenArray.count, 2);
}

- (void)testSaveAuthTokenLimitsHistorySize {

  // If
  NSString *accountId = @"someAccountId";

  // When
  for (int i = 0; i < kMSMaxAuthTokenArraySize; ++i) {
    [self.sut saveAuthToken:@"someToken" withAccountId:accountId expiresOn:nil];
    [self.sut saveAuthToken:nil withAccountId:accountId expiresOn:nil];
  }
  NSArray<MSAuthTokenInfo *> *actualAuthTokensHistory = [MSMockKeychainUtil arrayForKey:kMSAuthTokenArrayKey];

  // Then
  XCTAssertEqual([actualAuthTokensHistory count], kMSMaxAuthTokenArraySize);
}

- (void)testSaveAuthTokenAddsNewItemOnlyIfDiffersFromLatest {

  // If
  NSString *authToken = @"someToken";
  NSString *accountId = @"someAccountId";

  // When
  for (int i = 0; i < 2; ++i) {
    [self.sut saveAuthToken:authToken withAccountId:accountId expiresOn:nil];
  }
  for (int i = 0; i < 2; ++i) {
    [self.sut saveAuthToken:nil withAccountId:accountId expiresOn:nil];
  }
  for (int i = 0; i < 2; ++i) {
    [self.sut saveAuthToken:authToken withAccountId:accountId expiresOn:nil];
  }
  NSArray<MSAuthTokenInfo *> *actualAuthTokensHistory = [MSMockKeychainUtil arrayForKey:kMSAuthTokenArrayKey];
  MSAuthTokenInfo *latestAuthTokenInfo = [actualAuthTokensHistory lastObject];

  // Then
  XCTAssertEqual([actualAuthTokensHistory count], 3 + 1);
  XCTAssertEqual(latestAuthTokenInfo.authToken, authToken);
}

- (void)testSaveAuthTokenFillsTheGap {
  
  // If
  NSString *authToken = @"someToken";
  NSString *newAuthToken = @"someNewToken";
  NSString *accountId = @"someAccountId";
  NSString *newAccountId = @"someNewAccountId";
  NSDate *expiryFirst = [NSDate dateWithTimeIntervalSince1970:1900];
  NSDate *expirySecond = [NSDate dateWithTimeIntervalSinceNow:1000];

  // When
  [self.sut saveAuthToken:authToken withAccountId:accountId expiresOn:expiryFirst];
  [self.sut saveAuthToken:newAuthToken withAccountId:newAccountId expiresOn:expirySecond];

  // Then
  NSArray<MSAuthTokenInfo *> *actualAuthTokensHistory = [MSMockKeychainUtil arrayForKey:kMSAuthTokenArrayKey];
  MSAuthTokenInfo *latestAuthTokenInfo = actualAuthTokensHistory[2];
  XCTAssertNil(latestAuthTokenInfo.authToken);
}

- (void)testSaveAuthTokenExtendsStartTimeIfAccountTheSame {
  
  // If
  NSString *authToken = @"someToken";
  NSString *newAuthToken = @"someNewAuthToken";
  NSString *accountId = @"someAccountId";
  NSDate *expiryFirst = [NSDate dateWithTimeIntervalSince1970:1900];
  NSDate *expirySecond = [NSDate dateWithTimeIntervalSinceNow:1000];

  // When
  [self.sut saveAuthToken:authToken withAccountId:accountId expiresOn:expiryFirst];
  [self.sut saveAuthToken:newAuthToken withAccountId:accountId expiresOn:expirySecond];

  // Then
  NSArray<MSAuthTokenInfo *> *actualAuthTokensHistory = [MSMockKeychainUtil arrayForKey:kMSAuthTokenArrayKey];
  MSAuthTokenInfo *latestAuthTokenInfo = [actualAuthTokensHistory lastObject];
  XCTAssertTrue([latestAuthTokenInfo.startTime isEqualToDate:expiryFirst]);
}
@end
