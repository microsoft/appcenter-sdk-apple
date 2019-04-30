// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSALAccount.h"
#import "MSALAccountId.h"
#import "MSALAuthority.h"
#import "MSALError.h"
#import "MSALPublicClientApplication.h"
#import "MSALResult.h"
#import "MSAuthConfigIngestion.h"
#import "MSAuthConstants.h"
#import "MSAuthErrors.h"
#import "MSAuthPrivate.h"
#import "MSAuthTokenContext.h"
#import "MSAuthTokenContextDelegate.h"
#import "MSAuthTokenContextPrivate.h"
#import "MSAuthTokenInfo.h"
#import "MSAuthTokenValidityInfo.h"
#import "MSChannelGroupProtocol.h"
#import "MSChannelUnitProtocol.h"
#import "MSConstants.h"
#import "MSHttpTestUtil.h"
#import "MSMockUserDefaults.h"
#import "MSServiceAbstractProtected.h"
#import "MSTestFrameworks.h"
#import "MSUserInformation.h"
#import "MSUtility+File.h"

static NSString *const kMSTestAppSecret = @"TestAppSecret";

@interface MSAuth (Test)

- (void)configAuthenticationClient;
- (BOOL)removeAccount;
- (MSALAccount *)retrieveAccountWithAccountId:(NSString *)homeAccountId;

@end

@interface MSAuthTests : XCTestCase

@property(nonatomic) MSAuth *sut;
@property(nonatomic) MSMockUserDefaults *settingsMock;
@property(nonatomic) NSDictionary *dummyConfigDic;
@property(nonatomic) id utilityMock;
@property(nonatomic) id ingestionMock;
@property(nonatomic) id clientApplicationMock;
@property(nonatomic) MSUserInformation *signInUserInformation;
@property(nonatomic) NSError *signInError;
@property(nonatomic) MSALCompletionBlock msalCompletionBlock;

@end

@implementation MSAuthTests

- (void)setUp {
  [super setUp];
  self.settingsMock = [MSMockUserDefaults new];
  self.utilityMock = OCMClassMock([MSUtility class]);
  self.dummyConfigDic = @{
    @"identity_scope" : @"scope",
    @"client_id" : @"clientId",
    @"redirect_uri" : @"https://contoso.com/auth/path",
    @"authorities" : @[
      @{@"type" : @"B2C", @"default" : @YES, @"authority_url" : @"https://contoso.com/auth/path1"},
      @{@"type" : @"RandomType", @"default" : @NO, @"authority_url" : @"https://contoso.com/auth/path2"}
    ]
  };
  self.sut = [MSAuth sharedInstance];
  self.ingestionMock = OCMPartialMock([MSAuthConfigIngestion alloc]);
  OCMStub([self.ingestionMock alloc]).andReturn(self.ingestionMock);
  self.clientApplicationMock = OCMClassMock([MSALPublicClientApplication class]);
}

- (void)tearDown {
  [super tearDown];
  [MSAuth resetSharedInstance];
  self.sut = [MSAuth sharedInstance];
  [MSAuthTokenContext resetSharedInstance];
  [self.settingsMock stopMocking];
  [self.utilityMock stopMocking];
  [self.ingestionMock stopMocking];
  [self.clientApplicationMock stopMocking];
}

- (void)testApplyEnabledStateWorks {

  // If
  [[MSAuth sharedInstance] startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                                       appSecret:kMSTestAppSecret
                         transmissionTargetToken:nil
                                 fromApplication:YES];

  // When
  [self.sut setEnabled:YES];

  // Then
  XCTAssertTrue([self.sut isEnabled]);

  // When
  [self.sut setEnabled:NO];

  // Then
  XCTAssertFalse([self.sut isEnabled]);

  // When
  [self.sut setEnabled:YES];

  // Then
  XCTAssertTrue([self.sut isEnabled]);
}

- (void)testTokenIsPersistedOnStart {

  // If
  NSString *previousAuthToken = @"any-token";
  [[MSAuthTokenContext sharedInstance] setAuthToken:@"any-token" withAccountId:nil expiresOn:nil];
  [[MSAuth sharedInstance] startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                                       appSecret:kMSTestAppSecret
                         transmissionTargetToken:nil
                                 fromApplication:YES];

  // When
  [[MSAuthTokenContext sharedInstance] finishInitialize];

  // Then
  XCTAssertTrue([previousAuthToken isEqual:[[MSAuthTokenContext sharedInstance] authToken]]);
}

- (void)testTokenIsPersistedOnSeparateStart {

  // If
  NSString *previousAuthToken = @"any-token";
  [[MSAuthTokenContext sharedInstance] setAuthToken:@"any-token" withAccountId:nil expiresOn:nil];
  [[MSAuth sharedInstance] startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                                       appSecret:kMSTestAppSecret
                         transmissionTargetToken:nil
                                 fromApplication:YES];

  // When
  [[MSAuthTokenContext sharedInstance] finishInitialize];

  // Another module started separately.
  [[MSAuthTokenContext sharedInstance] finishInitialize];

  // Then
  XCTAssertTrue([previousAuthToken isEqual:[[MSAuthTokenContext sharedInstance] authToken]]);
}

- (void)testLoadAndDownloadOnEnabling {

  // If
  NSString *expectedETag = @"eTag";
  [self.settingsMock setObject:expectedETag forKey:kMSAuthETagKey];
  NSData *serializedConfig = [NSJSONSerialization dataWithJSONObject:self.dummyConfigDic options:(NSJSONWritingOptions)0 error:nil];
  OCMStub([self.utilityMock loadDataForPathComponent:[self.sut authConfigFilePath]]).andReturn(serializedConfig);
  OCMStub([self.ingestionMock sendAsync:OCMOCK_ANY eTag:OCMOCK_ANY completionHandler:OCMOCK_ANY]);

  // When
  [self.sut applyEnabledState:YES];

  // Then
  XCTAssertTrue([self.sut.authConfig isValid]);
  OCMVerify([self.ingestionMock sendAsync:nil eTag:expectedETag completionHandler:OCMOCK_ANY]);
}

- (void)testEnablingReadsAuthTokenFromKeychainAndDoesNotSetAuthContextIfNilAccount {

  // If
  NSString *expectedToken = @"expected";
  MSAuthTokenInfo *authTokenInfo = [[MSAuthTokenInfo alloc] initWithAuthToken:expectedToken
                                                                    accountId:@"someAccountId"
                                                                    startTime:nil
                                                                    expiresOn:nil];
  NSMutableArray<MSAuthTokenInfo *> *authTokenHistory = [NSMutableArray<MSAuthTokenInfo *> new];
  [authTokenHistory addObject:authTokenInfo];
  [[MSAuthTokenContext sharedInstance] setAuthTokenHistory:authTokenHistory];
  NSString *expectedETag = @"eTag";
  [self.settingsMock setObject:expectedETag forKey:kMSAuthETagKey];
  NSData *serializedConfig = [NSJSONSerialization dataWithJSONObject:self.dummyConfigDic options:(NSJSONWritingOptions)0 error:nil];
  OCMStub([self.utilityMock loadDataForPathComponent:[self.sut authConfigFilePath]]).andReturn(serializedConfig);
  id<MSAuthTokenContextDelegate> mockDelegate = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [[MSAuthTokenContext sharedInstance] addDelegate:mockDelegate];
  OCMStub([self.ingestionMock sendAsync:OCMOCK_ANY eTag:OCMOCK_ANY completionHandler:OCMOCK_ANY]);

  // Then
  OCMReject([mockDelegate authTokenContext:OCMOCK_ANY didUpdateAuthToken:OCMOCK_ANY]);

  // When
  [self.sut applyEnabledState:YES];
}

