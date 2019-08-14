// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSALAccount.h"
#import "MSALAccountId.h"
#import "MSALAuthority.h"
#import "MSALError.h"
#import "MSALLoggerConfig.h"
#import "MSALPublicClientApplication.h"
#import "MSALResult.h"
#import "MSALTenantProfile.h"
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
#import "MSConstants+Internal.h"
#import "MSConstants.h"
#import "MSHttpTestUtil.h"
#import "MSMockUserDefaults.h"
#import "MSServiceAbstractInternal.h"
#import "MSTestFrameworks.h"
#import "MSUserInformation.h"
#import "MSUtility+File.h"

static NSString *const kMSTestAppSecret = @"TestAppSecret";

@interface MSAuthTests : XCTestCase

@property(nonatomic) MSAuth *sut;
@property(nonatomic) MSMockUserDefaults *settingsMock;
@property(nonatomic) NSDictionary *dummyConfigDic;
@property(nonatomic) id bundleMock;
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
  self.bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([self.bundleMock mainBundle]).andReturn(self.bundleMock);
  OCMStub([self.bundleMock bundleIdentifier]).andReturn(@"com.test.app");
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
  self.ingestionMock = OCMClassMock([MSAuthConfigIngestion class]);
  OCMStub([self.ingestionMock alloc]).andReturn(self.ingestionMock);
  OCMStub([self.ingestionMock initWithBaseUrl:OCMOCK_ANY appSecret:OCMOCK_ANY]).andReturn(self.ingestionMock);
  self.clientApplicationMock = OCMClassMock([MSALPublicClientApplication class]);
}

- (void)tearDown {
  [super tearDown];
  [MSAuth resetSharedInstance];
  [MSAuthTokenContext resetSharedInstance];
  [self.settingsMock stopMocking];
  [self.bundleMock stopMocking];
  [self.utilityMock stopMocking];
  [self.ingestionMock stopMocking];
  [self.clientApplicationMock stopMocking];
}

- (void)testMSALLoggingEnabledByDefault {

  // If
  [MSAuth resetSharedInstance];

  // When
  [MSAuth sharedInstance];

  // Then
  XCTAssertEqual(MSALGlobalConfig.loggerConfig.logLevel, MSALLogLevelVerbose);
  XCTAssertNotNil(MSALGlobalConfig.loggerConfig.callback);
}

