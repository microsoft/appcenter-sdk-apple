// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthTokenContext.h"
#import "MSAuthTokenContextDelegate.h"
#import "MSAuthTokenContextPrivate.h"
#import "MSAuthTokenInfo.h"
#import "MSAuthTokenValidityInfo.h"
#import "MSConstants+Internal.h"
#import "MSConstants.h"
#import "MSEncrypter.h"
#import "MSMockUserDefaults.h"
#import "MSTestFrameworks.h"
#import "MSUtility+File.h"

@interface MSAuthTokenValidityInfo (Test)
+ (instancetype)initWithAuthToken:(nullable NSString *)authToken
                     andStartTime:(nullable NSDate *)startTime
                       andEndTime:(nullable NSDate *)endTime;
@end

@interface MSAuthTokenContextTests : XCTestCase

@property(nonatomic) MSAuthTokenContext *sut;
@property(nonatomic) MSMockUserDefaults *settingsMock;
@property(nonatomic) id utilityMock;

@end

@implementation MSAuthTokenContextTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
  [MSAuthTokenContext resetSharedInstance];

  // Do NOT use the shared instance to avoid impact on other tests.
  self.sut = [MSAuthTokenContext new];
  self.settingsMock = [MSMockUserDefaults new];
  self.utilityMock = OCMClassMock([MSUtility class]);
}

- (void)tearDown {
  [MSAuthTokenContext resetSharedInstance];
  [self.settingsMock stopMocking];
  [self.utilityMock stopMocking];
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
  [self.sut setAuthToken:expectedAuthToken withAccountId:expectedHomeAccountId expiresOn:nil];

  // Then
  XCTAssertEqualObjects([self.sut authToken], expectedAuthToken);
  XCTAssertEqualObjects([self.sut accountId], expectedHomeAccountId);
  OCMVerify([delegateMock authTokenContext:self.sut
                        didUpdateAccountId:[OCMArg checkWithBlock:^BOOL(id obj) {
                          return [(NSString *)obj isEqualToString:expectedAccountId];
                        }]]);
  NSArray<MSAuthTokenInfo *> *history = [self decryptedHistory];
  XCTAssertNotNil(history);
  XCTAssertEqual([history count], 1);
  XCTAssertEqualObjects(history[0].authToken, expectedAuthToken);
  XCTAssertEqualObjects(history[0].accountId, expectedHomeAccountId);
}

- (void)testSetAuthTokenWithGap {

  // If
  NSDate *expectedGapStartDate = [NSDate dateWithTimeIntervalSinceNow:-10];
  MSAuthTokenInfo *oldToken = [[MSAuthTokenInfo alloc] initWithAuthToken:@"oldToken"
                                                               accountId:@"oldAccountId"
                                                               startTime:[NSDate dateWithTimeIntervalSinceNow:-60]
                                                               expiresOn:expectedGapStartDate];
  NSMutableArray<MSAuthTokenInfo *> *tokenHistory = [[NSMutableArray<MSAuthTokenInfo *> alloc] initWithObjects:oldToken, nil];
  [self.sut setAuthTokenHistoryArray:tokenHistory];

  // When
  [self.sut setAuthToken:@"newToken" withAccountId:@"newAccountId" expiresOn:[NSDate dateWithTimeIntervalSinceNow:+42]];

  // Then
  XCTAssertEqual([[self.sut authTokenHistory] count], 3);
  MSAuthTokenInfo *actualToken = [[self.sut authTokenHistory] objectAtIndex:1];
  XCTAssertNil(actualToken.authToken);
  XCTAssertTrue([actualToken.startTime isEqualToDate:expectedGapStartDate]);
  XCTAssertNotNil(actualToken.expiresOn);
}