- (void)testEnablingReadsAuthTokenFromKeychainAndDoesNotSetAuthContextIfNil {

  // If
  NSString *expectedETag = @"eTag";
  [self.settingsMock setObject:expectedETag forKey:kMSAuthETagKey];
  NSData *serializedConfig = [NSJSONSerialization dataWithJSONObject:self.dummyConfigDic options:(NSJSONWritingOptions)0 error:nil];
  OCMStub([self.utilityMock loadDataForPathComponent:[self.sut authConfigFilePath]]).andReturn(serializedConfig);
  id<MSAuthTokenContextDelegate> mockDelegate = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [[MSAuthTokenContext sharedInstance] addDelegate:mockDelegate];
  OCMStub([self.ingestionMock sendAsync:OCMOCK_ANY eTag:OCMOCK_ANY completionHandler:OCMOCK_ANY]);

  // Then
  OCMReject([mockDelegate authTokenContext:OCMOCK_ANY didUpdateAuthToken:OCMOCK_ANY]);

  // When
  [self.sut applyEnabledState:YES];
}

- (void)testCleanUpOnDisabling {

  // If
  NSString *fakeAccountId = @"some-account-id";
  NSString *fakeToken = @"some-token";
  NSData *serializedConfig = [NSJSONSerialization dataWithJSONObject:self.dummyConfigDic options:(NSJSONWritingOptions)0 error:nil];
  OCMStub([self.utilityMock loadDataForPathComponent:[self.sut authConfigFilePath]]).andReturn(serializedConfig);
  [self.settingsMock setObject:@"eTag" forKey:kMSAuthETagKey];
  [[MSAuth sharedInstance] startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                                       appSecret:kMSTestAppSecret
                         transmissionTargetToken:nil
                                 fromApplication:YES];
  MSAuthTokenInfo *authTokenInfo = [[MSAuthTokenInfo alloc] initWithAuthToken:fakeToken
                                                                    accountId:fakeAccountId
                                                                    startTime:nil
                                                                    expiresOn:nil];
  NSMutableArray<MSAuthTokenInfo *> *authTokenHistory = [NSMutableArray<MSAuthTokenInfo *> new];
  [authTokenHistory addObject:authTokenInfo];
  [[MSAuthTokenContext sharedInstance] setAuthTokenHistory:authTokenHistory];
  [[MSAuthTokenContext sharedInstance] setAuthToken:fakeToken withAccountId:fakeAccountId expiresOn:nil];
  [self.sut setEnabled:YES];
  id accountMock = OCMPartialMock([MSALAccount new]);
  self.sut.clientApplication = self.clientApplicationMock;
  OCMStub([self.clientApplicationMock accountForHomeAccountId:OCMOCK_ANY error:[OCMArg anyObjectRef]]).andReturn(accountMock);

  // When
  [self.sut setEnabled:NO];
  MSAuthTokenInfo *actualAuthTokenInfo = [[[MSAuthTokenContext sharedInstance] authTokenHistory] lastObject];

  // Then
  XCTAssertNil(self.sut.clientApplication);
  XCTAssertNil([MSAuthTokenContext sharedInstance].authToken);
  XCTAssertNil(actualAuthTokenInfo.authToken);
  OCMVerify([self.utilityMock deleteItemForPathComponent:[self.sut authConfigFilePath]]);
  XCTAssertNil([self.settingsMock objectForKey:kMSAuthETagKey]);
  OCMVerify([self.clientApplicationMock removeAccount:OCMOCK_ANY error:[OCMArg anyObjectRef]]);
}

- (void)testCacheNewConfigWhenNoConfig {

  // If
  __block MSSendAsyncCompletionHandler ingestionBlock;
  NSString *expectedETag = @"newETag";
  NSData *newConfig = [NSJSONSerialization dataWithJSONObject:self.dummyConfigDic options:(NSJSONWritingOptions)0 error:nil];
  OCMStub([self.ingestionMock sendAsync:nil eTag:nil completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    // Get ingestion block for later call.
    [invocation retainArguments];
    [invocation getArgument:&ingestionBlock atIndex:4];
  });

  // When
  [self.sut downloadConfigurationWithETag:nil];
  ingestionBlock(@"callId", [MSHttpTestUtil createMockResponseForStatusCode:200 headers:@{kMSETagResponseHeader : expectedETag}], newConfig,
                 nil);

  // Then
  OCMVerify([self.utilityMock createFileAtPathComponent:[self.sut authConfigFilePath]
                                               withData:newConfig
                                             atomically:YES
                                         forceOverwrite:YES]);
  XCTAssertEqualObjects(expectedETag, [self.settingsMock objectForKey:kMSAuthETagKey]);
}

- (void)testCacheNewConfigWhenDeprecatedConfigIsCached {

  // If
  __block MSSendAsyncCompletionHandler ingestionBlock;
  NSString *oldETag = @"oldETag";
  NSString *expectedETag = @"newETag";
  [self.settingsMock setObject:oldETag forKey:kMSAuthETagKey];
  NSData *newConfig = [NSJSONSerialization dataWithJSONObject:self.dummyConfigDic options:(NSJSONWritingOptions)0 error:nil];
  OCMStub([self.ingestionMock sendAsync:nil eTag:oldETag completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    // Get ingestion block for later call.
    [invocation retainArguments];
    [invocation getArgument:&ingestionBlock atIndex:4];
  });

  // When
  [self.sut downloadConfigurationWithETag:oldETag];
  ingestionBlock(@"callId", [MSHttpTestUtil createMockResponseForStatusCode:200 headers:@{kMSETagResponseHeader : expectedETag}], newConfig,
                 nil);

  // Then
  OCMVerify([self.utilityMock createFileAtPathComponent:[self.sut authConfigFilePath]
                                               withData:newConfig
                                             atomically:YES
                                         forceOverwrite:YES]);
  XCTAssertEqualObjects(expectedETag, [self.settingsMock objectForKey:kMSAuthETagKey]);
}

- (void)testDontCacheConfigWhenCachedConfigIsNotDeprecated {

  // If
  __block MSSendAsyncCompletionHandler ingestionBlock;
  NSString *expectedETag = @"eTag";
  NSData *expectedConfig = [NSJSONSerialization dataWithJSONObject:self.dummyConfigDic options:(NSJSONWritingOptions)0 error:nil];
  OCMStub([self.ingestionMock sendAsync:nil eTag:expectedETag completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    // Get ingestion block for later call.
    [invocation retainArguments];
    [invocation getArgument:&ingestionBlock atIndex:4];
  });
  OCMReject([self.utilityMock createFileAtPathComponent:[self.sut authConfigFilePath]
                                               withData:OCMOCK_ANY
                                             atomically:OCMOCK_ANY
                                         forceOverwrite:OCMOCK_ANY]);
  OCMReject([self.settingsMock setObject:OCMOCK_ANY forKey:kMSAuthETagKey]);

  // When
  [self.sut downloadConfigurationWithETag:expectedETag];
  ingestionBlock(@"callId", [MSHttpTestUtil createMockResponseForStatusCode:304 headers:nil], expectedConfig, nil);
}