- (void)testApplyEnabledStateWorks {

  // If
  [self mockURLScheme:nil];
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
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
  [self mockURLScheme:nil];
  NSString *previousAuthToken = @"any-token";
  [[MSAuthTokenContext sharedInstance] setAuthToken:@"any-token" withAccountId:nil expiresOn:nil];
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
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
  [self mockURLScheme:nil];
  NSString *previousAuthToken = @"any-token";
  [[MSAuthTokenContext sharedInstance] setAuthToken:@"any-token" withAccountId:nil expiresOn:nil];
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
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
  [self mockURLScheme:nil];
  NSString *fakeAccountId = @"some-account-id";
  NSString *fakeToken = @"some-token";
  NSData *serializedConfig = [NSJSONSerialization dataWithJSONObject:self.dummyConfigDic options:(NSJSONWritingOptions)0 error:nil];
  OCMStub([self.utilityMock loadDataForPathComponent:[self.sut authConfigFilePath]]).andReturn(serializedConfig);
  [self.settingsMock setObject:@"eTag" forKey:kMSAuthETagKey];
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
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
  id accountMock = OCMClassMock(MSALAccount.class);
  self.sut.clientApplication = self.clientApplicationMock;
  OCMStub([self.clientApplicationMock accountForIdentifier:OCMOCK_ANY error:[OCMArg anyObjectRef]]).andReturn(accountMock);

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
  OCMReject([[self.utilityMock ignoringNonObjectArgs] createFileAtPathComponent:[self.sut authConfigFilePath]
                                                                       withData:OCMOCK_ANY
                                                                     atomically:NO
                                                                 forceOverwrite:NO]);
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
  OCMReject([[self.utilityMock ignoringNonObjectArgs] createFileAtPathComponent:[self.sut authConfigFilePath]
                                                                       withData:OCMOCK_ANY
                                                                     atomically:NO
                                                                 forceOverwrite:NO]);
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

  // When
  [self.sut downloadConfigurationWithETag:oldETag];
  ingestionBlock(@"callId", [MSHttpTestUtil createMockResponseForStatusCode:200 headers:@{kMSETagResponseHeader : expectedETag}],
                 invalidConfig, nil);

  // Then
  OCMReject([self.utilityMock createFileAtPathComponent:[self.sut authConfigFilePath]
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
  NSString *accessToken = @"accessToken";
  NSString *accountId = @"94c82516-cbee-44aa-8a6a-19f8d20322be";
  id tenantProfile = OCMClassMock(MSALTenantProfile.class);
  OCMStub([tenantProfile identifier]).andReturn(accountId);
  id msalResultMock = OCMPartialMock([MSALResult new]);
  OCMStub([msalResultMock idToken]).andReturn(idToken);
  OCMStub([msalResultMock accessToken]).andReturn(accessToken);
  OCMStub([msalResultMock tenantProfile]).andReturn(tenantProfile);
  NSData *serializedConfig = [NSJSONSerialization dataWithJSONObject:self.dummyConfigDic options:(NSJSONWritingOptions)0 error:nil];
  OCMStub([self.utilityMock loadDataForPathComponent:[self.sut authConfigFilePath]]).andReturn(serializedConfig);
  OCMStub([self.clientApplicationMock alloc]).andReturn(self.clientApplicationMock);
  OCMStub([self.clientApplicationMock initWithConfiguration:OCMOCK_ANY error:[OCMArg anyObjectRef]]).andReturn(self.clientApplicationMock);
  OCMStub([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __block MSALCompletionBlock completionBlock;
    [invocation getArgument:&completionBlock atIndex:3];
    completionBlock(msalResultMock, nil);
  });
  [self.sut applyEnabledState:YES];
  MSSignInCompletionHandler handler = ^(MSUserInformation *_Nullable userInformation, NSError *_Nullable error) {
    self.signInUserInformation = userInformation;
    self.signInError = error;
  };

  // When
  [self.sut signInWithCompletionHandler:handler];
  MSAuthTokenInfo *actualAuthTokenInfo = [[[MSAuthTokenContext sharedInstance] authTokenHistory] lastObject];

  // Then
  OCMVerify([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]);
  XCTAssertEqualObjects(idToken, [MSAuthTokenContext sharedInstance].authToken);
  XCTAssertEqualObjects(idToken, actualAuthTokenInfo.authToken);
  XCTAssertNotNil(self.signInUserInformation);
  XCTAssertEqualObjects(accountId, self.signInUserInformation.accountId);
  XCTAssertEqualObjects(idToken, self.signInUserInformation.idToken);
  XCTAssertEqualObjects(accessToken, self.signInUserInformation.accessToken);
  XCTAssertNil(self.signInError);
}

- (void)testSignInDoesNotAcquireTokenWhenDisabled {

  // If
  self.sut.clientApplication = self.clientApplicationMock;
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
  XCTAssertEqualObjects(kMSACAuthErrorDomain, self.signInError.domain);
  XCTAssertEqual(MSACAuthErrorServiceDisabled, self.signInError.code);
  XCTAssertNotNil(self.signInError.userInfo[NSLocalizedDescriptionKey]);
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
  [self.sut signInWithCompletionHandler:handler];

  // Then
  XCTAssertNil(self.signInUserInformation);
  XCTAssertNotNil(self.signInError);
  XCTAssertEqualObjects(kMSACAuthErrorDomain, self.signInError.domain);
  XCTAssertEqual(MSACAuthErrorNoConnection, self.signInError.code);
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
  [self.sut signInWithCompletionHandler:handler];

  // Then
  XCTAssertNil(self.signInUserInformation);
  XCTAssertNotNil(self.signInError);
  XCTAssertEqualObjects(kMSACAuthErrorDomain, self.signInError.domain);
  XCTAssertEqual(MSACAuthErrorSignInNotConfigured, self.signInError.code);
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
  [self.sut signInWithCompletionHandler:handler];

  // Then
  XCTAssertNil(self.signInUserInformation);
  XCTAssertNotNil(self.signInError);
  XCTAssertEqualObjects(kMSACAuthErrorDomain, self.signInError.domain);
  XCTAssertEqual(MSACAuthErrorSignInNotConfigured, self.signInError.code);
  XCTAssertNotNil(self.signInError.userInfo[NSLocalizedDescriptionKey]);
  [authMock stopMocking];
}

- (void)testSecondSignInSuccessAfterFirstSignInFails {

  // If
  NSString *idToken = @"idToken";
  NSString *accessToken = @"accessToken";
  NSString *accountId = @"94c82516-cbee-44aa-8a6a-19f8d20322be";
  id tenantProfile = OCMClassMock(MSALTenantProfile.class);
  OCMStub([tenantProfile identifier]).andReturn(accountId);
  id msalResultMock = OCMPartialMock([MSALResult new]);
  OCMStub([msalResultMock idToken]).andReturn(idToken);
  OCMStub([msalResultMock accessToken]).andReturn(accessToken);
  OCMStub([msalResultMock tenantProfile]).andReturn(tenantProfile);
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
  [self.sut signInWithCompletionHandler:handler1];

  // Then
  XCTAssertNil(self.signInUserInformation);
  XCTAssertNotNil(self.signInError);
  XCTAssertEqualObjects(kMSACAuthErrorDomain, self.signInError.domain);
  XCTAssertEqual(MSACAuthErrorSignInNotConfigured, self.signInError.code);
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
  [self.sut signInWithCompletionHandler:handler2];

  // When we complete second call
  self.msalCompletionBlock(msalResultMock, nil);
  MSAuthTokenInfo *actualAuthTokenInfo = [[[MSAuthTokenContext sharedInstance] authTokenHistory] lastObject];

  // Then
  OCMVerify([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]);
  XCTAssertEqualObjects(idToken, [MSAuthTokenContext sharedInstance].authToken);
  XCTAssertEqualObjects(idToken, actualAuthTokenInfo.authToken);
  XCTAssertNotNil(self.signInUserInformation);
  XCTAssertEqualObjects(accountId, self.signInUserInformation.accountId);
  XCTAssertEqualObjects(idToken, self.signInUserInformation.idToken);
  XCTAssertEqualObjects(accessToken, self.signInUserInformation.accessToken);
  XCTAssertNil(self.signInError);
  [authMock stopMocking];
}

- (void)testSilentSignInSavesAuthTokenAndHomeAccountId {

  // If
  NSString *expectedAccountId = @"fakeAccountId";
  NSString *expectedAuthToken = @"fakeAuthToken";
  id accountMock = OCMClassMock(MSALAccount.class);
  OCMStub([accountMock identifier]).andReturn(expectedAccountId);
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
  XCTAssertEqualObjects([MSAuthTokenContext sharedInstance].accountId, expectedAccountId);

  [accountMock stopMocking];
  [authMock stopMocking];
  [msalResultMock stopMocking];
}

- (void)testSilentSignInFailureTriggersInteractiveSignIn {

  // If
  self.sut.clientApplication = self.clientApplicationMock;
  self.sut.authConfig = [MSAuthConfig new];
  self.sut.authConfig.authScope = @"fake";
  id accountMock = OCMClassMock(MSALAccount.class);
  OCMStub([accountMock identifier]).andReturn(@"Something");
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
  [self.sut signInWithCompletionHandler:nil];

  // Then
  OCMVerify([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]);
  [authMock stopMocking];
}

- (void)testSignInTriggersSilentAuthentication {

  // If
  NSString *fakeAccountId = @"fakeAccountId";
  id accountMock = OCMClassMock(MSALAccount.class);
  OCMStub([accountMock identifier]).andReturn(fakeAccountId);
  NSData *serializedConfig = [NSJSONSerialization dataWithJSONObject:self.dummyConfigDic options:(NSJSONWritingOptions)0 error:nil];
  OCMStub([self.utilityMock loadDataForPathComponent:[self.sut authConfigFilePath]]).andReturn(serializedConfig);
  [self.sut applyEnabledState:YES];
  [[MSAuthTokenContext sharedInstance] setAuthToken:@"token" withAccountId:fakeAccountId expiresOn:nil];

  /*
   * `accountForHomeAccountId:error:` takes a double pointer (NSError * _Nullable __autoreleasing * _Nullable) so we need to pass in
   * `[OCMArg anyObjectRef]`. Passing in `OCMOCK_ANY` or `nil` will cause the OCMStub to not work.
   */
  OCMStub([self.clientApplicationMock accountForIdentifier:fakeAccountId error:[OCMArg anyObjectRef]]).andReturn(accountMock);
  self.sut.clientApplication = self.clientApplicationMock;
  self.sut.authConfig = [MSAuthConfig new];
  self.sut.authConfig.authScope = @"fake";

  // Then
  OCMReject([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]);

  // When
  [self.sut signInWithCompletionHandler:nil];

  // Then
  OCMVerify([self.clientApplicationMock acquireTokenSilentForScopes:OCMOCK_ANY account:OCMOCK_ANY completionBlock:OCMOCK_ANY]);
}

- (void)testSignInAlreadyInProgress {

  // If
  NSString *idToken = @"idToken";
  NSString *accessToken = @"accessToken";
  NSString *accountId = @"94c82516-cbee-44aa-8a6a-19f8d20322be";
  id tenantProfile = OCMClassMock(MSALTenantProfile.class);
  OCMStub([tenantProfile identifier]).andReturn(accountId);
  id msalResultMock = OCMPartialMock([MSALResult new]);
  OCMStub([msalResultMock idToken]).andReturn(idToken);
  OCMStub([msalResultMock accessToken]).andReturn(accessToken);
  OCMStub([msalResultMock tenantProfile]).andReturn(tenantProfile);
  NSData *serializedConfig = [NSJSONSerialization dataWithJSONObject:self.dummyConfigDic options:(NSJSONWritingOptions)0 error:nil];
  OCMStub([self.utilityMock loadDataForPathComponent:[self.sut authConfigFilePath]]).andReturn(serializedConfig);
  OCMStub([self.clientApplicationMock alloc]).andReturn(self.clientApplicationMock);
  OCMStub([self.clientApplicationMock initWithConfiguration:OCMOCK_ANY error:[OCMArg anyObjectRef]]).andReturn(self.clientApplicationMock);
  OCMStub([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __block MSALCompletionBlock completionBlock;
    [invocation getArgument:&completionBlock atIndex:3];
    self.msalCompletionBlock = completionBlock;
  });
  [self.sut applyEnabledState:YES];

  // When we make a first call
  MSSignInCompletionHandler handler1 = ^(MSUserInformation *_Nullable userInformation, NSError *_Nullable error) {
    self.signInUserInformation = userInformation;
    self.signInError = error;
  };
  [self.sut signInWithCompletionHandler:handler1];

  // And we make a second call before the first complete
  MSSignInCompletionHandler handler2 = ^(MSUserInformation *_Nullable userInformation, NSError *_Nullable error) {
    self.signInUserInformation = userInformation;
    self.signInError = error;
  };
  [self.sut signInWithCompletionHandler:handler2];

  // Then second call immediately fails
  XCTAssertNil(self.signInUserInformation);
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
  XCTAssertEqualObjects(idToken, self.signInUserInformation.idToken);
  XCTAssertEqualObjects(accessToken, self.signInUserInformation.accessToken);
  XCTAssertEqualObjects(accountId, self.signInUserInformation.accountId);
  XCTAssertNil(self.signInError);
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
  [self.sut signInWithCompletionHandler:handler];

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
  [self.sut signInWithCompletionHandler:handler];

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
  id tenantProfile = OCMClassMock(MSALTenantProfile.class);
  OCMStub([tenantProfile identifier]).andReturn(accountId);
  id msalResultMock = OCMPartialMock([MSALResult new]);
  OCMStub([msalResultMock idToken]).andReturn(idToken);
  OCMStub([msalResultMock tenantProfile]).andReturn(tenantProfile);
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
  [self.sut signInWithCompletionHandler:handler];
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
  [self.sut signOut];

  // Then
  OCMVerify([mockDelegate authTokenContext:OCMOCK_ANY didUpdateAuthToken:nil]);
  OCMVerify([mockDelegate authTokenContext:OCMOCK_ANY didUpdateAccountId:nil]);
  [authMock stopMocking];
}

- (void)testSignOutRemovesAccountFromMSAL {

  // If
  NSString *accountId = @"someAccount";
  [[MSAuthTokenContext sharedInstance] setAuthToken:@"someToken" withAccountId:accountId expiresOn:nil];
  id accountMock = OCMClassMock(MSALAccount.class);
  self.sut.clientApplication = self.clientApplicationMock;
  OCMStub([self.clientApplicationMock accountForIdentifier:accountId error:[OCMArg anyObjectRef]]).andReturn(accountMock);
  id authMock = OCMPartialMock(self.sut);
  OCMStub([authMock sharedInstance]).andReturn(authMock);
  OCMStub([authMock canBeUsed]).andReturn(YES);

  // When
  [self.sut signOut];

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
  [self.sut signOut];
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
  [self.sut signOut];
  XCTAssertTrue([self.sut removeAccount]);

  // Then
  OCMVerifyAll(self.clientApplicationMock);
  [authMock stopMocking];
}

- (void)testSignOutClearsAuthTokenAndAccountId {

  // If
  [self mockURLScheme:nil];
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
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
  [self.sut signOut];
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
  [self.sut signOut];

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
  [self.sut signOut];
  MSAuthTokenInfo *actualAuthTokenInfo = [[[MSAuthTokenContext sharedInstance] authTokenHistory] lastObject];

  // Then
  XCTAssertEqualObjects([[MSAuthTokenContext sharedInstance] authToken], authToken);
  XCTAssertEqualObjects(actualAuthTokenInfo.authToken, authToken);
  XCTAssertEqualObjects(actualAuthTokenInfo.accountId, accountId);
  [authMock stopMocking];
}

- (void)testDefaultConfigUrl {

  // If
  [self mockURLScheme:nil];

  // When
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                        appSecret:kMSTestAppSecret
          transmissionTargetToken:nil
                  fromApplication:YES];

  // Then
  OCMVerify([self.ingestionMock initWithBaseUrl:kMSAuthDefaultBaseURL appSecret:kMSTestAppSecret]);
}

- (void)testConfigURLIsPassedToIngestionWhenSetBeforeServiceStart {

  // If
  [self mockURLScheme:nil];
  NSString *baseConfigUrl = @"https://baseconfigurl.com";

  // When
  [self.sut setConfigUrl:baseConfigUrl];
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                        appSecret:kMSTestAppSecret
          transmissionTargetToken:nil
                  fromApplication:YES];

  // Then
  OCMVerify([self.ingestionMock initWithBaseUrl:baseConfigUrl appSecret:kMSTestAppSecret]);
}

