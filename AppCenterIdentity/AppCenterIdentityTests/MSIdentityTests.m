#import <Foundation/Foundation.h>

#import "MSAuthTokenContext.h"
#import "MSAuthTokenContextDelegate.h"
#import "MSChannelGroupProtocol.h"
#import "MSChannelUnitProtocol.h"
#import "MSHttpTestUtil.h"
#import "MSIdentity.h"
#import "MSIdentityConfigIngestion.h"
#import "MSIdentityConstants.h"
#import "MSIdentityPrivate.h"
#import "MSMockKeychainUtil.h"
#import "MSMockUserDefaults.h"
#import "MSServiceAbstractProtected.h"
#import "MSTestFrameworks.h"
#import "MSUtility+File.h"
#import <MSAL/MSAL.h>
#import <MSAL/MSALPublicClientApplication.h>
#import <OCMock/OCMock.h>

static NSString *const kMSTestAppSecret = @"TestAppSecret";

@interface MSIdentity (Test)

- (void)configAuthenticationClient;
- (BOOL)removeAccount;
- (BOOL)removeAuthToken;
- (void)removeAccountId;

@end

@interface MSIdentityTests : XCTestCase

@property(nonatomic) MSIdentity *sut;
@property(nonatomic) MSMockUserDefaults *settingsMock;
@property(nonatomic) NSDictionary *dummyConfigDic;
@property(nonatomic) id utilityMock;
@property(nonatomic) id keychainUtilMock;
@property(nonatomic) id ingestionMock;
@property(nonatomic) id clientApplicationMock;
@property(nonatomic) MSUserInformation *signInUserInformation;
@property(nonatomic) NSError *signInError;
@property(nonatomic) MSALCompletionBlock msalCompletionBlock;

@end

@implementation MSIdentityTests

- (void)setUp {
  [super setUp];
  self.settingsMock = [MSMockUserDefaults new];
  self.utilityMock = OCMClassMock([MSUtility class]);
  self.dummyConfigDic = @{
    @"identity_scope" : @"scope",
    @"client_id" : @"clientId",
    @"redirect_uri" : @"https://contoso.com/identity/path",
    @"authorities" : @[
      @{@"type" : @"B2C", @"default" : @YES, @"authority_url" : @"https://contoso.com/identity/path1"},
      @{@"type" : @"RandomType", @"default" : @NO, @"authority_url" : @"https://contoso.com/identity/path2"}
    ]
  };
  self.sut = [MSIdentity sharedInstance];
  self.keychainUtilMock = [MSMockKeychainUtil new];
  self.ingestionMock = OCMPartialMock([MSIdentityConfigIngestion alloc]);
  OCMStub([self.ingestionMock alloc]).andReturn(self.ingestionMock);
  self.clientApplicationMock = OCMClassMock([MSALPublicClientApplication class]);
}

- (void)tearDown {
  [super tearDown];
  [MSIdentity resetSharedInstance];
  self.sut = [MSIdentity sharedInstance];
  [MSAuthTokenContext resetSharedInstance];
  [self.settingsMock stopMocking];
  [self.utilityMock stopMocking];
  [self.keychainUtilMock stopMocking];
  [self.ingestionMock stopMocking];
  [self.clientApplicationMock stopMocking];
}