- (void)testDontCacheConfigWhenReceivedUnexpectedStatusCode {

  // If
  __block MSSendAsyncCompletionHandler ingestionBlock;
  NSString *expectedETag = @"eTag";
  NSData *expectedConfig = [NSJSONSerialization dataWithJSONObject:self.dummyConfigDic options:(NSJSONWritingOptions)0 error:nil];
  OCMStub([self.ingestionMock sendAsync:nil eTag:expectedETag completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    // Get ingestion block for later call.
    [invocation retainArguments];
    [invocation getArgument:&ingestionBlock atIndex:4];
  });
  OCMReject([self.utilityMock createFileAtPathComponent:[self.sut authConfigFilePath]
                                               withData:OCMOCK_ANY
                                             atomically:OCMOCK_ANY
                                         forceOverwrite:OCMOCK_ANY]);
  OCMReject([self.settingsMock setObject:OCMOCK_ANY forKey:kMSAuthETagKey]);

  // When
  [self.sut downloadConfigurationWithETag:expectedETag];
  ingestionBlock(@"callId", [MSHttpTestUtil createMockResponseForStatusCode:500 headers:nil], expectedConfig, nil);
}

#if TARGET_OS_IOS
- (void)testForwardRedirectURLToMSAL {

  // If
  NSURL *expectedURL = [NSURL URLWithString:@"scheme://test"];
  id msalMock = OCMClassMock([MSALPublicClientApplication class]);
  NSString *sourceApplication = @"valid_app";

  // When
  BOOL result = [MSAuth openURL:expectedURL
                        options:@{UIApplicationOpenURLOptionsSourceApplicationKey : sourceApplication}]; // TODO add more tests

  // Then
  OCMVerify([msalMock handleMSALResponse:expectedURL sourceApplication:sourceApplication]);
  XCTAssertFalse(result);
  [msalMock stopMocking];
}

- (void)testForwardRedirectURLToMSALWithoutSourceApplication {

  // If
  NSURL *expectedURL = [NSURL URLWithString:@"scheme://test"];
  id msalMock = OCMClassMock([MSALPublicClientApplication class]);

  // When
  BOOL result = [MSAuth openURL:expectedURL options:@{}];

  // Then
  OCMReject([msalMock handleMSALResponse:expectedURL sourceApplication:OCMOCK_ANY]);
  XCTAssertFalse(result);
  [msalMock stopMocking];
}
#endif

- (void)testConfigureMSALWithInvalidConfig {

  // If
  self.sut.authConfig = [MSAuthConfig new];

  // When
  [self.sut configAuthenticationClient];

  // Then
  XCTAssertNil(self.sut.clientApplication);
}

- (void)testLoadInvalidConfigurationFromCache {

  // If
  NSDictionary *invalidData = @{@"invalid" : @"data"};
  NSData *serializedConfig = [NSJSONSerialization dataWithJSONObject:invalidData options:(NSJSONWritingOptions)0 error:nil];
  OCMStub([self.utilityMock loadDataForPathComponent:[self.sut authConfigFilePath]]).andReturn(serializedConfig);
  [self.settingsMock setObject:@"eTag" forKey:kMSAuthETagKey];

  // When
  BOOL loaded = [self.sut loadConfigurationFromCache];

  // Then
  XCTAssertFalse(loaded);
  OCMVerify([self.utilityMock deleteItemForPathComponent:[self.sut authConfigFilePath]]);
  XCTAssertNil([self.settingsMock objectForKey:kMSAuthETagKey]);
}

- (void)testNotCacheInvalidConfig {

  // If
  __block MSSendAsyncCompletionHandler ingestionBlock;
  NSString *oldETag = @"oldETag";
  NSString *expectedETag = @"newETag";
  [self.settingsMock setObject:oldETag forKey:kMSAuthETagKey];
  NSData *invalidConfig = [NSJSONSerialization dataWithJSONObject:@{} options:(NSJSONWritingOptions)0 error:nil];
  OCMStub([self.ingestionMock sendAsync:nil eTag:oldETag completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    // Get ingestion block for later call.
    [invocation retainArguments];
    [invocation getArgument:&ingestionBlock atIndex:4];
  });
  MSAuth *service = (MSAuth *)[MSAuth sharedInstance];

  // When
  [service downloadConfigurationWithETag:oldETag];
  ingestionBlock(@"callId", [MSHttpTestUtil createMockResponseForStatusCode:200 headers:@{kMSETagResponseHeader : expectedETag}],
                 invalidConfig, nil);

  // Then
  OCMReject([self.utilityMock createFileAtPathComponent:[service authConfigFilePath]
                                               withData:OCMOCK_ANY
                                             atomically:YES
                                         forceOverwrite:YES]);
  XCTAssertEqualObjects(oldETag, [self.settingsMock objectForKey:kMSAuthETagKey]);
}

- (void)testNotCacheInvalidData {

  // If
  __block MSSendAsyncCompletionHandler ingestionBlock;
  NSString *oldETag = @"oldETag";
  NSString *expectedETag = @"newETag";
  [self.settingsMock setObject:oldETag forKey:kMSAuthETagKey];
  NSData *invalidData = [@"InvalidData" dataUsingEncoding:NSUTF8StringEncoding];
  OCMStub([self.ingestionMock sendAsync:nil eTag:oldETag completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    // Get ingestion block for later call.
    [invocation retainArguments];
    [invocation getArgument:&ingestionBlock atIndex:4];
  });

  // When
  [self.sut downloadConfigurationWithETag:oldETag];
  ingestionBlock(@"callId", [MSHttpTestUtil createMockResponseForStatusCode:200 headers:@{kMSETagResponseHeader : expectedETag}],
                 invalidData, nil);

  // Then
  OCMReject([self.utilityMock createFileAtPathComponent:[self.sut authConfigFilePath]
                                               withData:OCMOCK_ANY
                                             atomically:YES
                                         forceOverwrite:YES]);
  XCTAssertEqualObjects(oldETag, [self.settingsMock objectForKey:kMSAuthETagKey]);
}