- (void)testRefreshNeededTriggersRefresh {

  // If
  [self mockURLScheme:nil];
  NSString *fakeAccountId = @"accountId";
  NSString *fakeAuthToken = @"authToken";
  id authMock = OCMPartialMock(self.sut);
  [[MSAuthTokenContext sharedInstance] addDelegate:authMock];
  [[MSAuthTokenContext sharedInstance] setAuthToken:fakeAuthToken withAccountId:fakeAccountId expiresOn:nil];
  id fakeValidityInfo = OCMClassMock([MSAuthTokenValidityInfo class]);
  OCMStub([fakeValidityInfo expiresSoon]).andReturn(YES);
  OCMStub([fakeValidityInfo authToken]).andReturn(fakeAuthToken);
  OCMStub([authMock loadConfigurationFromCache]).andReturn(YES);
  OCMStub([authMock sharedInstance]).andReturn(authMock);
  OCMStub([authMock canBeUsed]).andReturn(YES);
  self.sut.authConfig = [MSAuthConfig new];
  self.sut.authConfig.authScope = @"fake";
  OCMStub([authMock configAuthenticationClient]).andDo(^(NSInvocation *__unused invocation) {
    self.sut.clientApplication = self.clientApplicationMock;
  });
  id accountMock = OCMClassMock(MSALAccount.class);
  OCMStub([authMock retrieveAccountWithAccountId:fakeAccountId]).andReturn(accountMock);

  // When
  [authMock startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                        appSecret:kMSTestAppSecret
          transmissionTargetToken:nil
                  fromApplication:YES];
  [[MSAuthTokenContext sharedInstance] checkIfTokenNeedsToBeRefreshed:fakeValidityInfo];

  // Then
  OCMVerify([self.clientApplicationMock acquireTokenSilentForScopes:OCMOCK_ANY account:OCMOCK_ANY completionBlock:OCMOCK_ANY]);

  // Clear
  [fakeValidityInfo stopMocking];
  [authMock stopMocking];
  [accountMock stopMocking];
}

