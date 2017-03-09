#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSBasicMachOParser.h"
#import "MSDistribute.h"
#import "MSDistributeInternal.h"
#import "MSDistributePrivate.h"
#import "MSKeychainUtil.h"
#import "MSLogManager.h"
#import "MSMobileCenter.h"
#import "MSServiceAbstract.h"
#import "MSServiceAbstractProtected.h"
#import "MSServiceInternal.h"
#import "MSUserDefaults.h"
#import "MSUtil.h"

static NSString *const kMSTestAppSecret = @"IAMSECRET";

// Mocked SFSafariViewController for url validation.
@interface SFSafariViewController : UIViewController

@property(class, nonatomic) NSURL *url;

- (instancetype)initWithURL:(NSURL *)url;

@end

static NSURL *sfURL;

@implementation SFSafariViewController

- (instancetype)initWithURL:(NSURL *)url {
  if ((self = [super init])) {
    [[self class] setUrl:url];
  }
  return self;
}
+ (NSURL *)url {
  return sfURL;
}

+ (void)setUrl:(NSURL *)url {
  sfURL = url;
}
@end

static NSURL *sfURL;

@interface MSDistributeTests : XCTestCase

@property(nonatomic, strong) MSDistribute *sut;
@property(nonatomic, strong) id parserMock;

@end

@implementation MSDistributeTests

- (void)setUp {
  [super setUp];
  
  self.sut = [MSDistribute new];

  [MS_USER_DEFAULTS removeObjectForKey:kMSUpdateTokenRequestIdKey];
  [MS_USER_DEFAULTS removeObjectForKey:kMSIgnoredReleaseIdKey];
  [MSKeychainUtil clear];

  // TODO: Add unit tests for MSBasicMachOParser.
  // FIXME: MSBasicMachOParser don't work on test projects. It's mocked for now to not fail other tests.
  id parserMock = OCMClassMock([MSBasicMachOParser class]);
  self.parserMock = parserMock;
  OCMStub([parserMock machOParserForMainBundle]).andReturn(self.parserMock);
  OCMStub([self.parserMock uuid])
      .andReturn([[NSUUID alloc] initWithUUIDString:@"CD55E7A9-7AD1-4CA6-B722-3D133F487DA9"]);
}

- (void)tearDown {
  [super tearDown];
  [MS_USER_DEFAULTS removeObjectForKey:kMSUpdateTokenRequestIdKey];
  [MS_USER_DEFAULTS removeObjectForKey:kMSIgnoredReleaseIdKey];
  [MSKeychainUtil clear];
  [self.parserMock stopMocking];
}

- (void)testUpdateURL {

  // If
  NSArray *bundleArray = @[
    @{ @"CFBundleURLSchemes" : @[ [NSString stringWithFormat:@"mobilecenter-%@", kMSTestAppSecret] ] }
  ];
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);
  OCMStub([bundleMock objectForInfoDictionaryKey:@"CFBundleURLTypes"]).andReturn(bundleArray);
  OCMStub([bundleMock objectForInfoDictionaryKey:@"MSAppName"]).andReturn(@"Something");
  id distributeMock = OCMPartialMock(self.sut);

  // Disable for now to bypass initializing sender.
  [distributeMock setEnabled:NO];
  [distributeMock startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];

  // Enable again.
  [distributeMock setEnabled:YES];

  // When
  NSURL *url = [distributeMock buildTokenRequestURLWithAppSecret:kMSTestAppSecret];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
  NSMutableDictionary<NSString *, NSString *> *queryStrings = [NSMutableDictionary<NSString *, NSString *> new];
  [components.queryItems
      enumerateObjectsUsingBlock:^(__kindof NSURLQueryItem *_Nonnull queryItem, NSUInteger idx, BOOL *_Nonnull stop) {
        if (queryItem.value) {
          [queryStrings setObject:(NSString * _Nonnull)queryItem.value forKey:queryItem.name];
        }
      }];

  // Then
  assertThat(url, notNilValue());
  assertThatLong(queryStrings.count, equalToLong(4));
  assertThatBool([components.path containsString:kMSTestAppSecret], isTrue());
  assertThat(queryStrings[kMSURLQueryPlatformKey], is(kMSURLQueryPlatformValue));
  assertThat(queryStrings[kMSURLQueryRedirectIdKey],
             is([NSString stringWithFormat:kMSDefaultCustomSchemeFormat, kMSTestAppSecret]));
  assertThat(queryStrings[kMSURLQueryRequestIdKey], notNilValue());
  assertThat(queryStrings[kMSURLQueryReleaseHashKey], notNilValue());
}