- (void)testSignInAcquiresAndSavesToken {

  // If
  NSString *idToken = @"idToken";
  NSString *accountId = @"94c82516-cbee-44aa-8a6a-19f8d20322be";
  id msalResultMock = OCMPartialMock([MSALResult new]);
  OCMStub([msalResultMock idToken]).andReturn(idToken);
  OCMStub([msalResultMock uniqueId]).andReturn(accountId);
  self.sut.clientApplication = self.clientApplicationMock;
  self.sut.authConfig = [MSAuthConfig new];
  self.sut.authConfig.authScope = @"fake";
  id authMock = OCMPartialMock(self.sut);
  OCMStub([authMock sharedInstance]).andReturn(authMock);
  OCMStub([authMock canBeUsed]).andReturn(YES);
  OCMStub([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __block MSALCompletionBlock completionBlock;
    [invocation getArgument:&completionBlock atIndex:3];
    completionBlock(msalResultMock, nil);
  });
  [[MSAuth sharedInstance] startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                                       appSecret:kMSTestAppSecret
                         transmissionTargetToken:nil
                                 fromApplication:YES];

  // When
  MSSignInCompletionHandler handler = ^(MSUserInformation *_Nullable userInformation, NSError *_Nullable error) {
    self.signInUserInformation = userInformation;
    self.signInError = error;
  };
  [MSAuth signInWithCompletionHandler:handler];
  MSAuthTokenInfo *actualAuthTokenInfo = [[[MSAuthTokenContext sharedInstance] authTokenHistory] lastObject];

  // Then
  OCMVerify([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]);
  XCTAssertEqualObjects(idToken, [MSAuthTokenContext sharedInstance].authToken);
  XCTAssertEqualObjects(idToken, actualAuthTokenInfo.authToken);
  XCTAssertNotNil(self.signInUserInformation);
  XCTAssertEqualObjects(accountId, self.signInUserInformation.accountId);
  XCTAssertNil(self.signInError);
  [authMock stopMocking];
}

- (void)testSignInDoesNotAcquireTokenWhenDisabled {

  // If
  self.sut.clientApplication = self.clientApplicationMock;
  id authMock = OCMPartialMock([MSAuth sharedInstance]);
  OCMStub([authMock sharedInstance]).andReturn(authMock);
  OCMStub([authMock canBeUsed]).andReturn(NO);
  OCMStub([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]).andDo(nil);

  // When
  OCMReject([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]);
  MSSignInCompletionHandler handler = ^(MSUserInformation *_Nullable userInformation, NSError *_Nullable error) {
    self.signInUserInformation = userInformation;
    self.signInError = error;
  };
  [MSAuth signInWithCompletionHandler:handler];

  // Then
  XCTAssertNil(self.signInUserInformation);
  XCTAssertNotNil(self.signInError);
  XCTAssertEqualObjects(kMSACAuthErrorDomain, self.signInError.domain);
  XCTAssertEqual(MSACAuthErrorServiceDisabled, self.signInError.code);
  XCTAssertNotNil(self.signInError.userInfo[NSLocalizedDescriptionKey]);
  [authMock stopMocking];
}

- (void)testSignInFailsWhenNoInternet {

  // If
  self.sut.clientApplication = self.clientApplicationMock;
  id reachability = OCMPartialMock([MS_Reachability reachabilityForInternetConnection]);
  OCMStub([reachability currentReachabilityStatus]).andReturn(NotReachable);
  id reachabilityMock = OCMClassMock([MS_Reachability class]);
  OCMStub(ClassMethod([reachabilityMock reachabilityForInternetConnection])).andReturn(reachability);
  OCMStub([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]).andDo(nil);
  id authMock = OCMPartialMock(self.sut);
  OCMStub([authMock sharedInstance]).andReturn(authMock);
  OCMStub([authMock canBeUsed]).andReturn(YES);

  // When
  MSSignInCompletionHandler handler = ^(MSUserInformation *_Nullable userInformation, NSError *_Nullable error) {
    self.signInUserInformation = userInformation;
    self.signInError = error;
  };
  [MSAuth signInWithCompletionHandler:handler];

  // Then
  XCTAssertNil(self.signInUserInformation);
  XCTAssertNotNil(self.signInError);
  XCTAssertEqualObjects(kMSACAuthErrorDomain, self.signInError.domain);
  XCTAssertEqual(MSACAuthErrorSignInWhenNoConnection, self.signInError.code);
  XCTAssertNotNil(self.signInError.userInfo[NSLocalizedDescriptionKey]);
  [authMock stopMocking];
}

- (void)testSignInDelayedWhenNoClientApplication {

  // If
  self.sut.authConfig = [MSAuthConfig new];
  self.sut.authConfig.authScope = @"fake";
  id authMock = OCMPartialMock(self.sut);
  OCMStub([authMock sharedInstance]).andReturn(authMock);
  OCMStub([authMock canBeUsed]).andReturn(YES);

  // When
  MSSignInCompletionHandler handler = ^(MSUserInformation *_Nullable userInformation, NSError *_Nullable error) {
    self.signInUserInformation = userInformation;
    self.signInError = error;
  };
  [MSAuth signInWithCompletionHandler:handler];

  // Then
  XCTAssertNil(self.signInUserInformation);
  XCTAssertNotNil(self.signInError);
  XCTAssertEqualObjects(kMSACAuthErrorDomain, self.signInError.domain);
  XCTAssertEqual(MSACAuthErrorSignInBackgroundOrNotConfigured, self.signInError.code);
  XCTAssertNotNil(self.signInError.userInfo[NSLocalizedDescriptionKey]);
  [authMock stopMocking];
}

- (void)testSignInFailsWhenNoAuthConfig {

  // If
  self.sut.clientApplication = self.clientApplicationMock;
  id authMock = OCMPartialMock(self.sut);
  OCMStub([authMock sharedInstance]).andReturn(authMock);
  OCMStub([authMock canBeUsed]).andReturn(YES);

  // When
  MSSignInCompletionHandler handler = ^(MSUserInformation *_Nullable userInformation, NSError *_Nullable error) {
    self.signInUserInformation = userInformation;
    self.signInError = error;
  };
  [MSAuth signInWithCompletionHandler:handler];

  // Then
  XCTAssertNil(self.signInUserInformation);
  XCTAssertNotNil(self.signInError);
  XCTAssertEqualObjects(kMSACAuthErrorDomain, self.signInError.domain);
  XCTAssertEqual(MSACAuthErrorSignInBackgroundOrNotConfigured, self.signInError.code);
  XCTAssertNotNil(self.signInError.userInfo[NSLocalizedDescriptionKey]);
  [authMock stopMocking];
}