- (void)testRefreshNeededWithNilAccountTriggersAnonymous {

  // If
  NSString *fakeAccountId = @"accountId";
  NSString *fakeAuthToken = @"authToken";
  [self mockURLScheme:nil];
  id fakeValidityInfo = OCMClassMock([MSAuthTokenValidityInfo class]);
  OCMStub([fakeValidityInfo expiresSoon]).andReturn(YES);
  OCMStub([fakeValidityInfo authToken]).andReturn(fakeAuthToken);
  id authMock = OCMPartialMock(self.sut);
  OCMStub([authMock loadConfigurationFromCache]).andReturn(YES);
  OCMStub([authMock configAuthenticationClient]).andDo(^(NSInvocation *__unused invocation) {
    self.sut.clientApplication = self.clientApplicationMock;
  });
  OCMStub([authMock sharedInstance]).andReturn(authMock);
  OCMStub([authMock canBeUsed]).andReturn(YES);
  OCMStub([authMock retrieveAccountWithAccountId:fakeAccountId]).andReturn(nil);
  self.sut.authConfig = [MSAuthConfig new];
  self.sut.authConfig.authScope = @"fake";
  OCMReject([self.sut.clientApplication acquireTokenSilentForScopes:OCMOCK_ANY account:OCMOCK_ANY completionBlock:OCMOCK_ANY]);
  id authTokenContextMock = OCMPartialMock([MSAuthTokenContext sharedInstance]);
  OCMStub([authTokenContextMock sharedInstance]).andReturn(authTokenContextMock);

  // When
  [authMock startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                        appSecret:kMSTestAppSecret
          transmissionTargetToken:nil
                  fromApplication:YES];
  [authTokenContextMock setAuthToken:fakeAuthToken withAccountId:fakeAccountId expiresOn:nil];
  [authTokenContextMock checkIfTokenNeedsToBeRefreshed:fakeValidityInfo];

  // Then
  OCMVerify([authTokenContextMock setAuthToken:nil withAccountId:nil expiresOn:nil]);

  // Clear
  [fakeValidityInfo stopMocking];
  [authMock stopMocking];
  [authTokenContextMock stopMocking];
}