- (void)testMalformedUpdateURL {

  // If
  NSString *badAppSecret = @"weird\\app\\secret";
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn([NSBundle bundleForClass:[self class]]);

  // When
  NSURL *url = [self.sut buildTokenRequestURLWithAppSecret:badAppSecret];

  assertThat(url, nilValue());
}

- (void)testOpenURLInSafariApp {

  // If
  NSURL *url = [NSURL URLWithString:@"https://contoso.com"];
  id appMock = OCMClassMock([UIApplication class]);
  OCMStub([appMock sharedApplication]).andReturn(appMock);
  OCMStub([appMock canOpenURL:url]).andReturn(YES);
  OCMStub([appMock openURL:url]).andDo(nil);

  // When
  [self.sut openURLInSafariApp:url];

  // Then
  OCMVerify([appMock openURL:url]);
}

- (void)testOpenURLInEmbeddedSafari {

  // If
  NSURL *url = [NSURL URLWithString:@"https://contoso.com"];

  // When
  @try {
    [self.sut openURLInEmbeddedSafari:url fromClass:[SFSafariViewController class]];
  } @catch (NSException *ex) {

    /**
     * TODO: This is not a UI test so we expect it to fail with NSInternalInconsistencyException exception.
     * Hopefully it doesn't prevent the URL to be set. Maybe introduce UI testing for this case in the future.
     */
  }

  // Then
  assertThat(SFSafariViewController.url, is(url));
}

- (void)testSetApiUrlWorks {

  // When
  NSString *testUrl = @"https://example.com";
  [self.sut setApiUrl:testUrl];

  // Then
  XCTAssertTrue([[self.sut apiUrl] isEqualToString:testUrl]);
}

- (void)testSetInstallUrlWorks {

  // When
  NSString *testUrl = @"https://example.com";
  [self.sut setInstallUrl:testUrl];

  // Then
  XCTAssertTrue([[self.sut installUrl] isEqualToString:testUrl]);
}

- (void)testDefaultInstallUrlWorks {

  // Then
  XCTAssertNotNil([self.sut installUrl]);
  XCTAssertTrue([[self.sut installUrl] isEqualToString:@"http://install.asgard-int.trafficmanager.net"]);
}

- (void)testDefaultApiUrlWorks {

  // Then
  XCTAssertNotNil([self.sut apiUrl]);
  XCTAssertTrue([[self.sut apiUrl] isEqualToString:@"https://asgard-int.trafficmanager.net/api/v0.1"]);
}

- (void)testHandleUpdate {

  // If
  MSReleaseDetails *details = [MSReleaseDetails new];
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock showConfirmationAlert:[OCMArg any]]).andDo(nil);

  // When
  [distributeMock handleUpdate:details];

  // Then
  OCMReject([distributeMock showConfirmationAlert:[OCMArg any]]);

  // If
  details.id = @1;
  details.downloadUrl = [NSURL URLWithString:@"https://contoso.com/valid/url"];

  // When
  [distributeMock handleUpdate:details];

  // Then
  OCMReject([distributeMock showConfirmationAlert:[OCMArg any]]);

  // If
  details.status = @"available";
  details.minOs = @"1000.0";

  // When
  [distributeMock handleUpdate:details];

  // Then
  OCMReject([distributeMock showConfirmationAlert:[OCMArg any]]);

  // If
  details.minOs = @"1.0";
  OCMStub([distributeMock isNewerVersion:[OCMArg any]]).andReturn(NO).andReturn(YES);

  // When
  [distributeMock handleUpdate:details];

  // Then
  OCMReject([distributeMock showConfirmationAlert:[OCMArg any]]);

  // When
  [distributeMock handleUpdate:details];

  // Then
  OCMVerify([distributeMock showConfirmationAlert:[OCMArg any]]);
}