- (void)testSetAuthTokenDoesNotTriggerNewUserOnSameAccount {

  // If
  NSString *expectedAuthToken = @"authToken1";
  NSString *expectedAccountId = @"account1";
  id<MSAuthTokenContextDelegate> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut setAuthToken:expectedAuthToken withAccountId:expectedAccountId expiresOn:nil];

  // Then
  OCMVerify([delegateMock authTokenContext:self.sut
                        didUpdateAccountId:[OCMArg checkWithBlock:^BOOL(id obj) {
                          return [(NSString *)obj isEqualToString:expectedAccountId];
                        }]]);

  OCMVerify([delegateMock authTokenContext:self.sut didUpdateAuthToken:expectedAuthToken]);

  // When
  [self.sut setAuthToken:expectedAuthToken withAccountId:expectedAccountId expiresOn:nil];

  // Then
  OCMVerify([delegateMock authTokenContext:self.sut didUpdateAuthToken:expectedAuthToken]);
  OCMReject([delegateMock authTokenContext:self.sut didUpdateAccountId:OCMOCK_ANY]);
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
  [self.sut setAuthToken:expectedAuthToken withAccountId:expectedAccountId expiresOn:nil];

  // Then
  OCMVerify([delegateMock authTokenContext:self.sut
                        didUpdateAccountId:[OCMArg checkWithBlock:^BOOL(id obj) {
                          return [(NSString *)obj isEqualToString:expectedAccountId];
                        }]]);

  // When
  [self.sut setAuthToken:expectedAuthToken2 withAccountId:expectedAccountId2 expiresOn:nil];

  // Then
  OCMVerify([delegateMock authTokenContext:self.sut
                        didUpdateAccountId:[OCMArg checkWithBlock:^BOOL(id obj) {
                          return [(NSString *)obj isEqualToString:expectedAccountId];
                        }]]);
}

- (void)testSetAnonymousAuthTokenInEmptyHistoryDoesNotPersistHistory {

  // If
  id<MSAuthTokenContextDelegate> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  for (int i = 0; i < kMSMaxAuthTokenArraySize; i++) {
    [self.sut setAuthToken:nil withAccountId:nil expiresOn:nil];
  }

  // Then
  NSArray<MSAuthTokenInfo *> *history = [self decryptedHistory];
  XCTAssertNil(history);
}

- (void)testRemoveDelegate {

  // If
  id delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [self.sut addDelegate:delegateMock];

  // Then
  OCMReject([delegateMock authTokenContext:self.sut didUpdateAccountId:OCMOCK_ANY]);

  // When
  [self.sut removeDelegate:delegateMock];
  [self.sut setAuthToken:@"some-token" withAccountId:@"someome" expiresOn:nil];

  // Then
  OCMVerifyAll(delegateMock);
}

- (void)testSaveAuthToken {

  // If
  NSString *expectedToken = @"someToken";
  NSString *expectedAccount = @"someAccountData";

  // When
  [self.sut setAuthToken:expectedToken withAccountId:expectedAccount expiresOn:nil];
  MSAuthTokenInfo *actualAuthTokenInfo = [[self.sut authTokenHistory] lastObject];

  // Then
  XCTAssertEqual(actualAuthTokenInfo.authToken, expectedToken);
  XCTAssertNotNil(actualAuthTokenInfo.startTime);
  XCTAssertNil(actualAuthTokenInfo.expiresOn);
  XCTAssertTrue([expectedAccount isEqualToString:actualAuthTokenInfo.accountId]);
}

- (void)testSaveAuthTokenWhenTokenIsEmpty {

  // If
  MSAuthTokenInfo *authTokenInfo = [[MSAuthTokenInfo alloc] initWithAuthToken:@"someToken"
                                                                    accountId:@"someAccountId"
                                                                    startTime:nil
                                                                    expiresOn:nil];
  NSMutableArray<MSAuthTokenInfo *> *authTokenHistory = [NSMutableArray<MSAuthTokenInfo *> new];
  [authTokenHistory addObject:authTokenInfo];
  [self.sut setAuthTokenHistory:authTokenHistory];

  // When
  [self.sut setAuthToken:nil withAccountId:@"someNewAccountData" expiresOn:nil];
  MSAuthTokenInfo *actualAuthTokenInfo = [[self.sut authTokenHistory] lastObject];

  // Then
  XCTAssertNil(actualAuthTokenInfo.authToken);
}

- (void)testSaveAuthTokenWhenAccountIsEmpty {

  // If
  NSString *expectedToken = @"someNewToken";

  // When
  [self.sut setAuthToken:expectedToken withAccountId:nil expiresOn:nil];
  MSAuthTokenInfo *actualAuthTokenInfo = [[self.sut authTokenHistory] lastObject];

  // Then
  XCTAssertEqual(actualAuthTokenInfo.authToken, expectedToken);
  XCTAssertNotNil(actualAuthTokenInfo.startTime);
  XCTAssertNil(actualAuthTokenInfo.expiresOn);
  XCTAssertNil(actualAuthTokenInfo.accountId);
}