- (void)testRefreshWithExpiredTokenWhileMsalNotConfigured {

  // If
  NSString *fakeAccountId = @"accountId";
  NSString *fakeAuthToken = @"authToken";
  id authMock = OCMPartialMock(self.sut);
  [[MSAuthTokenContext sharedInstance] addDelegate:authMock];
  [[MSAuthTokenContext sharedInstance] setAuthToken:fakeAuthToken withAccountId:fakeAccountId expiresOn:nil];
  id fakeValidityInfo = OCMClassMock([MSAuthTokenValidityInfo class]);
  OCMStub([fakeValidityInfo expiresSoon]).andReturn(YES);
  OCMStub([fakeValidityInfo authToken]).andReturn(fakeAuthToken);
  OCMStub([authMock sharedInstance]).andReturn(authMock);
  OCMStub([authMock canBeUsed]).andReturn(YES);
  self.sut.authConfig = [MSAuthConfig new];
  self.sut.authConfig.authScope = @"fake";
  id authTokenContextMock = OCMPartialMock([MSAuthTokenContext sharedInstance]);
  OCMStub([authTokenContextMock sharedInstance]).andReturn(authTokenContextMock);

  // If MSAL client not configured yet.
  self.sut.clientApplication = nil;

  // Shouldn't call MSAL client while it is not configured.
  OCMReject([authMock retrieveAccountWithAccountId:OCMOCK_ANY]);

  // When
  [[MSAuthTokenContext sharedInstance] checkIfTokenNeedsToBeRefreshed:fakeValidityInfo];

  // Then
  OCMVerifyAll(authMock);

  // Clear
  [fakeValidityInfo stopMocking];
  [authMock stopMocking];
  [authTokenContextMock stopMocking];
}