- (void)testOpenUrl {

  // Make sure we disable the debug-mode checks so we can actually test the logic.
  id mobileCenterMock = OCMClassMock([MSMobileCenter class]);
  OCMStub([mobileCenterMock isDebuggerAttached]).andReturn(NO);
  id utilMock = OCMClassMock([MSUtil class]);
  OCMStub([utilMock isRunningInDebugConfiguration]).andReturn(NO);
  OCMStub([utilMock currentAppEnvironment]).andReturn(MSEnvironmentOther);
  
  // If
  NSString *scheme = [NSString stringWithFormat:kMSDefaultCustomSchemeFormat, kMSTestAppSecret];
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock checkLatestRelease:[OCMArg any]]).andDo(nil);

  // Disable for now to bypass initializing sender.
  [distributeMock setEnabled:NO];
  [distributeMock startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];

  // Enable again.
  [distributeMock setEnabled:YES];
  NSURL *url = [NSURL URLWithString:@"invalid://?"];

  // When
  [distributeMock openUrl:url];

  // Then
  OCMReject([distributeMock checkLatestRelease:[OCMArg any]]);

  // If
  url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://?", scheme]];

  // When
  [distributeMock openUrl:url];

  // Then
  OCMReject([distributeMock checkLatestRelease:[OCMArg any]]);

  // If
  url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://?request_id=FIRST-REQUEST", scheme]];

  // When
  [distributeMock openUrl:url];

  // Then
  OCMReject([distributeMock checkLatestRelease:[OCMArg any]]);

  // If
  url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://?request_id=FIRST-REQUEST&update_token=token", scheme]];

  // When
  [distributeMock openUrl:url];

  // Then
  OCMReject([distributeMock checkLatestRelease:[OCMArg any]]);

  // If
  [MS_USER_DEFAULTS setObject:@"FIRST-REQUEST" forKey:kMSUpdateTokenRequestIdKey];
  url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://?request_id=FIRST-REQUEST&update_token=token",
                                                        [NSString stringWithFormat:kMSDefaultCustomSchemeFormat,
                                                                                   @"Invalid-app-secret"]]];

  // When
  [distributeMock openUrl:url];

  // Then
  OCMReject([distributeMock checkLatestRelease:[OCMArg any]]);

  // If
  url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://?request_id=FIRST-REQUEST&update_token=token", scheme]];

  // When
  [distributeMock openUrl:url];

  // Then
  OCMVerify([distributeMock checkLatestRelease:@"token"]);

  // If
  [distributeMock setEnabled:NO];

  // When
  [distributeMock openUrl:url];

  // Then
  OCMReject([distributeMock checkLatestRelease:[OCMArg any]]);
}

- (void)testApplyEnabledStateTrueForDebugConfig {
  [MS_USER_DEFAULTS removeObjectForKey:kMSUpdateTokenRequestIdKey];
  [MS_USER_DEFAULTS removeObjectForKey:kMSIgnoredReleaseIdKey];

  // If
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock checkLatestRelease:[OCMArg any]]).andDo(nil);
  OCMStub([distributeMock requestUpdateToken]).andDo(nil);

  // When
  [distributeMock applyEnabledState:YES];

  // Then
  XCTAssertNil([MS_USER_DEFAULTS objectForKey:kMSUpdateTokenRequestIdKey]);
  XCTAssertNil([MS_USER_DEFAULTS objectForKey:kMSIgnoredReleaseIdKey]);

  // When
  [distributeMock applyEnabledState:NO];

  // Then
  XCTAssertNil([MS_USER_DEFAULTS objectForKey:kMSUpdateTokenRequestIdKey]);
  XCTAssertNil([MS_USER_DEFAULTS objectForKey:kMSIgnoredReleaseIdKey]);
}