- (void)testRetrieveAuthTokenReturnsLatestHistoryElement {

  // If
  NSString *expectedAuthToken = @"expectedAuthToken";
  MSAuthTokenInfo *authTokenInfo1 = [[MSAuthTokenInfo alloc] initWithAuthToken:@"someAuthToken"
                                                                     accountId:@"someAccountId"
                                                                     startTime:nil
                                                                     expiresOn:nil];
  MSAuthTokenInfo *authTokenInfo2 = [[MSAuthTokenInfo alloc] initWithAuthToken:expectedAuthToken
                                                                     accountId:@"someAccountId"
                                                                     startTime:nil
                                                                     expiresOn:nil];
  NSMutableArray<MSAuthTokenInfo *> *authTokenHistory = [NSMutableArray<MSAuthTokenInfo *> new];
  [authTokenHistory addObject:authTokenInfo1];
  [authTokenHistory addObject:authTokenInfo2];
  [self.sut setAuthTokenHistory:authTokenHistory];

  // When
  NSString *actualAuthToken = [self.sut authToken];

  // Then
  XCTAssertTrue([actualAuthToken isEqualToString:expectedAuthToken]);
}

- (void)testGetAuthTokenValidityArray {

  // If
  NSString *expectedAuthToken = @"expectedAuthToken";
  NSDate *expiryFirst = [NSDate dateWithTimeIntervalSince1970:1900];
  NSDate *expirySecond = [NSDate dateWithTimeIntervalSinceNow:1000];
  NSDate *expiryThird = [NSDate dateWithTimeIntervalSinceNow:50000];
  [self.sut setAuthToken:@"unexpectedAuthToken1" withAccountId:@"someAccountId" expiresOn:nil];
  [self.sut setAuthToken:@"unexpectedAuthToken2" withAccountId:@"anotherAccountId" expiresOn:expiryFirst];
  [self.sut setAuthToken:@"unexpectedAuthToken3" withAccountId:@"anotherAccountId" expiresOn:expirySecond];
  [self.sut setAuthToken:expectedAuthToken withAccountId:@"anotherAccountId" expiresOn:expiryThird];

  // When
  NSArray<MSAuthTokenValidityInfo *> *actualAuthTokenValidityArray = [self.sut authTokenValidityArray];

  // Then
  XCTAssertEqual(expectedAuthToken, actualAuthTokenValidityArray.lastObject.authToken);
}

- (void)testRemoveAuthToken {

  // If
  NSString *tokenExpectedToBeDeleted = @"someAuthToken";
  [self.sut setAuthToken:tokenExpectedToBeDeleted withAccountId:@"someAccountId" expiresOn:nil];
  [self.sut setAuthToken:@"someNewAuthToken" withAccountId:@"anotherAccountId" expiresOn:nil];

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
  [self.sut setAuthToken:tokenExpectedNotToBeDeleted withAccountId:@"someAccountId" expiresOn:nil];

  // When
  [self.sut removeAuthToken:tokenExpectedNotToBeDeleted];
  NSArray<MSAuthTokenInfo *> *actualAuthTokenArray = [self.sut authTokenHistory];

  // Then
  XCTAssertEqual(actualAuthTokenArray.count, 1);
}

- (void)testSaveAuthTokenLimitsHistorySize {

  // If
  NSString *accountId = @"someAccountId";

  // When
  for (int i = 0; i < kMSMaxAuthTokenArraySize; ++i) {
    [self.sut setAuthToken:@"someToken" withAccountId:accountId expiresOn:nil];
    [self.sut setAuthToken:nil withAccountId:accountId expiresOn:nil];
  }
  NSArray<MSAuthTokenInfo *> *actualAuthTokensHistory = [self.sut authTokenHistory];

  // Then
  XCTAssertEqual([actualAuthTokensHistory count], kMSMaxAuthTokenArraySize);
}