- (void)testRefreshRetriedAfterMsalConfigured {

  // If
  NSString *fakeAccountId = @"accountId";
  NSString *fakeAuthToken = @"authToken";
  id authMock = OCMPartialMock(self.sut);
  [[MSAuthTokenContext sharedInstance] addDelegate:authMock];
  [[MSAuthTokenContext sharedInstance] setAuthToken:fakeAuthToken withAccountId:fakeAccountId expiresOn:nil];
  id fakeValidityInfo = OCMClassMock([MSAuthTokenValidityInfo class]);
  OCMStub([fakeValidityInfo expiresSoon]).andReturn(YES);
  OCMStub([fakeValidityInfo authToken]).andReturn(fakeAuthToken);
  OCMStub([authMock sharedInstance]).andReturn(authMock);
  OCMStub([authMock canBeUsed]).andReturn(YES);
  self.sut.authConfig = [MSAuthConfig new];
  self.sut.authConfig.authScope = @"fake";
  id authTokenContextMock = OCMPartialMock([MSAuthTokenContext sharedInstance]);
  OCMStub([authTokenContextMock sharedInstance]).andReturn(authTokenContextMock);
  __block int count = 0;
  OCMStub([self.clientApplicationMock accountForIdentifier:OCMOCK_ANY error:[OCMArg anyObjectRef]])
      .andDo(^(NSInvocation *__unused invocation) {
        count++;
      });

  // If MSAL client not configured yet.
  self.sut.clientApplication = nil;

  // When
  [[MSAuthTokenContext sharedInstance] checkIfTokenNeedsToBeRefreshed:fakeValidityInfo];

  // MSAL client configured.
  self.sut.clientApplication = self.clientApplicationMock;
  [[MSAuthTokenContext sharedInstance] checkIfTokenNeedsToBeRefreshed:fakeValidityInfo];

  // Then
  assertThatInt(count, equalToInt(1));

  // Clear
  [fakeValidityInfo stopMocking];
  [authMock stopMocking];
  [authTokenContextMock stopMocking];
}