- (void)testApplyEnabledStateTrue {
  
  // Make sure we disable the debug-mode checks so we can actually test the logic.
  id mobileCenterMock = OCMClassMock([MSMobileCenter class]);
  OCMStub([mobileCenterMock isDebuggerAttached]).andReturn(NO);
  id utilMock = OCMClassMock([MSUtil class]);
  OCMStub([utilMock isRunningInDebugConfiguration]).andReturn(NO);
  OCMStub([utilMock currentAppEnvironment]).andReturn(MSEnvironmentOther);
  
  // If
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock checkLatestRelease:[OCMArg any]]).andDo(nil);
  OCMStub([distributeMock requestUpdateToken]).andDo(nil);
  
  // When
  [distributeMock applyEnabledState:YES];

  // Then
  XCTAssertTrue([distributeMock checkForUpdatesAllowed]);
  OCMVerify([distributeMock requestUpdateToken]);

  // If
  [MSKeychainUtil storeString:@"UpdateToken" forKey:kMSUpdateTokenKey];

  // When
  [distributeMock applyEnabledState:YES];

  // Then
  OCMVerify([distributeMock checkLatestRelease:[OCMArg any]]);

  // If
  [MS_USER_DEFAULTS setObject:@"RequestID" forKey:kMSUpdateTokenRequestIdKey];
  [MS_USER_DEFAULTS setObject:@"ReleaseID" forKey:kMSIgnoredReleaseIdKey];

  // Then
  XCTAssertNotNil([MS_USER_DEFAULTS objectForKey:kMSUpdateTokenRequestIdKey]);
  XCTAssertNotNil([MS_USER_DEFAULTS objectForKey:kMSIgnoredReleaseIdKey]);

  // When
  [distributeMock applyEnabledState:NO];

  // Then
  XCTAssertNil([MS_USER_DEFAULTS objectForKey:kMSUpdateTokenRequestIdKey]);
  XCTAssertNil([MS_USER_DEFAULTS objectForKey:kMSIgnoredReleaseIdKey]);
}

- (void)testcheckForUpdatesAllConditionsMet {
  
  // If
  id mobileCenterMock = OCMClassMock([MSMobileCenter class]);
  id utilMock = OCMClassMock([MSUtil class]);
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock checkLatestRelease:[OCMArg any]]).andDo(nil);
  OCMStub([distributeMock requestUpdateToken]).andDo(nil);

  // When
  OCMStub([mobileCenterMock isDebuggerAttached]).andReturn(NO);
  OCMStub([utilMock isRunningInDebugConfiguration]).andReturn(NO);
  OCMStub([utilMock currentAppEnvironment]).andReturn(MSEnvironmentOther);

  // Then
  XCTAssertTrue([self.sut checkForUpdatesAllowed]);
  
  // When
  [distributeMock applyEnabledState:YES];
  
  // Then
  XCTAssertTrue([distributeMock checkForUpdatesAllowed]);
  OCMVerify([distributeMock requestUpdateToken]);
}

- (void)testcheckForUpdatesDebuggerAttached {
  
  // When
  id mobileCenterMock = OCMClassMock([MSMobileCenter class]);
  id utilMock = OCMClassMock([MSUtil class]);
  OCMStub([mobileCenterMock isDebuggerAttached]).andReturn(YES);
  OCMStub([utilMock isRunningInDebugConfiguration]).andReturn(NO);
  OCMStub([utilMock currentAppEnvironment]).andReturn(MSEnvironmentOther);
  
  // Then
  XCTAssertFalse([self.sut checkForUpdatesAllowed]);
}

- (void)testcheckForUpdatesDebugConfig {
  
  // When
  id mobileCenterMock = OCMClassMock([MSMobileCenter class]);
  id utilMock = OCMClassMock([MSUtil class]);
  OCMStub([mobileCenterMock isDebuggerAttached]).andReturn(NO);
  OCMStub([utilMock isRunningInDebugConfiguration]).andReturn(YES);
  OCMStub([utilMock currentAppEnvironment]).andReturn(MSEnvironmentOther);
  
  // Then
  XCTAssertFalse([self.sut checkForUpdatesAllowed]);
}

- (void)testcheckForUpdatesInvalidEnvironment {
  
  // When
  id mobileCenterMock = OCMClassMock([MSMobileCenter class]);
  id utilMock = OCMClassMock([MSUtil class]);
  OCMStub([mobileCenterMock isDebuggerAttached]).andReturn(NO);
  OCMStub([utilMock isRunningInDebugConfiguration]).andReturn(NO);
  OCMStub([utilMock currentAppEnvironment]).andReturn(MSEnvironmentTestFlight);
  
  // Then
  XCTAssertFalse([self.sut checkForUpdatesAllowed]);
}

@end