- (void)testSecondSignInSuccessAfterFirstSignInFails {

  // If
  NSString *idToken = @"idToken";
  NSString *accountId = @"94c82516-cbee-44aa-8a6a-19f8d20322be";
  id msalResultMock = OCMPartialMock([MSALResult new]);
  OCMStub([msalResultMock idToken]).andReturn(idToken);
  OCMStub([msalResultMock uniqueId]).andReturn(accountId);
  self.sut.clientApplication = self.clientApplicationMock;
  id authMock = OCMPartialMock(self.sut);
  OCMStub([authMock sharedInstance]).andReturn(authMock);
  OCMStub([authMock canBeUsed]).andReturn(YES);

  // When

  // We expect the call would fail and the handler will be called with an error because authConfig isn't mocked and configured.
  MSSignInCompletionHandler handler1 = ^(MSUserInformation *_Nullable userInformation, NSError *_Nullable error) {
    self.signInUserInformation = userInformation;
    self.signInError = error;
  };
  [MSAuth signInWithCompletionHandler:handler1];

  // Then
  XCTAssertNil(self.signInUserInformation);
  XCTAssertNotNil(self.signInError);
  XCTAssertEqualObjects(kMSACAuthErrorDomain, self.signInError.domain);
  XCTAssertEqual(MSACAuthErrorSignInBackgroundOrNotConfigured, self.signInError.code);
  XCTAssertNotNil(self.signInError.userInfo[NSLocalizedDescriptionKey]);

  // If
  id configMock = OCMPartialMock([MSAuthConfig new]);
  OCMStub([configMock authScope]).andReturn(@"fake");
  OCMStub([authMock authConfig]).andReturn(configMock);
  OCMStub([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __block MSALCompletionBlock completionBlock;
    [invocation getArgument:&completionBlock atIndex:3];
    self.msalCompletionBlock = completionBlock;
  });

  // When
  MSSignInCompletionHandler handler2 = ^(MSUserInformation *_Nullable userInformation, NSError *_Nullable error) {
    self.signInUserInformation = userInformation;
    self.signInError = error;
  };
  [MSAuth signInWithCompletionHandler:handler2];

  // When we complete second call
  self.msalCompletionBlock(msalResultMock, nil);
  MSAuthTokenInfo *actualAuthTokenInfo = [[[MSAuthTokenContext sharedInstance] authTokenHistory] lastObject];

  // Then
  OCMVerify([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]);
  XCTAssertEqualObjects(idToken, [MSAuthTokenContext sharedInstance].authToken);
  XCTAssertEqualObjects(idToken, actualAuthTokenInfo.authToken);
  XCTAssertNotNil(self.signInUserInformation);
  XCTAssertEqualObjects(accountId, self.signInUserInformation.accountId);
  XCTAssertNil(self.signInError);
  [authMock stopMocking];
}

- (void)testSilentSignInSavesAuthTokenAndHomeAccountId {

  // If
  [[MSAuth sharedInstance] startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                                       appSecret:kMSTestAppSecret
                         transmissionTargetToken:nil
                                 fromApplication:YES];
  NSString *expectedHomeAccountId = @"fakeHomeAccountId";
  NSString *expectedAuthToken = @"fakeAuthToken";
  MSALAccountId *mockAccountId = OCMPartialMock([MSALAccountId new]);
  OCMStub(mockAccountId.identifier).andReturn(expectedHomeAccountId);
  id accountMock = OCMPartialMock([MSALAccount new]);
  OCMStub([accountMock homeAccountId]).andReturn(mockAccountId);
  id msalResultMock = OCMPartialMock([MSALResult new]);
  OCMStub([msalResultMock account]).andReturn(accountMock);
  OCMStub([msalResultMock idToken]).andReturn(expectedAuthToken);
  OCMStub([self.clientApplicationMock acquireTokenSilentForScopes:OCMOCK_ANY account:accountMock completionBlock:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __block MSALCompletionBlock completionBlock;
        [invocation getArgument:&completionBlock atIndex:4];
        completionBlock(msalResultMock, nil);
      });
  self.sut.clientApplication = self.clientApplicationMock;
  self.sut.authConfig = [MSAuthConfig new];
  self.sut.authConfig.authScope = @"fake";
  id authMock = OCMPartialMock(self.sut);
  OCMStub([authMock sharedInstance]).andReturn(authMock);
  OCMStub([authMock canBeUsed]).andReturn(YES);

  // When
  self.sut.signInCompletionHandler = ^(MSUserInformation *_Nullable __unused userInformation, NSError *_Nullable __unused error) {
  };
  [self.sut acquireTokenSilentlyWithMSALAccount:accountMock
                                     uiFallback:NO
                    keyPathForCompletionHandler:NSStringFromSelector(@selector(signInCompletionHandler))];
  MSAuthTokenInfo *actualAuthTokenInfo = [[[MSAuthTokenContext sharedInstance] authTokenHistory] lastObject];

  // Then
  XCTAssertEqualObjects(actualAuthTokenInfo.authToken, expectedAuthToken);
  XCTAssertEqualObjects([MSAuthTokenContext sharedInstance].authToken, expectedAuthToken);
  XCTAssertEqualObjects([MSAuthTokenContext sharedInstance].accountId, expectedHomeAccountId);

  [accountMock stopMocking];
  [authMock stopMocking];
  [msalResultMock stopMocking];
}

- (void)testSilentSignInFailureTriggersInteractiveSignIn {

  // If
  self.sut.clientApplication = self.clientApplicationMock;
  self.sut.authConfig = [MSAuthConfig new];
  self.sut.authConfig.authScope = @"fake";
  MSALAccountId *mockAccountId = OCMPartialMock([MSALAccountId new]);
  OCMStub(mockAccountId.identifier).andReturn(@"Something");
  id accountMock = OCMPartialMock([MSALAccount new]);
  OCMStub([accountMock homeAccountId]).andReturn(mockAccountId);
  id authMock = OCMPartialMock(self.sut);
  OCMStub([authMock sharedInstance]).andReturn(authMock);
  OCMStub([authMock canBeUsed]).andReturn(YES);
  OCMStub([self.clientApplicationMock acquireTokenSilentForScopes:OCMOCK_ANY account:OCMOCK_ANY completionBlock:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __block MSALCompletionBlock completionBlock;
        [invocation getArgument:&completionBlock atIndex:4];
        NSError *error = [[NSError alloc] initWithDomain:MSALErrorDomain
                                                    code:MSALErrorInteractionRequired
                                                userInfo:@{NSLocalizedDescriptionKey : @"Error"}];
        completionBlock(nil, error);
      });

  // When
  self.sut.signInCompletionHandler = ^(MSUserInformation *_Nullable __unused userInformation, NSError *_Nullable __unused error) {
  };
  [self.sut acquireTokenSilentlyWithMSALAccount:accountMock
                                     uiFallback:YES
                    keyPathForCompletionHandler:NSStringFromSelector(@selector(signInCompletionHandler))];

  // Then
  OCMVerify([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]);
  [authMock stopMocking];
}

- (void)testSignInTriggersInteractiveAuthentication {

  // If
  self.sut.clientApplication = self.clientApplicationMock;
  self.sut.authConfig = [MSAuthConfig new];
  self.sut.authConfig.authScope = @"fake";
  id authMock = OCMPartialMock(self.sut);
  OCMStub([authMock sharedInstance]).andReturn(authMock);
  OCMStub([authMock canBeUsed]).andReturn(YES);

  // Then
  OCMReject([self.clientApplicationMock acquireTokenSilentForScopes:OCMOCK_ANY account:OCMOCK_ANY completionBlock:OCMOCK_ANY]);

  // When
  [MSAuth signInWithCompletionHandler:nil];

  // Then
  OCMVerify([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]);
  [authMock stopMocking];
}