- (void)testContinuePendingSignInAfterConfigDownloaded {

  // If
  __block MSSendAsyncCompletionHandler ingestionBlock;
  MSSignInCompletionHandler handler = ^(MSUserInformation *_Nullable userInformation, NSError *_Nullable error) {
    self.signInUserInformation = userInformation;
    self.signInError = error;
  };
  NSString *expectedETag = @"newETag";
  NSString *expectedAccountId = @"accountID";
  NSData *newConfig = [NSJSONSerialization dataWithJSONObject:self.dummyConfigDic options:(NSJSONWritingOptions)0 error:nil];
  OCMStub([self.ingestionMock sendAsync:nil eTag:nil completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    // Get ingestion block for later call.
    [invocation retainArguments];
    [invocation getArgument:&ingestionBlock atIndex:4];
  });
  id tenantProfile = OCMClassMock(MSALTenantProfile.class);
  OCMStub([tenantProfile identifier]).andReturn(expectedAccountId);
  id msalResultMock = OCMPartialMock([MSALResult new]);
  OCMStub([msalResultMock tenantProfile]).andReturn(tenantProfile);
  OCMStub([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __block MSALCompletionBlock completionBlock;
    [invocation getArgument:&completionBlock atIndex:3];
    completionBlock(msalResultMock, nil);
  });
  OCMStub([self.clientApplicationMock alloc]).andReturn(self.clientApplicationMock);
  OCMStub([self.clientApplicationMock initWithConfiguration:OCMOCK_ANY error:[OCMArg anyObjectRef]]).andReturn(self.clientApplicationMock);
  self.sut.ingestion = self.ingestionMock;
  [self.sut applyEnabledState:YES];
  [self.sut downloadConfigurationWithETag:nil];
  [self.sut signInWithCompletionHandler:handler];

  // When
  ingestionBlock(@"callId", [MSHttpTestUtil createMockResponseForStatusCode:200 headers:@{kMSETagResponseHeader : expectedETag}], newConfig,
                 nil);

  // Then
  XCTAssertEqualObjects(self.signInUserInformation.accountId, expectedAccountId);
  XCTAssertNil(self.signInError);
}

- (void)testSignInDontWaitForConfigIfConfigCached {

  // If
  NSString *accountId = @"94c82516-cbee-44aa-8a6a-19f8d20322be";
  NSString *idToken = @"idToken";
  NSString *accessToken = @"accessToken";
  id tenantProfile = OCMClassMock(MSALTenantProfile.class);
  OCMStub([tenantProfile identifier]).andReturn(accountId);
  id msalResultMock = OCMPartialMock([MSALResult new]);
  OCMStub([msalResultMock tenantProfile]).andReturn(tenantProfile);
  OCMStub([msalResultMock idToken]).andReturn(idToken);
  OCMStub([msalResultMock accessToken]).andReturn(accessToken);
  NSData *serializedConfig = [NSJSONSerialization dataWithJSONObject:self.dummyConfigDic options:(NSJSONWritingOptions)0 error:nil];
  OCMStub([self.utilityMock loadDataForPathComponent:[self.sut authConfigFilePath]]).andReturn(serializedConfig);
  OCMStub([self.clientApplicationMock alloc]).andReturn(self.clientApplicationMock);
  OCMStub([self.clientApplicationMock initWithConfiguration:OCMOCK_ANY error:[OCMArg anyObjectRef]]).andReturn(self.clientApplicationMock);
  OCMStub([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __block MSALCompletionBlock completionBlock;
    [invocation getArgument:&completionBlock atIndex:3];
    completionBlock(msalResultMock, nil);
  });
  [self.sut applyEnabledState:YES];
  MSSignInCompletionHandler handler = ^(MSUserInformation *_Nullable userInformation, NSError *_Nullable error) {
    self.signInUserInformation = userInformation;
    self.signInError = error;
  };

  // When
  [self.sut signInWithCompletionHandler:handler];

  // Then
  XCTAssertNil(self.signInError);
  XCTAssertEqualObjects(self.signInUserInformation.accountId, accountId);
  XCTAssertEqualObjects(self.signInUserInformation.idToken, idToken);
  XCTAssertEqualObjects(self.signInUserInformation.accessToken, accessToken);
}

