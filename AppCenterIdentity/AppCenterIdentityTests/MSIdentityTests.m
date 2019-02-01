#import <Foundation/Foundation.h>

#import "MSChannelGroupProtocol.h"
#import "MSChannelUnitProtocol.h"
#import "MSHttpTestUtil.h"
#import "MSIdentity.h"
#import "MSIdentityConfigIngestion.h"
#import "MSIdentityPrivate.h"
#import "MSMockUserDefaults.h"
#import "MSServiceAbstractProtected.h"
#import "MSTestFrameworks.h"
#import "MSUtility+File.h"
#import <MSAL/MSALPublicClientApplication.h>

static NSString *const kMSTestAppSecret = @"TestAppSecret";

@interface MSIdentityTests : XCTestCase

@property(nonatomic) MSIdentity *sut;
@property(nonatomic) MSMockUserDefaults *settingsMock;
@property(nonatomic) NSDictionary *dummyConfigDic;
@property(nonatomic) id utilityMock;

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

  // When
  self.sut = [MSIdentity new];
}

- (void)tearDown {
  [super tearDown];
  [MSIdentity resetSharedInstance];
  [self.settingsMock stopMocking];
  [self.utilityMock stopMocking];
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

  // When
  [service applyEnabledState:YES];

  // Then
  XCTAssertTrue([service.identityConfig isValid]);
  OCMVerify([ingestionMock sendAsync:nil eTag:expectedETag completionHandler:OCMOCK_ANY]);
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
  [service setEnabled:YES];

  // When
  [service setEnabled:NO];

  // Then
  XCTAssertNil(service.clientApplication);
  XCTAssertNil(service.accessToken);
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
  [MSIdentity handleUrlResponse:expectedURL];

  // Then
  OCMVerify([msalMock handleMSALResponse:expectedURL]);
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

// TODO add tests to cover login.

@end