- (void)testSignInTriggersSilentAuthentication {

  // If
  MSALAccountId *mockAccountId = OCMPartialMock([MSALAccountId new]);
  NSString *fakeAccountId = @"fakeHomeAccountId";
  OCMStub(mockAccountId.identifier).andReturn(fakeAccountId);
  id accountMock = OCMPartialMock([MSALAccount new]);
  OCMStub([accountMock homeAccountId]).andReturn(fakeAccountId);
  [[MSAuth sharedInstance] startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                                       appSecret:kMSTestAppSecret
                         transmissionTargetToken:nil
                                 fromApplication:YES];
  [[MSAuthTokenContext sharedInstance] setAuthToken:@"token" withAccountId:fakeAccountId expiresOn:nil];
  /*
   * `accountForHomeAccountId:error:` takes a double pointer (NSError * _Nullable __autoreleasing * _Nullable) so we need to pass in
   * `[OCMArg anyObjectRef]`. Passing in `OCMOCK_ANY` or `nil` will cause the OCMStub to not work.
   */
  OCMStub([self.clientApplicationMock accountForHomeAccountId:fakeAccountId error:[OCMArg anyObjectRef]]).andReturn(accountMock);
  self.sut.clientApplication = self.clientApplicationMock;
  self.sut.authConfig = [MSAuthConfig new];
  self.sut.authConfig.authScope = @"fake";
  id authMock = OCMPartialMock(self.sut);
  OCMStub([authMock sharedInstance]).andReturn(authMock);
  OCMStub([authMock canBeUsed]).andReturn(YES);

  // Then
  OCMReject([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]);

  // When
  [MSAuth signInWithCompletionHandler:nil];

  // Then
  OCMVerify([self.clientApplicationMock acquireTokenSilentForScopes:OCMOCK_ANY account:OCMOCK_ANY completionBlock:OCMOCK_ANY]);
  [authMock stopMocking];
}

- (void)testSignInAlreadyInProgress {

  // If
  NSString *idToken = @"idToken";
  NSString *accountId = @"94c82516-cbee-44aa-8a6a-19f8d20322be";
  id msalResultMock = OCMPartialMock([MSALResult new]);
  OCMStub([msalResultMock idToken]).andReturn(idToken);
  OCMStub([msalResultMock uniqueId]).andReturn(accountId);
  self.sut.clientApplication = self.clientApplicationMock;
  self.sut.authConfig = [MSAuthConfig new];
  self.sut.authConfig.authScope = @"fake";
  id authMock = OCMPartialMock(self.sut);
  OCMStub([authMock sharedInstance]).andReturn(authMock);
  OCMStub([authMock canBeUsed]).andReturn(YES);
  OCMStub([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __block MSALCompletionBlock completionBlock;
    [invocation getArgument:&completionBlock atIndex:3];
    self.msalCompletionBlock = completionBlock;
  });
  [[MSAuth sharedInstance] startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                                       appSecret:kMSTestAppSecret
                         transmissionTargetToken:nil
                                 fromApplication:YES];

  // When we make a first call
  MSSignInCompletionHandler handler1 = ^(MSUserInformation *_Nullable userInformation, NSError *_Nullable error) {
    self.signInUserInformation = userInformation;
    self.signInError = error;
  };
  [MSAuth signInWithCompletionHandler:handler1];

  // And we make a second call before the first complete
  MSSignInCompletionHandler handler2 = ^(MSUserInformation *_Nullable userInformation, NSError *_Nullable error) {
    self.signInUserInformation = userInformation;
    self.signInError = error;
  };
  [MSAuth signInWithCompletionHandler:handler2];

  // Then second call immediately fails
  XCTAssertNil(self.signInUserInformation);
  XCTAssertNotNil(self.signInError);
  XCTAssertEqualObjects(kMSACAuthErrorDomain, self.signInError.domain);
  XCTAssertEqual(MSACAuthErrorPreviousSignInRequestInProgress, self.signInError.code);
  XCTAssertNotNil(self.signInError.userInfo[NSLocalizedDescriptionKey]);

  // When we complete first call
  self.msalCompletionBlock(msalResultMock, nil);
  MSAuthTokenInfo *actualAuthTokenInfo = [[[MSAuthTokenContext sharedInstance] authTokenHistory] lastObject];

  // Then
  OCMVerify([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]);
  XCTAssertEqualObjects(idToken, [MSAuthTokenContext sharedInstance].authToken);
  XCTAssertEqualObjects(idToken, actualAuthTokenInfo.authToken);
  XCTAssertNotNil(self.signInUserInformation);
  XCTAssertEqualObjects(accountId, self.signInUserInformation.accountId);
  XCTAssertNil(self.signInError);
  [authMock stopMocking];
}

- (void)testSignInError {

  // If
  id authTokenContextMock = OCMPartialMock([MSAuthTokenContext sharedInstance]);
  OCMStub([authTokenContextMock sharedInstance]).andReturn(authTokenContextMock);
  NSError *signInError = [[NSError alloc] initWithDomain:MSALErrorDomain
                                                    code:MSALInternalErrorAuthorizationFailed
                                                userInfo:@{MSALErrorDescriptionKey : @"failed"}];
  self.sut.clientApplication = self.clientApplicationMock;
  self.sut.authConfig = [MSAuthConfig new];
  self.sut.authConfig.authScope = @"fake";
  id authMock = OCMPartialMock(self.sut);
  OCMStub([authMock sharedInstance]).andReturn(authMock);
  OCMStub([authMock canBeUsed]).andReturn(YES);
  OCMStub([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __block MSALCompletionBlock completionBlock;
    [invocation getArgument:&completionBlock atIndex:3];
    completionBlock(nil, signInError);
  });

  // When
  MSSignInCompletionHandler handler = ^(MSUserInformation *_Nullable userInformation, NSError *_Nullable error) {
    self.signInUserInformation = userInformation;
    self.signInError = error;
  };
  [MSAuth signInWithCompletionHandler:handler];

  // Then
  OCMVerify([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]);
  OCMVerify([authTokenContextMock setAuthToken:nil withAccountId:nil expiresOn:nil]);
  XCTAssertNil(self.signInUserInformation);
  XCTAssertNotNil(self.signInError);
  XCTAssertEqualObjects(MSALErrorDomain, self.signInError.domain);
  XCTAssertEqual(MSALInternalErrorAuthorizationFailed, self.signInError.code);
  XCTAssertNotNil(self.signInError.userInfo[MSALErrorDescriptionKey]);
  [authMock stopMocking];
  [authTokenContextMock stopMocking];
}

- (void)testSignInCancelled {

  // If
  id authTokenContextMock = OCMPartialMock([MSAuthTokenContext sharedInstance]);
  OCMStub([authTokenContextMock sharedInstance]).andReturn(authTokenContextMock);
  NSError *signInError = [[NSError alloc] initWithDomain:MSALErrorDomain
                                                    code:MSALErrorUserCanceled
                                                userInfo:@{MSALErrorDescriptionKey : @"cancelled"}];
  self.sut.clientApplication = self.clientApplicationMock;
  self.sut.authConfig = [MSAuthConfig new];
  self.sut.authConfig.authScope = @"fake";
  id authMock = OCMPartialMock(self.sut);
  OCMStub([authMock sharedInstance]).andReturn(authMock);
  OCMStub([authMock canBeUsed]).andReturn(YES);
  OCMStub([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __block MSALCompletionBlock completionBlock;
    [invocation getArgument:&completionBlock atIndex:3];
    completionBlock(nil, signInError);
  });

  // When
  MSSignInCompletionHandler handler = ^(MSUserInformation *_Nullable userInformation, NSError *_Nullable error) {
    self.signInUserInformation = userInformation;
    self.signInError = error;
  };
  [MSAuth signInWithCompletionHandler:handler];

  // Then
  OCMVerify([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]);
  OCMVerify([authTokenContextMock setAuthToken:nil withAccountId:nil expiresOn:nil]);
  XCTAssertNil(self.signInUserInformation);
  XCTAssertNotNil(self.signInError);
  XCTAssertEqualObjects(MSALErrorDomain, self.signInError.domain);
  XCTAssertEqual(MSALErrorUserCanceled, self.signInError.code);
  XCTAssertNotNil(self.signInError.userInfo[MSALErrorDescriptionKey]);
  [authMock stopMocking];
  [authTokenContextMock stopMocking];
}