- (void)testCancelPendingOperationWithErrorCode {

  // If
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called."];
  NSInteger errorCode = 1;
  NSString *message = @"test";
  __block NSError *signInError;
  __block NSError *refreshError;
  self.sut.signInCompletionHandler = ^(MSUserInformation *_Nullable __unused userInformation, NSError *_Nullable error) {
    signInError = error;
  };
  self.sut.refreshCompletionHandler = ^(MSUserInformation *_Nullable __unused userInformation, NSError *_Nullable error) {
    refreshError = error;

    // Fulfill expectation here. MSAuth calls signInCompletionHandler and then refreshCompletionHandler.
    [expectation fulfill];
  };

  // When
  [self.sut cancelPendingOperationsWithErrorCode:1 message:@"test"];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertNotNil(signInError);
                                 XCTAssertEqual(signInError.domain, kMSACAuthErrorDomain);
                                 XCTAssertEqual(signInError.code, errorCode);
                                 XCTAssertEqual(signInError.userInfo[NSLocalizedDescriptionKey], message);
                                 XCTAssertNotNil(refreshError);
                                 XCTAssertEqual(refreshError.domain, kMSACAuthErrorDomain);
                                 XCTAssertEqual(refreshError.code, errorCode);
                                 XCTAssertEqual(refreshError.userInfo[NSLocalizedDescriptionKey], message);
                               }];
}

- (void)testCancelPendingOperationWhenDisabled {

  // If
  id authMock = OCMPartialMock(self.sut);

  // When
  [authMock setEnabled:NO];

  // Then
  OCMVerify([authMock cancelPendingOperationsWithErrorCode:MSACAuthErrorServiceDisabled message:OCMOCK_ANY]);
  [authMock stopMocking];
}

- (void)testCancelPendingOperationWhenSignOut {

  // If
  id authMock = OCMPartialMock(self.sut);
  OCMStub([authMock sharedInstance]).andReturn(authMock);
  OCMStub([authMock canBeUsed]).andReturn(YES);

  // When
  [MSAuth signOut];

  // Then
  OCMVerify([authMock cancelPendingOperationsWithErrorCode:MSACAuthErrorInterruptedByAnotherOperation message:OCMOCK_ANY]);
  [authMock stopMocking];
}

- (void)testInvalidURLSchemeDoesNotStartAuth {

  // If
  [self mockURLScheme:@"Invalid URL scheme"];

  // When
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                        appSecret:kMSTestAppSecret
          transmissionTargetToken:nil
                  fromApplication:YES];

  // Then
  XCTAssertFalse(self.sut.started);
}

- (void)testCheckValidURLSchemeRegistered {

  // If
  [self mockURLScheme:nil];

  // When
  BOOL valid = [self.sut checkURLSchemeRegistered:[NSString stringWithFormat:kMSMSALCustomSchemeFormat, kMSTestAppSecret]];

  // Then
  XCTAssertTrue(valid);
}

- (void)testCheckInvalidAppSecretForURLSchemeRegistered {

  // If
  [self mockURLScheme:nil];

  // When
  BOOL valid = [self.sut checkURLSchemeRegistered:[NSString stringWithFormat:kMSMSALCustomSchemeFormat, MS_UUID_STRING]];

  // Then
  XCTAssertFalse(valid);
}

- (void)testCheckInvalidTypeRoleForURLSchemeRegistered {

  // If
  NSString *validURLScheme = @"Valid URL Scheme";
  NSArray *bundleArray = @[ @{kMSCFBundleTypeRole : @"None", kMSCFBundleURLSchemes : @[ validURLScheme ]} ];
  OCMStub([self.bundleMock objectForInfoDictionaryKey:kMSCFBundleURLTypes]).andReturn(bundleArray);

  // When
  BOOL valid = [self.sut checkURLSchemeRegistered:validURLScheme];

  // Then
  XCTAssertFalse(valid);
}

- (void)testCheckNoURLSchemeRegistered {

  // If
  OCMStub([self.bundleMock objectForInfoDictionaryKey:kMSCFBundleURLTypes]).andReturn(nil);

  // When
  BOOL valid = [self.sut checkURLSchemeRegistered:@"Valid URL Scheme"];

  // Then
  XCTAssertFalse(valid);
}

- (void)mockURLScheme:(NSString *)urlScheme {
  if (!urlScheme) {
    urlScheme = [NSString stringWithFormat:kMSMSALCustomSchemeFormat, kMSTestAppSecret];
  }
  NSArray *bundleArray = @[ @{kMSCFBundleTypeRole : kMSURLTypeRoleEditor, kMSCFBundleURLSchemes : @[ urlScheme ]} ];
  OCMStub([self.bundleMock objectForInfoDictionaryKey:kMSCFBundleURLTypes]).andReturn(bundleArray);
}

@end