- (void)testSaveAuthTokenAddsNewItemOnlyIfDiffersFromLatest {

  // If
  NSString *authToken = @"someToken";
  NSString *authToken1 = @"someNewToken";
  NSString *authToken2 = @"someNewNewToken";
  NSString *accountId = @"someAccountId";

  // When
  for (int i = 0; i < 2; ++i) {
    [self.sut setAuthToken:authToken withAccountId:accountId expiresOn:nil];
  }
  for (int i = 0; i < 2; ++i) {
    [self.sut setAuthToken:authToken1 withAccountId:accountId expiresOn:nil];
  }
  for (int i = 0; i < 2; ++i) {
    [self.sut setAuthToken:authToken2 withAccountId:accountId expiresOn:nil];
  }
  NSArray<MSAuthTokenInfo *> *actualAuthTokensHistory = [self.sut authTokenHistory];
  MSAuthTokenInfo *latestAuthTokenInfo = [actualAuthTokensHistory lastObject];

  // Then
  XCTAssertEqual([actualAuthTokensHistory count], 3);
  XCTAssertEqual(latestAuthTokenInfo.authToken, authToken2);
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
  [self.sut setAuthToken:authToken withAccountId:accountId expiresOn:expiryFirst];
  [self.sut setAuthToken:newAuthToken withAccountId:newAccountId expiresOn:expirySecond];

  // Then
  NSArray<MSAuthTokenInfo *> *actualAuthTokensHistory = [self.sut authTokenHistory];
  MSAuthTokenInfo *latestAuthTokenInfo = actualAuthTokensHistory[1];
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
  [self.sut setAuthToken:authToken withAccountId:accountId expiresOn:expiryFirst];
  [self.sut setAuthToken:newAuthToken withAccountId:accountId expiresOn:expirySecond];

  // Then
  NSArray<MSAuthTokenInfo *> *actualAuthTokensHistory = [self.sut authTokenHistory];
  MSAuthTokenInfo *latestAuthTokenInfo = [actualAuthTokensHistory lastObject];
  XCTAssertTrue([latestAuthTokenInfo.startTime isEqualToDate:expiryFirst]);
}

- (void)testCheckIfTokenNeedsToBeRefreshedTokenIsNotlastTokenEntry {
  NSString *expectedAuthToken1 = @"authToken1";
  NSString *expectedAccountId1 = @"account1";
  NSString *expectedAuthToken2 = @"authToken2";
  id<MSAuthTokenContextDelegate> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  OCMReject([delegateMock authTokenContext:OCMOCK_ANY refreshAuthTokenForAccountId:OCMOCK_ANY]);
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut setAuthToken:expectedAuthToken1 withAccountId:expectedAccountId1 expiresOn:nil];
  MSAuthTokenValidityInfo *authToken = [[MSAuthTokenValidityInfo alloc] initWithAuthToken:expectedAuthToken2 startTime:nil endTime:nil];
  [self.sut checkIfTokenNeedsToBeRefreshed:authToken];
}

- (void)testCheckIfTokenNeedsToBeRefreshed {

  // If
  NSString *expectedAuthToken = @"authToken1";
  NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-((60.0f * 60.0f * 24.0f))];
  NSDate *expiresDate = [NSDate dateWithTimeIntervalSinceNow:+(60.0f * 60.0f * 24.0f)];
  id<MSAuthTokenContextDelegate> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [self.sut addDelegate:delegateMock];
  OCMReject([delegateMock authTokenContext:OCMOCK_ANY refreshAuthTokenForAccountId:OCMOCK_ANY]);

  NSArray<MSAuthTokenInfo *> *authTokenHistory = @[ [[MSAuthTokenInfo alloc] initWithAuthToken:expectedAuthToken
                                                                                     accountId:@"test"
                                                                                     startTime:nil
                                                                                     expiresOn:nil] ];
  [self.sut setAuthTokenHistory:authTokenHistory];
  MSAuthTokenValidityInfo *authToken = [[MSAuthTokenValidityInfo alloc] initWithAuthToken:expectedAuthToken
                                                                                startTime:startDate
                                                                                  endTime:expiresDate];

  // When
  [self.sut checkIfTokenNeedsToBeRefreshed:authToken];
}

- (void)testExpiresSoonTrue {

  // If
  NSString *expectedAuthToken = @"authToken1";
  NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-((60.0f * 60.0f * 24.0f) * 2)];
  NSDate *expiresDate = [NSDate dateWithTimeIntervalSinceNow:-(60.0f * 60.0f * 24.0f)];
  MSAuthTokenValidityInfo *authToken = [[MSAuthTokenValidityInfo alloc] initWithAuthToken:expectedAuthToken
                                                                                startTime:startDate
                                                                                  endTime:expiresDate];

  // When
  bool *isExpiresSoon = [authToken expiresSoon];

  // Then
  XCTAssertTrue(isExpiresSoon);
}

