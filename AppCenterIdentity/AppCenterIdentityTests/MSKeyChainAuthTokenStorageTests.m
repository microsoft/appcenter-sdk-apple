// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSMockKeychainUtil.h"
#import "MSMockUserDefaults.h"
#import "MSTestFrameworks.h"
#import "MSUtility+File.h"
#import "MSKeychainAuthTokenStorage.h"
#import "MSIdentityConstants.h"
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

//- (void)testRemoveAuthToken {
//
//  // If
//  [MSMockKeychainUtil storeString:@"someToken" forKey:kMSIdentityAuthTokenKey];
//
//  // When
//  XCTAssertTrue([self.sut removeAuthToken]);
//  XCTAssertFalse([self.sut removeAuthToken]);
//}

- (void)tearDown {
  [super tearDown];
  [self.settingsMock stopMocking];
  [self.utilityMock stopMocking];
  [self.keychainUtilMock stopMocking];
}

@end
