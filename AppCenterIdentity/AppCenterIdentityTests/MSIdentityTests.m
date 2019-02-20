#import <Foundation/Foundation.h>

#import "MSAuthTokenContext.h"
#import "MSAuthTokenContextDelegate.h"
#import "MSChannelGroupProtocol.h"
#import "MSChannelUnitProtocol.h"
#import "MSHttpTestUtil.h"
#import "MSIdentity.h"
#import "MSIdentityConfigIngestion.h"
#import "MSIdentityPrivate.h"
#import "MSMockKeychainUtil.h"
#import "MSMockUserDefaults.h"
#import "MSServiceAbstractProtected.h"
#import "MSTestFrameworks.h"
#import "MSUtility+File.h"
#import <MSAL/MSAL.h>
#import <MSAL/MSALPublicClientApplication.h>

static NSString *const kMSTestAppSecret = @"TestAppSecret";

@interface MSIdentityTests : XCTestCase

@property(nonatomic) MSIdentity *sut;
@property(nonatomic) MSMockUserDefaults *settingsMock;
@property(nonatomic) NSDictionary *dummyConfigDic;
@property(nonatomic) id utilityMock;
@property(nonatomic) id keychainUtilMock;

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
  self.sut = [MSIdentity new];
  self.keychainUtilMock = [MSMockKeychainUtil new];
}

- (void)tearDown {
  [super tearDown];
  [MSIdentity resetSharedInstance];
  [MSAuthTokenContext resetSharedInstance];
  [self.settingsMock stopMocking];
  [self.utilityMock stopMocking];
  [self.keychainUtilMock stopMocking];
}

- (void)testApplyEnabledStateWorks {

  // If
  [[MSIdentity sharedInstance] startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                                           appSecret:kMSTestAppSecret
                             transmissionTargetToken:nil
                                     fromApplication:YES];
  MSServiceAbstract *service = (MSServiceAbstract *)[MSIdentity sharedInstance];

  // When
  [service setEnabled:YES];

  // Then
  XCTAssertTrue([service isEnabled]);

  // When
  [service setEnabled:NO];

  // Then
  XCTAssertFalse([service isEnabled]);

  // When
  [service setEnabled:YES];

  // Then
  XCTAssertTrue([service isEnabled]);
}

- (void)testLoadAndDownloadOnEnabling {

  // If
  MSIdentity *service = [MSIdentity sharedInstance];
  NSString *expectedETag = @"eTag";
  [self.settingsMock setObject:expectedETag forKey:kMSIdentityETagKey];
  NSData *serializedConfig = [NSJSONSerialization dataWithJSONObject:self.dummyConfigDic options:(NSJSONWritingOptions)0 error:nil];
  OCMStub([self.utilityMock loadDataForPathComponent:[service identityConfigFilePath]]).andReturn(serializedConfig);
  id ingestionMock = OCMPartialMock([MSIdentityConfigIngestion alloc]);
  OCMStub([ingestionMock alloc]).andReturn(ingestionMock);
  OCMStub([ingestionMock sendAsync:OCMOCK_ANY eTag:OCMOCK_ANY completionHandler:OCMOCK_ANY]);

  // When
  [service applyEnabledState:YES];

  // Then
  XCTAssertTrue([service.identityConfig isValid]);
  OCMVerify([ingestionMock sendAsync:nil eTag:expectedETag completionHandler:OCMOCK_ANY]);
  [ingestionMock stopMocking];
}