- (void)testSignInFailsAfterDisablingEvenIfBrowserWasOpenedAndSignInSucceeds {

  // If
  NSString *idToken = @"idToken";
  NSString *accountId = @"94c82516-cbee-44aa-8a6a-19f8d20322be";
  id msalResultMock = OCMPartialMock([MSALResult new]);
  OCMStub([msalResultMock idToken]).andReturn(idToken);
  OCMStub([msalResultMock uniqueId]).andReturn(accountId);
  self.sut.clientApplication = self.clientApplicationMock;
  self.sut.authConfig = [MSAuthConfig new];
  self.sut.authConfig.authScope = @"fake";
  id authMock = OCMPartialMock(self.sut);
  OCMStub([authMock sharedInstance]).andReturn(authMock);
  OCMStub([authMock canBeUsed]).andReturn(YES);
  OCMStub([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __block MSALCompletionBlock completionBlock;
    [invocation getArgument:&completionBlock atIndex:3];
    self.msalCompletionBlock = completionBlock;
  });

  // When
  MSSignInCompletionHandler handler = ^(MSUserInformation *_Nullable userInformation, NSError *_Nullable error) {
    self.signInUserInformation = userInformation;
    self.signInError = error;
  };
  [MSAuth signInWithCompletionHandler:handler];
  [self.sut setEnabled:NO];
  self.msalCompletionBlock(msalResultMock, nil);

  // Then
  OCMVerify([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]);
  XCTAssertNil(self.signInUserInformation);
  XCTAssertNotNil(self.signInError);
  XCTAssertEqualObjects(kMSACAuthErrorDomain, self.signInError.domain);
  XCTAssertEqual(MSACAuthErrorServiceDisabled, self.signInError.code);
  XCTAssertNotNil(self.signInError.userInfo[NSLocalizedDescriptionKey]);
  [authMock stopMocking];
}

- (void)testSignOutInvokesDelegatesWithNilToken {

  // If
  [[MSAuthTokenContext sharedInstance] setAuthToken:@"someToken" withAccountId:@"someAccount" expiresOn:nil];
  id<MSAuthTokenContextDelegate> mockDelegate = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [[MSAuthTokenContext sharedInstance] addDelegate:mockDelegate];
  id authMock = OCMPartialMock(self.sut);
  OCMStub([authMock sharedInstance]).andReturn(authMock);
  OCMStub([authMock canBeUsed]).andReturn(YES);

  // When
  [MSAuth signOut];

  // Then
  OCMVerify([mockDelegate authTokenContext:OCMOCK_ANY didUpdateAuthToken:nil]);
  OCMVerify([mockDelegate authTokenContext:OCMOCK_ANY didUpdateUserInformation:nil]);
  [authMock stopMocking];
}

- (void)testSignOutRemovesAccountFromMSAL {

  // If
  NSString *accountId = @"someAccount";
  [[MSAuthTokenContext sharedInstance] setAuthToken:@"someToken" withAccountId:accountId expiresOn:nil];
  id accountMock = OCMPartialMock([MSALAccount new]);
  self.sut.clientApplication = self.clientApplicationMock;
  OCMStub([self.clientApplicationMock accountForHomeAccountId:accountId error:[OCMArg anyObjectRef]]).andReturn(accountMock);
  id authMock = OCMPartialMock(self.sut);
  OCMStub([authMock sharedInstance]).andReturn(authMock);
  OCMStub([authMock canBeUsed]).andReturn(YES);

  // When
  [MSAuth signOut];

  // Then
  OCMVerify([authMock removeAccount]);
  OCMVerify([self.clientApplicationMock removeAccount:OCMOCK_ANY error:[OCMArg anyObjectRef]]);
  [authMock stopMocking];
}

- (void)testSignOutShouldNotRemoveAccountFromMSALIfNotConfigured {

  // If
  NSString *accountId = @"someAccount";
  [[MSAuthTokenContext sharedInstance] setAuthToken:@"someToken" withAccountId:accountId expiresOn:nil];
  id authMock = OCMPartialMock(self.sut);
  OCMStub([authMock sharedInstance]).andReturn(authMock);
  OCMStub([authMock canBeUsed]).andReturn(YES);

  // Then
  OCMReject([self.clientApplicationMock removeAccount:OCMOCK_ANY error:[OCMArg anyObjectRef]]);

  // When
  [MSAuth signOut];
  XCTAssertFalse([self.sut removeAccount]);

  // Then
  XCTAssertNil(self.sut.clientApplication);
  [authMock stopMocking];
}

- (void)testSignOutShouldNotRemoveAccountFromMSALIfNoAccount {

  // If
  NSString *accountId = @"someAccount";
  [[MSAuthTokenContext sharedInstance] setAuthToken:@"someToken" withAccountId:accountId expiresOn:nil];
  self.sut.clientApplication = self.clientApplicationMock;
  id authMock = OCMPartialMock(self.sut);
  OCMStub([authMock sharedInstance]).andReturn(authMock);
  OCMStub([authMock canBeUsed]).andReturn(YES);

  // Then
  OCMReject([self.clientApplicationMock removeAccount:OCMOCK_ANY error:[OCMArg anyObjectRef]]);

  // When
  [MSAuth signOut];
  XCTAssertTrue([self.sut removeAccount]);

  // Then
  OCMVerifyAll(self.clientApplicationMock);
  [authMock stopMocking];
}

- (void)testSignOutClearsAuthTokenAndAccountId {

  // If
  [[MSAuth sharedInstance] startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                                       appSecret:kMSTestAppSecret
                         transmissionTargetToken:nil
                                 fromApplication:YES];
  [[MSAuthTokenContext sharedInstance] setAuthToken:@"someToken" withAccountId:@"someAccount" expiresOn:nil];
  MSAuthTokenInfo *authTokenInfo = [[MSAuthTokenInfo alloc] initWithAuthToken:@"someToken"
                                                                    accountId:@"someAccountId"
                                                                    startTime:nil
                                                                    expiresOn:nil];
  NSMutableArray<MSAuthTokenInfo *> *authTokenHistory = [NSMutableArray<MSAuthTokenInfo *> new];
  [authTokenHistory addObject:authTokenInfo];
  [[MSAuthTokenContext sharedInstance] setAuthTokenHistory:authTokenHistory];
  id authMock = OCMPartialMock(self.sut);
  OCMStub([authMock sharedInstance]).andReturn(authMock);
  OCMStub([authMock canBeUsed]).andReturn(YES);

  // When
  [MSAuth signOut];
  MSAuthTokenInfo *actualAuthTokenInfo = [[[MSAuthTokenContext sharedInstance] authTokenHistory] lastObject];

  // Then
  XCTAssertNil(actualAuthTokenInfo.authToken);
  XCTAssertNil(actualAuthTokenInfo.accountId);
  [authMock stopMocking];
}

