// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSIdentityConstants.h"
#import "MSKeychainAuthTokenStorage.h"
#import "MSMockKeychainUtil.h"
#import "MSMockUserDefaults.h"
#import "MSTestFrameworks.h"
#import "MSUtility+File.h"
#import <OCMock/OCMock.h>

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

- (void)testSaveAuthToken {

  // If
  NSString *expectedToken = @"someToken";
  NSString *expectedAccount = @"someAccountData";

  // When
  [self.sut saveAuthToken:expectedToken withAccountId:expectedAccount];

  // Then
  XCTAssertEqual([MSMockKeychainUtil stringForKey:kMSIdentityAuthTokenKey], expectedToken);
  XCTAssertEqual([self.settingsMock objectForKey:kMSIdentityMSALAccountHomeAccountKey], expectedAccount);
}

- (void)testSaveAuthTokenWhenTokenIsEmpty {

  // If
  [MSMockKeychainUtil storeString:@"someToken" forKey:kMSIdentityAuthTokenKey];
  [self.settingsMock setObject:@"someAccountData" forKey:kMSIdentityMSALAccountHomeAccountKey];

  // When
  [self.sut saveAuthToken:nil withAccountId:@"someNewAccountData"];

  // Then
  XCTAssertNil([MSMockKeychainUtil stringForKey:kMSIdentityAuthTokenKey]);
  XCTAssertNil([self.settingsMock objectForKey:kMSIdentityMSALAccountHomeAccountKey]);
}

- (void)testSaveAuthTokenWhenAccountIsEmpty {

  // If
  NSString *expectedToken = @"someNewToken";
  [MSMockKeychainUtil storeString:@"someToken" forKey:kMSIdentityAuthTokenKey];
  [self.settingsMock setObject:@"someAccountData" forKey:kMSIdentityMSALAccountHomeAccountKey];

  // When
  [self.sut saveAuthToken:expectedToken withAccountId:nil];

  // Then
  XCTAssertEqual([MSMockKeychainUtil stringForKey:kMSIdentityAuthTokenKey], expectedToken);
  XCTAssertNil([self.settingsMock objectForKey:kMSIdentityMSALAccountHomeAccountKey]);
}

- (void)tearDown {
  [super tearDown];
  [self.settingsMock stopMocking];
  [self.utilityMock stopMocking];
  [self.keychainUtilMock stopMocking];
}

@end