- (void)testApplyEnabledStateWorks {

  // If
  [[MSIdentity sharedInstance] startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
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

- (void)testLoadAndDownloadOnEnabling {

  // If
  NSString *expectedETag = @"eTag";
  [self.settingsMock setObject:expectedETag forKey:kMSIdentityETagKey];
  NSData *serializedConfig = [NSJSONSerialization dataWithJSONObject:self.dummyConfigDic options:(NSJSONWritingOptions)0 error:nil];
  OCMStub([self.utilityMock loadDataForPathComponent:[self.sut identityConfigFilePath]]).andReturn(serializedConfig);
  OCMStub([self.ingestionMock sendAsync:OCMOCK_ANY eTag:OCMOCK_ANY completionHandler:OCMOCK_ANY]);

  // When
  [self.sut applyEnabledState:YES];

  // Then
  XCTAssertTrue([self.sut.identityConfig isValid]);
  OCMVerify([self.ingestionMock sendAsync:nil eTag:expectedETag completionHandler:OCMOCK_ANY]);
}

- (void)testEnablingReadsAuthTokenFromKeychainAndSetsAuthContext {

  // If
  NSString *expectedToken = @"expected";
  [MSMockKeychainUtil storeString:expectedToken forKey:kMSIdentityAuthTokenKey];
  NSString *expectedETag = @"eTag";
  [self.settingsMock setObject:expectedETag forKey:kMSIdentityETagKey];
  [self.settingsMock setObject:@"fakeHomeAccountId" forKey:kMSIdentityMSALAccountHomeAccountKey];
  NSData *serializedConfig = [NSJSONSerialization dataWithJSONObject:self.dummyConfigDic options:(NSJSONWritingOptions)0 error:nil];
  OCMStub([self.utilityMock loadDataForPathComponent:[self.sut identityConfigFilePath]]).andReturn(serializedConfig);
  OCMStub([self.ingestionMock sendAsync:OCMOCK_ANY eTag:OCMOCK_ANY completionHandler:OCMOCK_ANY]);

  // When
  [self.sut applyEnabledState:YES];

  // Then
  XCTAssertEqual([MSAuthTokenContext sharedInstance].authToken, expectedToken);
}

- (void)testEnablingReadsAuthTokenFromKeychainAndDoesNotSetAuthContextIfNilAccount {

  // If
  NSString *expectedToken = @"expected";
  [MSMockKeychainUtil storeString:expectedToken forKey:kMSIdentityAuthTokenKey];
  NSString *expectedETag = @"eTag";
  [self.settingsMock setObject:expectedETag forKey:kMSIdentityETagKey];
  NSData *serializedConfig = [NSJSONSerialization dataWithJSONObject:self.dummyConfigDic options:(NSJSONWritingOptions)0 error:nil];
  OCMStub([self.utilityMock loadDataForPathComponent:[self.sut identityConfigFilePath]]).andReturn(serializedConfig);
  id<MSAuthTokenContextDelegate> mockDelegate = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [[MSAuthTokenContext sharedInstance] addDelegate:mockDelegate];
  OCMStub([self.ingestionMock sendAsync:OCMOCK_ANY eTag:OCMOCK_ANY completionHandler:OCMOCK_ANY]);

  // Then
  OCMReject([mockDelegate authTokenContext:OCMOCK_ANY didSetNewAuthToken:OCMOCK_ANY]);

  // When
  [self.sut applyEnabledState:YES];
}

- (void)testEnablingReadsAuthTokenFromKeychainAndDoesNotSetAuthContextIfNil {

  // If
  NSString *expectedETag = @"eTag";
  [self.settingsMock setObject:expectedETag forKey:kMSIdentityETagKey];
  NSData *serializedConfig = [NSJSONSerialization dataWithJSONObject:self.dummyConfigDic options:(NSJSONWritingOptions)0 error:nil];
  OCMStub([self.utilityMock loadDataForPathComponent:[self.sut identityConfigFilePath]]).andReturn(serializedConfig);
  id<MSAuthTokenContextDelegate> mockDelegate = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [[MSAuthTokenContext sharedInstance] addDelegate:mockDelegate];
  OCMStub([self.ingestionMock sendAsync:OCMOCK_ANY eTag:OCMOCK_ANY completionHandler:OCMOCK_ANY]);

  // Then
  OCMReject([mockDelegate authTokenContext:OCMOCK_ANY didSetNewAuthToken:OCMOCK_ANY]);

  // When
  [self.sut applyEnabledState:YES];
}

- (void)testCleanUpOnDisabling {

  // If
  NSData *serializedConfig = [NSJSONSerialization dataWithJSONObject:self.dummyConfigDic options:(NSJSONWritingOptions)0 error:nil];
  OCMStub([self.utilityMock loadDataForPathComponent:[self.sut identityConfigFilePath]]).andReturn(serializedConfig);
  [self.settingsMock setObject:@"eTag" forKey:kMSIdentityETagKey];
  [[MSIdentity sharedInstance] startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                                           appSecret:kMSTestAppSecret
                             transmissionTargetToken:nil
                                     fromApplication:YES];
  [MSMockKeychainUtil storeString:@"foobar" forKey:kMSIdentityAuthTokenKey];
  [[MSAuthTokenContext sharedInstance] setAuthToken:@"someToken" withAccountId:@"someAccount"];
  [self.settingsMock setObject:@"fakeHomeAccountId" forKey:kMSIdentityMSALAccountHomeAccountKey];
  [self.sut setEnabled:YES];
  id accountMock = OCMPartialMock([MSALAccount new]);
  self.sut.clientApplication = self.clientApplicationMock;
  OCMStub([self.clientApplicationMock accountForHomeAccountId:OCMOCK_ANY error:[OCMArg anyObjectRef]]).andReturn(accountMock);

  // When
  [self.sut setEnabled:NO];

  // Then
  XCTAssertNil(self.sut.clientApplication);
  XCTAssertNil([MSAuthTokenContext sharedInstance].authToken);
  XCTAssertNil([MSMockKeychainUtil stringForKey:kMSIdentityAuthTokenKey]);
  OCMVerify([self.utilityMock deleteItemForPathComponent:[self.sut identityConfigFilePath]]);
  XCTAssertNil([self.settingsMock objectForKey:kMSIdentityETagKey]);
  XCTAssertNil([self.settingsMock objectForKey:kMSIdentityMSALAccountHomeAccountKey]);
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
  OCMVerify([self.utilityMock createFileAtPathComponent:[self.sut identityConfigFilePath]
                                               withData:newConfig
                                             atomically:YES
                                         forceOverwrite:YES]);
  XCTAssertEqualObjects(expectedETag, [self.settingsMock objectForKey:kMSIdentityETagKey]);
}

- (void)testCacheNewConfigWhenDeprecatedConfigIsCached {

  // If
  __block MSSendAsyncCompletionHandler ingestionBlock;
  NSString *oldETag = @"oldETag";
  NSString *expectedETag = @"newETag";
  [self.settingsMock setObject:oldETag forKey:kMSIdentityETagKey];
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
  OCMVerify([self.utilityMock createFileAtPathComponent:[self.sut identityConfigFilePath]
                                               withData:newConfig
                                             atomically:YES
                                         forceOverwrite:YES]);
  XCTAssertEqualObjects(expectedETag, [self.settingsMock objectForKey:kMSIdentityETagKey]);
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
  OCMReject([self.utilityMock createFileAtPathComponent:[self.sut identityConfigFilePath]
                                               withData:OCMOCK_ANY
                                             atomically:OCMOCK_ANY
                                         forceOverwrite:OCMOCK_ANY]);
  OCMReject([self.settingsMock setObject:OCMOCK_ANY forKey:kMSIdentityETagKey]);

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
  OCMReject([self.utilityMock createFileAtPathComponent:[self.sut identityConfigFilePath]
                                               withData:OCMOCK_ANY
                                             atomically:OCMOCK_ANY
                                         forceOverwrite:OCMOCK_ANY]);
  OCMReject([self.settingsMock setObject:OCMOCK_ANY forKey:kMSIdentityETagKey]);

  // When
  [self.sut downloadConfigurationWithETag:expectedETag];
  ingestionBlock(@"callId", [MSHttpTestUtil createMockResponseForStatusCode:500 headers:nil], expectedConfig, nil);
}

- (void)testForwardRedirectURLToMSAL {

  // If
  NSURL *expectedURL = [NSURL URLWithString:@"scheme://test"];
  id msalMock = OCMClassMock([MSALPublicClientApplication class]);

  // When
  BOOL result = [MSIdentity openURL:expectedURL]; // TODO add more tests

  // Then
  OCMVerify([msalMock handleMSALResponse:expectedURL]);
  XCTAssertFalse(result);
  [msalMock stopMocking];
}

- (void)testConfigureMSALWithInvalidConfig {

  // If
  self.sut.identityConfig = [MSIdentityConfig new];

  // When
  [self.sut configAuthenticationClient];

  // Then
  XCTAssertNil(self.sut.clientApplication);
}

- (void)testLoadInvalidConfigurationFromCache {

  // If
  NSDictionary *invalidData = @{@"invalid" : @"data"};
  NSData *serializedConfig = [NSJSONSerialization dataWithJSONObject:invalidData options:(NSJSONWritingOptions)0 error:nil];
  OCMStub([self.utilityMock loadDataForPathComponent:[self.sut identityConfigFilePath]]).andReturn(serializedConfig);
  [self.settingsMock setObject:@"eTag" forKey:kMSIdentityETagKey];

  // When
  BOOL loaded = [self.sut loadConfigurationFromCache];

  // Then
  XCTAssertFalse(loaded);
  OCMVerify([self.utilityMock deleteItemForPathComponent:[self.sut identityConfigFilePath]]);
  XCTAssertNil([self.settingsMock objectForKey:kMSIdentityETagKey]);
}

- (void)testNotCacheInvalidConfig {

  // If
  __block MSSendAsyncCompletionHandler ingestionBlock;
  NSString *oldETag = @"oldETag";
  NSString *expectedETag = @"newETag";
  [self.settingsMock setObject:oldETag forKey:kMSIdentityETagKey];
  NSData *invalidConfig = [NSJSONSerialization dataWithJSONObject:@{} options:(NSJSONWritingOptions)0 error:nil];
  OCMStub([self.ingestionMock sendAsync:nil eTag:oldETag completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    // Get ingestion block for later call.
    [invocation retainArguments];
    [invocation getArgument:&ingestionBlock atIndex:4];
  });
  MSIdentity *service = (MSIdentity *)[MSIdentity sharedInstance];

  // When
  [service downloadConfigurationWithETag:oldETag];
  ingestionBlock(@"callId", [MSHttpTestUtil createMockResponseForStatusCode:200 headers:@{kMSETagResponseHeader : expectedETag}],
                 invalidConfig, nil);

  // Then
  OCMReject([self.utilityMock createFileAtPathComponent:[service identityConfigFilePath]
                                               withData:OCMOCK_ANY
                                             atomically:YES
                                         forceOverwrite:YES]);
  XCTAssertEqualObjects(oldETag, [self.settingsMock objectForKey:kMSIdentityETagKey]);
}

- (void)testNotCacheInvalidData {

  // If
  __block MSSendAsyncCompletionHandler ingestionBlock;
  NSString *oldETag = @"oldETag";
  NSString *expectedETag = @"newETag";
  [self.settingsMock setObject:oldETag forKey:kMSIdentityETagKey];
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
  OCMReject([self.utilityMock createFileAtPathComponent:[self.sut identityConfigFilePath]
                                               withData:OCMOCK_ANY
                                             atomically:YES
                                         forceOverwrite:YES]);
  XCTAssertEqualObjects(oldETag, [self.settingsMock objectForKey:kMSIdentityETagKey]);
}

- (void)testSignInAcquiresAndSavesToken {

  // If
  NSString *idToken = @"idToken";
  NSString *accountId = @"94c82516-cbee-44aa-8a6a-19f8d20322be";
  id msalResultMock = OCMPartialMock([MSALResult new]);
  OCMStub([msalResultMock idToken]).andReturn(idToken);
  OCMStub([msalResultMock uniqueId]).andReturn(accountId);
  self.sut.clientApplication = self.clientApplicationMock;
  self.sut.identityConfig = [MSIdentityConfig new];
  self.sut.identityConfig.identityScope = @"fake";
  id identityMock = OCMPartialMock(self.sut);
  OCMStub([identityMock sharedInstance]).andReturn(identityMock);
  OCMStub([identityMock canBeUsed]).andReturn(YES);
  OCMStub([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __block MSALCompletionBlock completionBlock;
    [invocation getArgument:&completionBlock atIndex:3];
    completionBlock(msalResultMock, nil);
  });

  // When
  MSSignInCompletionHandler handler = ^(MSUserInformation *_Nullable userInformation, NSError *_Nullable error) {
    self.signInUserInformation = userInformation;
    self.signInError = error;
  };
  [MSIdentity signInWithCompletionHandler:handler];

  // Then
  OCMVerify([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]);
  XCTAssertEqualObjects(idToken, [MSAuthTokenContext sharedInstance].authToken);
  XCTAssertEqualObjects(idToken, [MSMockKeychainUtil stringForKey:kMSIdentityAuthTokenKey]);
  XCTAssertNotNil(self.signInUserInformation);
  XCTAssertEqualObjects(accountId, self.signInUserInformation.accountId);
  XCTAssertNil(self.signInError);
  [identityMock stopMocking];
}

- (void)testSignInDoesNotAcquireTokenWhenDisabled {

  // If
  self.sut.clientApplication = self.clientApplicationMock;
  id identityMock = OCMPartialMock([MSIdentity sharedInstance]);
  OCMStub([identityMock sharedInstance]).andReturn(identityMock);
  OCMStub([identityMock canBeUsed]).andReturn(NO);
  OCMStub([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]).andDo(nil);

  // When
  OCMReject([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]);
  MSSignInCompletionHandler handler = ^(MSUserInformation *_Nullable userInformation, NSError *_Nullable error) {
    self.signInUserInformation = userInformation;
    self.signInError = error;
  };
  [MSIdentity signInWithCompletionHandler:handler];

  // Then
  XCTAssertNil(self.signInUserInformation);
  XCTAssertNotNil(self.signInError);
  XCTAssertEqualObjects(MSIdentityErrorDomain, self.signInError.domain);
  XCTAssertEqual(MSIdentityErrorServiceDisabled, self.signInError.code);
  XCTAssertNotNil(self.signInError.userInfo[MSIdentityErrorDescriptionKey]);
  [identityMock stopMocking];
}

- (void)testSignInFailsWhenNoInternet {

  // If
  self.sut.clientApplication = self.clientApplicationMock;
  id reachability = OCMPartialMock([MS_Reachability reachabilityForInternetConnection]);
  OCMStub([reachability currentReachabilityStatus]).andReturn(NotReachable);
  id reachabilityMock = OCMClassMock([MS_Reachability class]);
  OCMStub(ClassMethod([reachabilityMock reachabilityForInternetConnection])).andReturn(reachability);
  OCMStub([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]).andDo(nil);
  id identityMock = OCMPartialMock(self.sut);
  OCMStub([identityMock sharedInstance]).andReturn(identityMock);
  OCMStub([identityMock canBeUsed]).andReturn(YES);

  // When
  MSSignInCompletionHandler handler = ^(MSUserInformation *_Nullable userInformation, NSError *_Nullable error) {
    self.signInUserInformation = userInformation;
    self.signInError = error;
  };
  [MSIdentity signInWithCompletionHandler:handler];

  // Then
  XCTAssertNil(self.signInUserInformation);
  XCTAssertNotNil(self.signInError);
  XCTAssertEqualObjects(MSIdentityErrorDomain, self.signInError.domain);
  XCTAssertEqual(MSIdentityErrorSignInWhenNoConnection, self.signInError.code);
  XCTAssertNotNil(self.signInError.userInfo[MSIdentityErrorDescriptionKey]);
  [identityMock stopMocking];
}

- (void)testSignInDelayedWhenNoClientApplication {

  // If
  self.sut.identityConfig = [MSIdentityConfig new];
  self.sut.identityConfig.identityScope = @"fake";
  id identityMock = OCMPartialMock(self.sut);
  OCMStub([identityMock sharedInstance]).andReturn(identityMock);
  OCMStub([identityMock canBeUsed]).andReturn(YES);

  // When
  MSSignInCompletionHandler handler = ^(MSUserInformation *_Nullable userInformation, NSError *_Nullable error) {
    self.signInUserInformation = userInformation;
    self.signInError = error;
  };
  [MSIdentity signInWithCompletionHandler:handler];

  // Then
  XCTAssertNil(self.signInUserInformation);
  XCTAssertNotNil(self.signInError);
  XCTAssertEqualObjects(MSIdentityErrorDomain, self.signInError.domain);
  XCTAssertEqual(MSIdentityErrorSignInBackgroundOrNotConfigured, self.signInError.code);
  XCTAssertNotNil(self.signInError.userInfo[MSIdentityErrorDescriptionKey]);
  [identityMock stopMocking];
}

- (void)testSignInFailsWhenNoIdentityConfig {

  // If
  self.sut.clientApplication = self.clientApplicationMock;
  id identityMock = OCMPartialMock(self.sut);
  OCMStub([identityMock sharedInstance]).andReturn(identityMock);
  OCMStub([identityMock canBeUsed]).andReturn(YES);

  // When
  MSSignInCompletionHandler handler = ^(MSUserInformation *_Nullable userInformation, NSError *_Nullable error) {
    self.signInUserInformation = userInformation;
    self.signInError = error;
  };
  [MSIdentity signInWithCompletionHandler:handler];

  // Then
  XCTAssertNil(self.signInUserInformation);
  XCTAssertNotNil(self.signInError);
  XCTAssertEqualObjects(MSIdentityErrorDomain, self.signInError.domain);
  XCTAssertEqual(MSIdentityErrorSignInBackgroundOrNotConfigured, self.signInError.code);
  XCTAssertNotNil(self.signInError.userInfo[MSIdentityErrorDescriptionKey]);
  [identityMock stopMocking];
}

- (void)testSilentSignInSavesAuthTokenAndHomeAccountId {

  // If
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
  self.sut.identityConfig = [MSIdentityConfig new];
  self.sut.identityConfig.identityScope = @"fake";
  id identityMock = OCMPartialMock(self.sut);
  OCMStub([identityMock sharedInstance]).andReturn(identityMock);
  OCMStub([identityMock canBeUsed]).andReturn(YES);

  // When
  [self.sut acquireTokenSilentlyWithMSALAccount:accountMock];

  // Then
  XCTAssertEqualObjects([MSMockKeychainUtil stringForKey:kMSIdentityAuthTokenKey], expectedAuthToken);
  XCTAssertEqualObjects([MSAuthTokenContext sharedInstance].authToken, expectedAuthToken);
  XCTAssertEqualObjects([self.settingsMock valueForKey:kMSIdentityMSALAccountHomeAccountKey], expectedHomeAccountId);
  [accountMock stopMocking];
  [identityMock stopMocking];
  [msalResultMock stopMocking];
}

- (void)testSilentSignInFailureTriggersInteractiveSignIn {

  // If
  self.sut.clientApplication = self.clientApplicationMock;
  self.sut.identityConfig = [MSIdentityConfig new];
  self.sut.identityConfig.identityScope = @"fake";
  id msalResultMock = OCMPartialMock([MSALResult new]);
  NSString *expectedAuthToken = @"fakeAuthToken";
  OCMStub([msalResultMock idToken]).andReturn(expectedAuthToken);
  id identityMock = OCMPartialMock(self.sut);
  OCMStub([identityMock sharedInstance]).andReturn(identityMock);
  OCMStub([identityMock canBeUsed]).andReturn(YES);
  OCMStub([self.clientApplicationMock acquireTokenSilentForScopes:OCMOCK_ANY account:OCMOCK_ANY completionBlock:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __block MSALCompletionBlock completionBlock;
        [invocation getArgument:&completionBlock atIndex:4];
        completionBlock(msalResultMock, OCMOCK_ANY);
      });

  // When
  [self.sut acquireTokenSilentlyWithMSALAccount:OCMOCK_ANY];

  // Then
  OCMVerify([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]);
  [identityMock stopMocking];
}

- (void)testSignInTriggersInteractiveAuthentication {

  // If
  self.sut.clientApplication = self.clientApplicationMock;
  self.sut.identityConfig = [MSIdentityConfig new];
  self.sut.identityConfig.identityScope = @"fake";
  id identityMock = OCMPartialMock(self.sut);
  OCMStub([identityMock sharedInstance]).andReturn(identityMock);
  OCMStub([identityMock canBeUsed]).andReturn(YES);

  // Then
  OCMReject([self.clientApplicationMock acquireTokenSilentForScopes:OCMOCK_ANY account:OCMOCK_ANY completionBlock:OCMOCK_ANY]);

  // When
  [MSIdentity signInWithCompletionHandler:nil];

  // Then
  OCMVerify([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]);
  [identityMock stopMocking];
}

- (void)testSignInTriggersSilentAuthentication {

  // If
  MSALAccountId *mockAccountId = OCMPartialMock([MSALAccountId new]);
  NSString *fakeAccountId = @"fakeHomeAccountId";
  OCMStub(mockAccountId.identifier).andReturn(fakeAccountId);
  id accountMock = OCMPartialMock([MSALAccount new]);
  OCMStub([accountMock homeAccountId]).andReturn(fakeAccountId);
  [self.settingsMock setObject:fakeAccountId forKey:kMSIdentityMSALAccountHomeAccountKey];

  /*
   * `accountForHomeAccountId:error:` takes a double pointer (NSError * _Nullable __autoreleasing * _Nullable) so we need to pass in
   * `[OCMArg anyObjectRef]`. Passing in `OCMOCK_ANY` or `nil` will cause the OCMStub to not work.
   */
  OCMStub([self.clientApplicationMock accountForHomeAccountId:fakeAccountId error:[OCMArg anyObjectRef]]).andReturn(accountMock);
  self.sut.clientApplication = self.clientApplicationMock;
  self.sut.identityConfig = [MSIdentityConfig new];
  self.sut.identityConfig.identityScope = @"fake";
  id identityMock = OCMPartialMock(self.sut);
  OCMStub([identityMock sharedInstance]).andReturn(identityMock);
  OCMStub([identityMock canBeUsed]).andReturn(YES);

  // Then
  OCMReject([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]);

  // When
  [MSIdentity signInWithCompletionHandler:nil];

  // Then
  OCMVerify([self.clientApplicationMock acquireTokenSilentForScopes:OCMOCK_ANY account:OCMOCK_ANY completionBlock:OCMOCK_ANY]);
  [identityMock stopMocking];
}

- (void)testSignInAlreadyInProgress {

  // If
  NSString *idToken = @"idToken";
  NSString *accountId = @"94c82516-cbee-44aa-8a6a-19f8d20322be";
  id msalResultMock = OCMPartialMock([MSALResult new]);
  OCMStub([msalResultMock idToken]).andReturn(idToken);
  OCMStub([msalResultMock uniqueId]).andReturn(accountId);
  self.sut.clientApplication = self.clientApplicationMock;
  self.sut.identityConfig = [MSIdentityConfig new];
  self.sut.identityConfig.identityScope = @"fake";
  id identityMock = OCMPartialMock(self.sut);
  OCMStub([identityMock sharedInstance]).andReturn(identityMock);
  OCMStub([identityMock canBeUsed]).andReturn(YES);
  OCMStub([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __block MSALCompletionBlock completionBlock;
    [invocation getArgument:&completionBlock atIndex:3];
    self.msalCompletionBlock = completionBlock;
  });

  // When we make a first call
  MSSignInCompletionHandler handler1 = ^(MSUserInformation *_Nullable userInformation, NSError *_Nullable error) {
    self.signInUserInformation = userInformation;
    self.signInError = error;
  };
  [MSIdentity signInWithCompletionHandler:handler1];

  // And we make a second call before the first complete
  MSSignInCompletionHandler handler2 = ^(MSUserInformation *_Nullable userInformation, NSError *_Nullable error) {
    self.signInUserInformation = userInformation;
    self.signInError = error;
  };
  [MSIdentity signInWithCompletionHandler:handler2];

  // Then second call immediately fails
  XCTAssertNil(self.signInUserInformation);
  XCTAssertNotNil(self.signInError);
  XCTAssertEqualObjects(MSIdentityErrorDomain, self.signInError.domain);
  XCTAssertEqual(MSIdentityErrorPreviousSignInRequestInProgress, self.signInError.code);
  XCTAssertNotNil(self.signInError.userInfo[MSIdentityErrorDescriptionKey]);

  // When we complete first call
  self.msalCompletionBlock(msalResultMock, nil);

  // Then
  OCMVerify([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]);
  XCTAssertEqualObjects(idToken, [MSAuthTokenContext sharedInstance].authToken);
  XCTAssertEqualObjects(idToken, [MSMockKeychainUtil stringForKey:kMSIdentityAuthTokenKey]);
  XCTAssertNotNil(self.signInUserInformation);
  XCTAssertEqualObjects(accountId, self.signInUserInformation.accountId);
  XCTAssertNil(self.signInError);
  [identityMock stopMocking];
}

- (void)testSignInError {

  // If
  NSError *signInError = [[NSError alloc] initWithDomain:MSALErrorDomain
                                                    code:MSALErrorAuthorizationFailed
                                                userInfo:@{MSALErrorDescriptionKey : @"failed"}];
  self.sut.clientApplication = self.clientApplicationMock;
  self.sut.identityConfig = [MSIdentityConfig new];
  self.sut.identityConfig.identityScope = @"fake";
  id identityMock = OCMPartialMock(self.sut);
  OCMStub([identityMock sharedInstance]).andReturn(identityMock);
  OCMStub([identityMock canBeUsed]).andReturn(YES);
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
  [MSIdentity signInWithCompletionHandler:handler];

  // Then
  OCMVerify([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]);
  XCTAssertNil(self.signInUserInformation);
  XCTAssertNotNil(self.signInError);
  XCTAssertEqualObjects(MSALErrorDomain, self.signInError.domain);
  XCTAssertEqual(MSALErrorAuthorizationFailed, self.signInError.code);
  XCTAssertNotNil(self.signInError.userInfo[MSALErrorDescriptionKey]);
  [identityMock stopMocking];
}

- (void)testSignInCancelled {

  // If
  NSError *signInError = [[NSError alloc] initWithDomain:MSALErrorDomain
                                                    code:MSALErrorUserCanceled
                                                userInfo:@{MSALErrorDescriptionKey : @"cancelled"}];
  self.sut.clientApplication = self.clientApplicationMock;
  self.sut.identityConfig = [MSIdentityConfig new];
  self.sut.identityConfig.identityScope = @"fake";
  id identityMock = OCMPartialMock(self.sut);
  OCMStub([identityMock sharedInstance]).andReturn(identityMock);
  OCMStub([identityMock canBeUsed]).andReturn(YES);
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
  [MSIdentity signInWithCompletionHandler:handler];

  // Then
  OCMVerify([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]);
  XCTAssertNil(self.signInUserInformation);
  XCTAssertNotNil(self.signInError);
  XCTAssertEqualObjects(MSALErrorDomain, self.signInError.domain);
  XCTAssertEqual(MSALErrorUserCanceled, self.signInError.code);
  XCTAssertNotNil(self.signInError.userInfo[MSALErrorDescriptionKey]);
  [identityMock stopMocking];
}

- (void)testSignInFailsAfterDisablingEvenIfBrowserWasOpenedAndSignInSucceeds {

  // If
  NSString *idToken = @"idToken";
  NSString *accountId = @"94c82516-cbee-44aa-8a6a-19f8d20322be";
  id msalResultMock = OCMPartialMock([MSALResult new]);
  OCMStub([msalResultMock idToken]).andReturn(idToken);
  OCMStub([msalResultMock uniqueId]).andReturn(accountId);
  self.sut.clientApplication = self.clientApplicationMock;
  self.sut.identityConfig = [MSIdentityConfig new];
  self.sut.identityConfig.identityScope = @"fake";
  id identityMock = OCMPartialMock(self.sut);
  OCMStub([identityMock sharedInstance]).andReturn(identityMock);
  OCMStub([identityMock canBeUsed]).andReturn(YES);
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
  [MSIdentity signInWithCompletionHandler:handler];
  [self.sut setEnabled:NO];
  self.msalCompletionBlock(msalResultMock, nil);

  // Then
  OCMVerify([self.clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]);
  XCTAssertNil(self.signInUserInformation);
  XCTAssertNotNil(self.signInError);
  XCTAssertEqualObjects(MSIdentityErrorDomain, self.signInError.domain);
  XCTAssertEqual(MSIdentityErrorServiceDisabled, self.signInError.code);
  XCTAssertNotNil(self.signInError.userInfo[MSIdentityErrorDescriptionKey]);
  [identityMock stopMocking];
}

- (void)testSignOutInvokesDelegatesWithNilToken {

  // If
  [[MSAuthTokenContext sharedInstance] setAuthToken:@"someToken" withAccountId:@"someAccount"];
  id<MSAuthTokenContextDelegate> mockDelegate = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [[MSAuthTokenContext sharedInstance] addDelegate:mockDelegate];
  id identityMock = OCMPartialMock(self.sut);
  OCMStub([identityMock sharedInstance]).andReturn(identityMock);
  OCMStub([identityMock canBeUsed]).andReturn(YES);

  // When
  [MSIdentity signOut];

  // Then
  OCMVerify([mockDelegate authTokenContext:OCMOCK_ANY didSetNewAuthToken:nil]);
  OCMVerify([mockDelegate authTokenContext:OCMOCK_ANY didSetNewAccountIdWithAuthToken:nil]);
  [identityMock stopMocking];
}

- (void)testSignOutRemovesAccountFromMSAL {

  // If
  NSString *accountId = @"someAccount";
  [[MSAuthTokenContext sharedInstance] setAuthToken:@"someToken" withAccountId:accountId];
  [self.settingsMock setObject:accountId forKey:kMSIdentityMSALAccountHomeAccountKey];
  id accountMock = OCMPartialMock([MSALAccount new]);
  self.sut.clientApplication = self.clientApplicationMock;
  OCMStub([self.clientApplicationMock accountForHomeAccountId:accountId error:[OCMArg anyObjectRef]]).andReturn(accountMock);
  id identityMock = OCMPartialMock(self.sut);
  OCMStub([identityMock sharedInstance]).andReturn(identityMock);
  OCMStub([identityMock canBeUsed]).andReturn(YES);

  // When
  [MSIdentity signOut];

  // Then
  OCMVerify([identityMock removeAccount]);
  OCMVerify([self.clientApplicationMock removeAccount:OCMOCK_ANY error:[OCMArg anyObjectRef]]);
  [identityMock stopMocking];
}

- (void)testSignOutShouldNotRemoveAccountFromMSALIfNotConfigured {

  // If
  NSString *accountId = @"someAccount";
  [[MSAuthTokenContext sharedInstance] setAuthToken:@"someToken" withAccountId:accountId];
  id identityMock = OCMPartialMock(self.sut);
  OCMStub([identityMock sharedInstance]).andReturn(identityMock);
  OCMStub([identityMock canBeUsed]).andReturn(YES);

  // Then
  OCMReject([self.clientApplicationMock removeAccount:OCMOCK_ANY error:[OCMArg anyObjectRef]]);

  // When
  [MSIdentity signOut];
  XCTAssertFalse([self.sut removeAccount]);

  // Then
  XCTAssertNil(self.sut.clientApplication);
  [identityMock stopMocking];
}

- (void)testSignOutShouldNotRemoveAccountFromMSALIfNoAccount {

  // If
  NSString *accountId = @"someAccount";
  [[MSAuthTokenContext sharedInstance] setAuthToken:@"someToken" withAccountId:accountId];
  self.sut.clientApplication = self.clientApplicationMock;
  id identityMock = OCMPartialMock(self.sut);
  OCMStub([identityMock sharedInstance]).andReturn(identityMock);
  OCMStub([identityMock canBeUsed]).andReturn(YES);

  // Then
  OCMReject([self.clientApplicationMock removeAccount:OCMOCK_ANY error:[OCMArg anyObjectRef]]);

  // When
  [MSIdentity signOut];
  XCTAssertTrue([self.sut removeAccount]);

  // Then
  XCTAssertNil([self.settingsMock objectForKey:kMSIdentityMSALAccountHomeAccountKey]);
  [identityMock stopMocking];
}

- (void)testSignOutClearsAuthTokenAndAccountId {

  // If
  [[MSAuthTokenContext sharedInstance] setAuthToken:@"someToken" withAccountId:@"someAccount"];
  [MSMockKeychainUtil storeString:@"someToken" forKey:kMSIdentityAuthTokenKey];
  [self.settingsMock setObject:@"someAccount" forKey:kMSIdentityMSALAccountHomeAccountKey];
  id identityMock = OCMPartialMock(self.sut);
  OCMStub([identityMock sharedInstance]).andReturn(identityMock);
  OCMStub([identityMock canBeUsed]).andReturn(YES);

  // When
  [MSIdentity signOut];

  // Then
  OCMVerify([identityMock removeAuthToken]);
  OCMVerify([identityMock removeAccountId]);
  XCTAssertNil([MSMockKeychainUtil stringForKey:kMSIdentityAuthTokenKey]);
  XCTAssertNil([self.settingsMock objectForKey:kMSIdentityMSALAccountHomeAccountKey]);
  [identityMock stopMocking];
}

- (void)testRemoveAuthToken {

  // If
  [MSMockKeychainUtil storeString:@"someToken" forKey:kMSIdentityAuthTokenKey];

  // When
  XCTAssertTrue([self.sut removeAuthToken]);
  XCTAssertFalse([self.sut removeAuthToken]);
}

- (void)testSignOutDoesNothingWhenNotSignedIn {

  // If
  id<MSAuthTokenContextDelegate> mockDelegate = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [[MSAuthTokenContext sharedInstance] addDelegate:mockDelegate];
  id identityMock = OCMPartialMock(self.sut);
  OCMStub([identityMock sharedInstance]).andReturn(identityMock);
  OCMStub([identityMock canBeUsed]).andReturn(YES);

  // Then
  OCMReject([mockDelegate authTokenContext:OCMOCK_ANY didSetNewAuthToken:OCMOCK_ANY]);
  OCMReject([identityMock removeAccount]);
  OCMReject([identityMock removeAuthToken]);
  OCMReject([identityMock removeAccountId]);

  // When
  [MSIdentity signOut];

  // Then
  XCTAssertNil([[MSAuthTokenContext sharedInstance] authToken]);
  [identityMock stopMocking];
}

- (void)testSignOutDoesNothingWhenDisabled {

  // If
  NSString *authToken = @"someToken";
  NSString *accountId = @"someAccount";
  [[MSAuthTokenContext sharedInstance] setAuthToken:authToken withAccountId:accountId];
  [MSMockKeychainUtil storeString:authToken forKey:kMSIdentityAuthTokenKey];
  [self.settingsMock setObject:accountId forKey:kMSIdentityMSALAccountHomeAccountKey];
  id identityMock = OCMPartialMock(self.sut);
  OCMStub([identityMock sharedInstance]).andReturn(identityMock);
  OCMStub([identityMock canBeUsed]).andReturn(NO);

  // When
  [MSIdentity signOut];

  // Then
  XCTAssertEqualObjects([[MSAuthTokenContext sharedInstance] authToken], authToken);
  XCTAssertEqualObjects([MSMockKeychainUtil stringForKey:kMSIdentityAuthTokenKey], authToken);
  XCTAssertEqualObjects([self.settingsMock objectForKey:kMSIdentityMSALAccountHomeAccountKey], accountId);
  [identityMock stopMocking];
}

- (void)testDefaultConfigUrl {

  // When
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                        appSecret:kMSTestAppSecret
          transmissionTargetToken:nil
                  fromApplication:YES];

  // Then
  XCTAssertNotNil(self.sut.ingestion);
  XCTAssertEqualObjects(self.sut.ingestion.baseURL, kMSIdentityDefaultBaseURL);
}

- (void)testConfigURLIsPassedToIngestionWhenSetBeforeServiceStart {

  // If
  NSString *baseConfigUrl = @"https://baseconfigurl.com";

  // When
  [MSIdentity setConfigUrl:baseConfigUrl];
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                        appSecret:kMSTestAppSecret
          transmissionTargetToken:nil
                  fromApplication:YES];

  // Then
  XCTAssertNotNil(self.sut.ingestion);
  XCTAssertEqualObjects(self.sut.ingestion.baseURL, baseConfigUrl);
}

@end
