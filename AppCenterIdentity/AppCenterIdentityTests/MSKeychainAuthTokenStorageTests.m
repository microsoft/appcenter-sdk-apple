// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSAuthTokenInfo.h"
#import "MSIdentityConstants.h"
#import "MSKeychainAuthTokenStorage.h"
#import "MSMockKeychainUtil.h"
#import "MSMockUserDefaults.h"
#import "MSTestFrameworks.h"
#import "MSUtility+File.h"

@interface MSKeychainAuthTokenStorageTests : XCTestCase

@property(nonatomic) MSKeychainAuthTokenStorage *sut;
@property(nonatomic) MSMockUserDefaults *settingsMock;
@property(nonatomic) id utilityMock;
@property(nonatomic) id keychainUtilMock;

@end

@implementation MSKeychainAuthTokenStorageTests

- (void)setUp {
  [super setUp];
  self.settingsMock = [MSMockUserDefaults new];
  self.utilityMock = OCMClassMock([MSUtility class]);
  self.sut = [MSKeychainAuthTokenStorage new];
  self.keychainUtilMock = [MSMockKeychainUtil new];
}

- (void)tearDown {
  [super tearDown];
  [self.settingsMock stopMocking];
  [self.utilityMock stopMocking];
  [self.keychainUtilMock stopMocking];
}

- (void)testSaveAuthToken {

  // If
  NSString *expectedToken = @"someToken";
  NSString *expectedAccount = @"someAccountData";

  // When
  [self.sut saveAuthToken:expectedToken withAccountId:expectedAccount expiresOn:nil];
  MSAuthTokenInfo *actualAuthTokenInfo = [[MSMockKeychainUtil arrayForKey:kMSIdentityAuthTokenArrayKey] lastObject];

  // Then
  XCTAssertEqual(actualAuthTokenInfo.authToken, expectedToken);
  XCTAssertNotNil(actualAuthTokenInfo.startTime);
  XCTAssertNil(actualAuthTokenInfo.endTime);
  XCTAssertEqual([self.settingsMock objectForKey:kMSIdentityMSALAccountHomeAccountKey], expectedAccount);
}

- (void)testSaveAuthTokenWhenTokenIsEmpty {

  // If
  MSAuthTokenInfo *authTokenInfo = [[MSAuthTokenInfo alloc] initWithAuthToken:@"someToken"
                                                                 andAccountId:@"someAccountId"
                                                                 andStartTime:nil
                                                                   andEndTime:nil];
  NSMutableArray<MSAuthTokenInfo *> *authTokenHistory = [NSMutableArray<MSAuthTokenInfo *> new];
  [authTokenHistory addObject:authTokenInfo];
  [MSMockKeychainUtil storeArray:authTokenHistory forKey:kMSIdentityAuthTokenArrayKey];
  [self.settingsMock setObject:@"someAccountData" forKey:kMSIdentityMSALAccountHomeAccountKey];

  // When
  [self.sut saveAuthToken:nil withAccountId:@"someNewAccountData" expiresOn:nil];
  MSAuthTokenInfo *actualAuthTokenInfo = [[MSMockKeychainUtil arrayForKey:kMSIdentityAuthTokenArrayKey] lastObject];

  // Then
  XCTAssertNil(actualAuthTokenInfo.authToken);
  XCTAssertNil([self.settingsMock objectForKey:kMSIdentityMSALAccountHomeAccountKey]);
}

- (void)testSaveAuthTokenWhenAccountIsEmpty {

  // If
  NSString *expectedToken = @"someNewToken";
  [self.settingsMock setObject:@"someAccountData" forKey:kMSIdentityMSALAccountHomeAccountKey];

  // When
  [self.sut saveAuthToken:expectedToken withAccountId:nil expiresOn:nil];
  MSAuthTokenInfo *actualAuthTokenInfo = [[MSMockKeychainUtil arrayForKey:kMSIdentityAuthTokenArrayKey] lastObject];

  // Then
  XCTAssertEqual(actualAuthTokenInfo.authToken, expectedToken);
  XCTAssertNotNil(actualAuthTokenInfo.startTime);
  XCTAssertNil(actualAuthTokenInfo.endTime);
  XCTAssertNil([self.settingsMock objectForKey:kMSIdentityMSALAccountHomeAccountKey]);
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
  [MSMockKeychainUtil storeArray:authTokenHistory forKey:kMSIdentityAuthTokenArrayKey];

  // When
  NSString *actualAuthToken = [self.sut retrieveAuthToken];

  // Then
  XCTAssertEqual(actualAuthToken, expectedAuthToken);
}

- (void)testSaveAuthTokenLimitsHistorySize {

  // If
  NSString *accountId = @"someAccountId";

  // When
  for (int i = 0; i < kMSIdentityMaxAuthTokenArraySize; ++i) {
    [self.sut saveAuthToken:@"someToken" withAccountId:accountId expiresOn:nil];
    [self.sut saveAuthToken:nil withAccountId:accountId expiresOn:nil];
  }
  NSMutableArray<MSAuthTokenInfo *> *actualAuthTokensHistory = [MSMockKeychainUtil arrayForKey:kMSIdentityAuthTokenArrayKey];

  // Then
  XCTAssertEqual([actualAuthTokensHistory count], kMSIdentityMaxAuthTokenArraySize);
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
  NSMutableArray<MSAuthTokenInfo *> *actualAuthTokensHistory = [MSMockKeychainUtil arrayForKey:kMSIdentityAuthTokenArrayKey];
  MSAuthTokenInfo *latestAuthTokenInfo = [actualAuthTokensHistory lastObject];

  // Then
  XCTAssertEqual([actualAuthTokensHistory count], 3 + 1);
  XCTAssertEqual(latestAuthTokenInfo.authToken, authToken);
}

@end