- (void)testExpiresSoonFalse {

  // If
  NSString *expectedAuthToken = @"authToken1";
  NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-((60.0f * 60.0f * 24.0f))];
  NSDate *expiresDate = [NSDate dateWithTimeIntervalSinceNow:+(60.0f * 60.0f * 24.0f)];
  MSAuthTokenValidityInfo *authToken = [[MSAuthTokenValidityInfo alloc] initWithAuthToken:expectedAuthToken
                                                                                startTime:startDate
                                                                                  endTime:expiresDate];

  // When
  bool *isExpiresSoon = [authToken expiresSoon];

  // Then
  XCTAssertFalse(isExpiresSoon);
}

- (void)testRefreshAuthTokenForAccountId {

  // If
  NSString *expectedAuthToken = @"authToken1";
  NSString *expectedAccountId = @"account1";
  NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-((60.0f * 60.0f * 24.0f) * 2)];
  NSDate *expiresDate = [NSDate dateWithTimeIntervalSinceNow:+500];
  id<MSAuthTokenContextDelegate> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [self.sut addDelegate:delegateMock];
  [self.sut setAuthToken:expectedAuthToken withAccountId:expectedAccountId expiresOn:expiresDate];
  MSAuthTokenValidityInfo *authToken = [[MSAuthTokenValidityInfo alloc] initWithAuthToken:expectedAuthToken
                                                                                startTime:startDate
                                                                                  endTime:expiresDate];

  // When
  [self.sut checkIfTokenNeedsToBeRefreshed:authToken];

  // Then
  OCMVerify([delegateMock authTokenContext:OCMOCK_ANY refreshAuthTokenForAccountId:expectedAccountId]);
}

- (void)testSameAuthTokenNotRefreshedTwice {

  // If
  NSString *expectedAuthToken = @"authToken1";
  NSString *expectedAccountId = @"account1";
  NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-((60.0f * 60.0f * 24.0f) * 2)];
  NSDate *expiresDate = [NSDate dateWithTimeIntervalSinceNow:+500];
  id<MSAuthTokenContextDelegate> delegateMock = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  __block int count = 0;
  OCMStub([delegateMock authTokenContext:OCMOCK_ANY didUpdateAccountId:expectedAccountId]).andDo(^(NSInvocation *__unused invocation) {
    count++;
  });
  [self.sut addDelegate:delegateMock];
  [self.sut setAuthToken:expectedAuthToken withAccountId:expectedAccountId expiresOn:expiresDate];
  MSAuthTokenValidityInfo *authToken = [[MSAuthTokenValidityInfo alloc] initWithAuthToken:expectedAuthToken
                                                                                startTime:startDate
                                                                                  endTime:expiresDate];

  // When
  [self.sut checkIfTokenNeedsToBeRefreshed:authToken];

  // Then
  XCTAssertEqual(count, 1);

  // When
  [self.sut checkIfTokenNeedsToBeRefreshed:authToken];

  // Then
  XCTAssertEqual(count, 1);
}

- (void)testFinishDoesNotResetTokenIfPrevented {

  // If
  id sut = OCMPartialMock(self.sut);
  [sut preventResetAuthTokenAfterStart];
  OCMReject([sut setAuthToken:OCMOCK_ANY withAccountId:OCMOCK_ANY expiresOn:OCMOCK_ANY]);

  // When
  [sut finishInitialize];

  // Then
  OCMVerifyAll(sut);
  [sut stopMocking];
}

- (void)testFinishResetsTokenIfNotPrevented {

  // If
  OCMStub([self.sut setAuthToken:nil withAccountId:nil expiresOn:nil]);

  // When
  [self.sut finishInitialize];

  // Then
  OCMVerify([self.sut setAuthToken:nil withAccountId:nil expiresOn:nil]);
}

- (void)testFinishResetsTokenIfNotPreventedOnlyOnce {

  // If
  id sut = OCMPartialMock(self.sut);
  __block int callCount = 0;
  OCMStub([sut setAuthToken:nil withAccountId:nil expiresOn:nil]).andDo(^(__unused NSInvocation *invocation) {
    ++callCount;
  });

  // When
  [sut finishInitialize];

  // Another module starts.
  [sut finishInitialize];

  // Then
  XCTAssertEqual(callCount, 1);
  [sut stopMocking];
}

- (NSArray<MSAuthTokenInfo *> *)decryptedHistory {
  NSData *encryptedData = [self.settingsMock objectForKey:kMSAuthTokenHistoryKey];
  NSData *decryptedData = [self.sut.encrypter decryptData:encryptedData];
  NSArray<MSAuthTokenInfo *> *history = [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
  return history;
}

@end