- (void)testEnablingReadsAuthTokenFromKeychainAndSetsAuthContext {
  
  // If
  MSIdentity *service = [MSIdentity sharedInstance];
  NSString *expectedToken = @"expected";
  [MSMockKeychainUtil storeString: expectedToken forKey:kMSIdentityAuthTokenKey];
  NSString *expectedETag = @"eTag";
  [self.settingsMock setObject:expectedETag forKey:kMSIdentityETagKey];
  NSData *serializedConfig = [NSJSONSerialization dataWithJSONObject:self.dummyConfigDic options:(NSJSONWritingOptions)0 error:nil];
  OCMStub([self.utilityMock loadDataForPathComponent:[service identityConfigFilePath]]).andReturn(serializedConfig);
  id ingestionMock = OCMPartialMock([MSIdentityConfigIngestion alloc]);
  OCMStub([ingestionMock alloc]).andReturn(ingestionMock);
  OCMStub([ingestionMock sendAsync:OCMOCK_ANY eTag:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
  
  // When
  [service applyEnabledState:YES];
  
  // Then
  XCTAssertEqual([MSAuthTokenContext sharedInstance].authToken, expectedToken);
  [ingestionMock stopMocking];
}

- (void)testEnablingReadsAuthTokenFromKeychainAndDoesNotSetAuthContextIfNil {

  // If
  MSIdentity *service = [MSIdentity sharedInstance];
  NSString *expectedETag = @"eTag";
  [self.settingsMock setObject:expectedETag forKey:kMSIdentityETagKey];
  NSData *serializedConfig = [NSJSONSerialization dataWithJSONObject:self.dummyConfigDic options:(NSJSONWritingOptions)0 error:nil];
  OCMStub([self.utilityMock loadDataForPathComponent:[service identityConfigFilePath]]).andReturn(serializedConfig);
  id<MSAuthTokenContextDelegate> mockDelegate = OCMProtocolMock(@protocol(MSAuthTokenContextDelegate));
  [[MSAuthTokenContext sharedInstance] addDelegate:mockDelegate];
  id ingestionMock = OCMPartialMock([MSIdentityConfigIngestion alloc]);
  OCMStub([ingestionMock alloc]).andReturn(ingestionMock);
  OCMStub([ingestionMock sendAsync:OCMOCK_ANY eTag:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
  
  // Then
  OCMReject([mockDelegate authTokenContext:OCMOCK_ANY didReceiveAuthToken:OCMOCK_ANY]);

  // When
  [service applyEnabledState:YES];
  [ingestionMock stopMocking];
}

- (void)testCleanUpOnDisabling {

  // If
  MSIdentity *service = [MSIdentity sharedInstance];
  NSData *serializedConfig = [NSJSONSerialization dataWithJSONObject:self.dummyConfigDic options:(NSJSONWritingOptions)0 error:nil];
  OCMStub([self.utilityMock loadDataForPathComponent:[service identityConfigFilePath]]).andReturn(serializedConfig);
  [self.settingsMock setObject:@"eTag" forKey:kMSIdentityETagKey];
  [[MSIdentity sharedInstance] startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                                           appSecret:kMSTestAppSecret
                             transmissionTargetToken:nil
                                     fromApplication:YES];
  [MSMockKeychainUtil storeString:@"foobar" forKey:kMSIdentityAuthTokenKey];
  [MSAuthTokenContext sharedInstance].authToken = @"some token";
  [service setEnabled:YES];

  // When
  [service setEnabled:NO];

  // Then
  XCTAssertNil(service.clientApplication);
  XCTAssertNil([MSAuthTokenContext sharedInstance].authToken);
  XCTAssertNil([MSMockKeychainUtil stringForKey:kMSIdentityAuthTokenKey]);
  OCMVerify([self.utilityMock deleteItemForPathComponent:[service identityConfigFilePath]]);
  XCTAssertNil([self.settingsMock objectForKey:kMSIdentityETagKey]);
}

- (void)testCacheNewConfigWhenNoConfig {

  // If
  __block MSSendAsyncCompletionHandler ingestionBlock;
  NSString *expectedETag = @"newETag";
  NSData *newConfig = [NSJSONSerialization dataWithJSONObject:self.dummyConfigDic options:(NSJSONWritingOptions)0 error:nil];
  id ingestionMock = OCMPartialMock([MSIdentityConfigIngestion alloc]);
  OCMStub([ingestionMock alloc]).andReturn(ingestionMock);
  OCMStub([ingestionMock sendAsync:nil eTag:nil completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    // Get ingestion block for later call.
    [invocation retainArguments];
    [invocation getArgument:&ingestionBlock atIndex:4];
  });
  MSIdentity *service = [MSIdentity sharedInstance];

  // When
  [service downloadConfigurationWithETag:nil];
  ingestionBlock(@"callId", [MSHttpTestUtil createMockResponseForStatusCode:200 headers:@{kMSETagResponseHeader : expectedETag}], newConfig,
                 nil);

  // Then
  OCMVerify([self.utilityMock createFileAtPathComponent:[service identityConfigFilePath]
                                               withData:newConfig
                                             atomically:YES
                                         forceOverwrite:YES]);
  XCTAssertEqualObjects(expectedETag, [self.settingsMock objectForKey:kMSIdentityETagKey]);
  [ingestionMock stopMocking];
}

- (void)testCacheNewConfigWhenDeprecatedConfigIsCached {

  // If
  __block MSSendAsyncCompletionHandler ingestionBlock;
  NSString *oldETag = @"oldETag";
  NSString *expectedETag = @"newETag";
  [self.settingsMock setObject:oldETag forKey:kMSIdentityETagKey];
  NSData *newConfig = [NSJSONSerialization dataWithJSONObject:self.dummyConfigDic options:(NSJSONWritingOptions)0 error:nil];
  id ingestionMock = OCMPartialMock([MSIdentityConfigIngestion alloc]);
  OCMStub([ingestionMock alloc]).andReturn(ingestionMock);
  OCMStub([ingestionMock sendAsync:nil eTag:oldETag completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    // Get ingestion block for later call.
    [invocation retainArguments];
    [invocation getArgument:&ingestionBlock atIndex:4];
  });
  MSIdentity *service = [MSIdentity sharedInstance];

  // When
  [service downloadConfigurationWithETag:oldETag];
  ingestionBlock(@"callId", [MSHttpTestUtil createMockResponseForStatusCode:200 headers:@{kMSETagResponseHeader : expectedETag}], newConfig,
                 nil);

  // Then
  OCMVerify([self.utilityMock createFileAtPathComponent:[service identityConfigFilePath]
                                               withData:newConfig
                                             atomically:YES
                                         forceOverwrite:YES]);
  XCTAssertEqualObjects(expectedETag, [self.settingsMock objectForKey:kMSIdentityETagKey]);
  [ingestionMock stopMocking];
}

- (void)testDontCacheConfigWhenCachedConfigIsNotDeprecated {

  // If
  __block MSSendAsyncCompletionHandler ingestionBlock;
  NSString *expectedETag = @"eTag";
  NSData *expectedConfig = [NSJSONSerialization dataWithJSONObject:self.dummyConfigDic options:(NSJSONWritingOptions)0 error:nil];
  id ingestionMock = OCMPartialMock([MSIdentityConfigIngestion alloc]);
  OCMStub([ingestionMock alloc]).andReturn(ingestionMock);
  OCMStub([ingestionMock sendAsync:nil eTag:expectedETag completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    // Get ingestion block for later call.
    [invocation retainArguments];
    [invocation getArgument:&ingestionBlock atIndex:4];
  });
  MSIdentity *service = [MSIdentity sharedInstance];
  OCMReject([self.utilityMock createFileAtPathComponent:[service identityConfigFilePath]
                                               withData:OCMOCK_ANY
                                             atomically:OCMOCK_ANY
                                         forceOverwrite:OCMOCK_ANY]);
  OCMReject([self.settingsMock setObject:OCMOCK_ANY forKey:kMSIdentityETagKey]);

  // When
  [service downloadConfigurationWithETag:expectedETag];
  ingestionBlock(@"callId", [MSHttpTestUtil createMockResponseForStatusCode:304 headers:nil], expectedConfig, nil);

  // Then
  [ingestionMock stopMocking];
}

- (void)testDontCacheConfigWhenReceivedUnexpectedStatusCode {

  // If
  __block MSSendAsyncCompletionHandler ingestionBlock;
  NSString *expectedETag = @"eTag";
  NSData *expectedConfig = [NSJSONSerialization dataWithJSONObject:self.dummyConfigDic options:(NSJSONWritingOptions)0 error:nil];
  id ingestionMock = OCMPartialMock([MSIdentityConfigIngestion alloc]);
  OCMStub([ingestionMock alloc]).andReturn(ingestionMock);
  OCMStub([ingestionMock sendAsync:nil eTag:expectedETag completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    // Get ingestion block for later call.
    [invocation retainArguments];
    [invocation getArgument:&ingestionBlock atIndex:4];
  });
  MSIdentity *service = [MSIdentity sharedInstance];
  OCMReject([self.utilityMock createFileAtPathComponent:[service identityConfigFilePath]
                                               withData:OCMOCK_ANY
                                             atomically:OCMOCK_ANY
                                         forceOverwrite:OCMOCK_ANY]);
  OCMReject([self.settingsMock setObject:OCMOCK_ANY forKey:kMSIdentityETagKey]);

  // When
  [service downloadConfigurationWithETag:expectedETag];
  ingestionBlock(@"callId", [MSHttpTestUtil createMockResponseForStatusCode:500 headers:nil], expectedConfig, nil);

  // Then
  [ingestionMock stopMocking];
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
  MSIdentity *service = [MSIdentity sharedInstance];
  service.identityConfig = [MSIdentityConfig new];

  // When
  [service configAuthenticationClient];

  // Then
  XCTAssertNil(service.clientApplication);
}

- (void)testLoadInvalidConfigurationFromCache {

  // If
  NSDictionary *invalidData = @{@"invalid" : @"data"};
  NSData *serializedConfig = [NSJSONSerialization dataWithJSONObject:invalidData options:(NSJSONWritingOptions)0 error:nil];
  MSIdentity *service = [MSIdentity sharedInstance];
  OCMStub([self.utilityMock loadDataForPathComponent:[service identityConfigFilePath]]).andReturn(serializedConfig);
  [self.settingsMock setObject:@"eTag" forKey:kMSIdentityETagKey];

  // When
  BOOL loaded = [service loadConfigurationFromCache];

  // Then
  XCTAssertFalse(loaded);
  OCMVerify([self.utilityMock deleteItemForPathComponent:[service identityConfigFilePath]]);
  XCTAssertNil([self.settingsMock objectForKey:kMSIdentityETagKey]);
}

- (void)testNotCacheInvalidConfig {

  // If
  __block MSSendAsyncCompletionHandler ingestionBlock;
  NSString *oldETag = @"oldETag";
  NSString *expectedETag = @"newETag";
  [self.settingsMock setObject:oldETag forKey:kMSIdentityETagKey];
  NSData *invalidConfig = [NSJSONSerialization dataWithJSONObject:@{} options:(NSJSONWritingOptions)0 error:nil];
  id ingestionMock = OCMPartialMock([MSIdentityConfigIngestion alloc]);
  OCMStub([ingestionMock alloc]).andReturn(ingestionMock);
  OCMStub([ingestionMock sendAsync:nil eTag:oldETag completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
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
  [ingestionMock stopMocking];
}

- (void)testNotCacheInvalidData {

  // If
  __block MSSendAsyncCompletionHandler ingestionBlock;
  NSString *oldETag = @"oldETag";
  NSString *expectedETag = @"newETag";
  [self.settingsMock setObject:oldETag forKey:kMSIdentityETagKey];
  NSData *invalidData = [@"InvalidData" dataUsingEncoding:NSUTF8StringEncoding];
  id ingestionMock = OCMPartialMock([MSIdentityConfigIngestion alloc]);
  OCMStub([ingestionMock alloc]).andReturn(ingestionMock);
  OCMStub([ingestionMock sendAsync:nil eTag:oldETag completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    // Get ingestion block for later call.
    [invocation retainArguments];
    [invocation getArgument:&ingestionBlock atIndex:4];
  });
  MSIdentity *service = (MSIdentity *)[MSIdentity sharedInstance];

  // When
  [service downloadConfigurationWithETag:oldETag];
  ingestionBlock(@"callId", [MSHttpTestUtil createMockResponseForStatusCode:200 headers:@{kMSETagResponseHeader : expectedETag}],
                 invalidData, nil);

  // Then
  OCMReject([self.utilityMock createFileAtPathComponent:[service identityConfigFilePath]
                                               withData:OCMOCK_ANY
                                             atomically:YES
                                         forceOverwrite:YES]);
  XCTAssertEqualObjects(oldETag, [self.settingsMock objectForKey:kMSIdentityETagKey]);
  [ingestionMock stopMocking];
}

- (void)testLoginAcquiresAndSavesToken {

  // If
  NSString *idToken = @"fake";
  id msalResultMock = OCMPartialMock([MSALResult new]);
  OCMStub([msalResultMock idToken]).andReturn(idToken);
  MSIdentity *service = [MSIdentity sharedInstance];
  id clientApplicationMock = OCMClassMock([MSALPublicClientApplication class]);
  service.clientApplication = clientApplicationMock;
  service.identityConfig = [MSIdentityConfig new];
  service.identityConfig.identityScope = @"fake";
  id identityMock = OCMPartialMock(service);
  OCMStub([identityMock sharedInstance]).andReturn(identityMock);
  OCMStub([identityMock canBeUsed]).andReturn(YES);
  OCMStub([clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __block MSALCompletionBlock completionBlock;
    [invocation getArgument:&completionBlock atIndex:3];
    completionBlock(msalResultMock, nil);
  });

  // When
  [MSIdentity login];

  // Then
  OCMVerify([clientApplicationMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]);
  XCTAssertEqual(idToken, [MSAuthTokenContext sharedInstance].authToken);
  XCTAssertEqual(idToken, [MSMockKeychainUtil stringForKey:kMSIdentityAuthTokenKey]);
  [identityMock stopMocking];
  [clientApplicationMock stopMocking];
}

- (void)testLoginDoesNotAcquireTokenWhenDisabled {

  // If
  id identityMock = OCMPartialMock([MSIdentity sharedInstance]);
  OCMStub([identityMock sharedInstance]).andReturn(identityMock);
  OCMStub([identityMock canBeUsed]).andReturn(NO);
  id msalMock = OCMClassMock([MSALPublicClientApplication class]);
  OCMStub([msalMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]).andDo(nil);

  // When
  [MSIdentity login];

  // Then
  OCMReject([msalMock acquireTokenForScopes:OCMOCK_ANY completionBlock:OCMOCK_ANY]);
  [identityMock stopMocking];
  [msalMock stopMocking];
}

- (void)testLoginDelayedWhenNoClientApplication {

  // If
  MSIdentity *service = [MSIdentity sharedInstance];
  service.identityConfig = [MSIdentityConfig new];
  service.identityConfig.identityScope = @"fake";
  id identityMock = OCMPartialMock(service);
  OCMStub([identityMock sharedInstance]).andReturn(identityMock);
  OCMStub([identityMock canBeUsed]).andReturn(YES);

  // When
  [MSIdentity login];

  // Then
  XCTAssertTrue(service.loginDelayed);
  [identityMock stopMocking];
}

- (void)testLoginDelayedWhenNoIdentityConfig {

  // If
  MSIdentity *service = [MSIdentity sharedInstance];
  id clientApplicationMock = OCMPartialMock([MSALPublicClientApplication alloc]);
  service.clientApplication = clientApplicationMock;
  id identityMock = OCMPartialMock(service);
  OCMStub([identityMock sharedInstance]).andReturn(identityMock);
  OCMStub([identityMock canBeUsed]).andReturn(YES);

  // When
  [MSIdentity login];

  // Then
  XCTAssertTrue(service.loginDelayed);
  [identityMock stopMocking];
  [clientApplicationMock stopMocking];
}

@end