- (void)testSignOutWhenAlreadySignedOut {

  // If
  self.sut.clientApplication = self.clientApplicationMock;
  id authMock = OCMPartialMock(self.sut);
  OCMStub([authMock sharedInstance]).andReturn(authMock);
  OCMStub([authMock canBeUsed]).andReturn(YES);
  id authTokenContextMock = OCMPartialMock([MSAuthTokenContext sharedInstance]);
  OCMStub([authTokenContextMock sharedInstance]).andReturn(authTokenContextMock);

  // Then
  OCMReject([self.clientApplicationMock removeAccount:OCMOCK_ANY error:[OCMArg anyObjectRef]]);

  // When
  [MSAuth signOut];

  // Then
  XCTAssertNil([[MSAuthTokenContext sharedInstance] authToken]);
  XCTAssertNil([[MSAuthTokenContext sharedInstance] accountId]);
  [authMock stopMocking];
  [authTokenContextMock stopMocking];
}

- (void)testSignOutDoesNothingWhenDisabled {

  // If
  NSString *authToken = @"someToken";
  NSString *accountId = @"someAccount";
  [[MSAuthTokenContext sharedInstance] setAuthToken:authToken withAccountId:accountId expiresOn:nil];
  MSAuthTokenInfo *authTokenInfo = [[MSAuthTokenInfo alloc] initWithAuthToken:authToken accountId:accountId startTime:nil expiresOn:nil];
  NSMutableArray<MSAuthTokenInfo *> *authTokenHistory = [NSMutableArray<MSAuthTokenInfo *> new];
  [authTokenHistory addObject:authTokenInfo];
  [[MSAuthTokenContext sharedInstance] setAuthTokenHistory:authTokenHistory];
  id authMock = OCMPartialMock(self.sut);
  OCMStub([authMock sharedInstance]).andReturn(authMock);
  OCMStub([authMock canBeUsed]).andReturn(NO);

  // When
  [MSAuth signOut];
  MSAuthTokenInfo *actualAuthTokenInfo = [[[MSAuthTokenContext sharedInstance] authTokenHistory] lastObject];

  // Then
  XCTAssertEqualObjects([[MSAuthTokenContext sharedInstance] authToken], authToken);
  XCTAssertEqualObjects(actualAuthTokenInfo.authToken, authToken);
  XCTAssertEqualObjects(actualAuthTokenInfo.accountId, accountId);
  [authMock stopMocking];
}

- (void)testDefaultConfigUrl {

  // When
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                        appSecret:kMSTestAppSecret
          transmissionTargetToken:nil
                  fromApplication:YES];

  // Then
  XCTAssertNotNil(self.sut.ingestion);
  XCTAssertEqualObjects(self.sut.ingestion.baseURL, kMSAuthDefaultBaseURL);
}

- (void)testConfigURLIsPassedToIngestionWhenSetBeforeServiceStart {

  // If
  NSString *baseConfigUrl = @"https://baseconfigurl.com";

  // When
  [MSAuth setConfigUrl:baseConfigUrl];
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                        appSecret:kMSTestAppSecret
          transmissionTargetToken:nil
                  fromApplication:YES];

  // Then
  XCTAssertNotNil(self.sut.ingestion);
  XCTAssertEqualObjects(self.sut.ingestion.baseURL, baseConfigUrl);
}

- (void)testRefreshNeededTriggersRefresh {

  // If
  NSString *fakeAccountId = @"accountId";
  NSString *fakeAuthToken = @"authToken";
  id authMock = OCMPartialMock(self.sut);
  [[MSAuthTokenContext sharedInstance] setAuthToken:fakeAuthToken withAccountId:fakeAccountId expiresOn:nil];
  MSAuthTokenValidityInfo *fakeValidityInfo = OCMClassMock([MSAuthTokenValidityInfo class]);
  OCMStub([fakeValidityInfo expiresSoon]).andReturn(YES);
  OCMStub([fakeValidityInfo authToken]).andReturn(fakeAuthToken);
  OCMStub([authMock sharedInstance]).andReturn(authMock);
  OCMStub([authMock canBeUsed]).andReturn(YES);
  self.sut.authConfig = [MSAuthConfig new];
  self.sut.authConfig.authScope = @"fake";
  OCMStub([authMock configAuthenticationClient]).andDo(^(NSInvocation *__unused invocation) {
    self.sut.clientApplication = self.clientApplicationMock;
  });
  MSALAccount *accountMock = OCMClassMock([MSALAccount class]);
  OCMStub([authMock retrieveAccountWithAccountId:fakeAccountId]).andReturn(accountMock);

  // When
  [authMock startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                        appSecret:kMSTestAppSecret
          transmissionTargetToken:nil
                  fromApplication:YES];
  [[MSAuthTokenContext sharedInstance] checkIfTokenNeedsToBeRefreshed:fakeValidityInfo];

  // Then
  OCMVerify([self.sut.clientApplication acquireTokenSilentForScopes:OCMOCK_ANY account:OCMOCK_ANY completionBlock:OCMOCK_ANY]);
  [authMock stopMocking];
}

- (void)testRefreshNeededWithNilAccountTriggersAnonymous {

  // If
  NSString *fakeAccountId = @"accountId";
  NSString *fakeAuthToken = @"authToken";
  id authMock = OCMPartialMock(self.sut);
  [[MSAuthTokenContext sharedInstance] addDelegate:authMock];
  [[MSAuthTokenContext sharedInstance] setAuthToken:fakeAuthToken withAccountId:fakeAccountId expiresOn:nil];
  MSAuthTokenValidityInfo *fakeValidityInfo = OCMClassMock([MSAuthTokenValidityInfo class]);
  OCMStub([fakeValidityInfo expiresSoon]).andReturn(YES);
  OCMStub([fakeValidityInfo authToken]).andReturn(fakeAuthToken);
  OCMStub([authMock sharedInstance]).andReturn(authMock);
  OCMStub([authMock canBeUsed]).andReturn(YES);
  OCMStub([authMock retrieveAccountWithAccountId:fakeAccountId]).andReturn(nil);
  self.sut.authConfig = [MSAuthConfig new];
  self.sut.authConfig.authScope = @"fake";
  OCMStub([authMock configAuthenticationClient]).andDo(^(NSInvocation *__unused invocation) {
    self.sut.clientApplication = self.clientApplicationMock;
  });
  OCMReject([self.sut.clientApplication acquireTokenSilentForScopes:OCMOCK_ANY account:OCMOCK_ANY completionBlock:OCMOCK_ANY]);
  id authTokenContextMock = OCMPartialMock([MSAuthTokenContext sharedInstance]);
  OCMStub([authTokenContextMock sharedInstance]).andReturn(authTokenContextMock);

  // When
  [[MSAuthTokenContext sharedInstance] checkIfTokenNeedsToBeRefreshed:fakeValidityInfo];

  // Then
  OCMVerify([authTokenContextMock setAuthToken:nil withAccountId:nil expiresOn:nil]);
  [authMock stopMocking];
  [authTokenContextMock stopMocking];
}

@end
