#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "MSAlertController.h"
#import "MSBasicMachOParser.h"
#import "MSDistribute.h"
#import "MSDistributeInternal.h"
#import "MSDistributePrivate.h"
#import "MSDistributeTestUtil.h"
#import "MSDistributeUtil.h"
#import "MSKeychainUtil.h"
#import "MSMobileCenter.h"
#import "MSMockUserDefaults.h"
#import "MSServiceAbstractProtected.h"
#import "MSUserDefaults.h"
#import "MSUtility+Application.h"
#import "MSUtility+Environment.h"
#import "MSUtility+StringFormatting.h"

static NSString *const kMSTestAppSecret = @"IAMSECRET";
static NSString *const kMSTestReleaseHash = @"RELEASEHASH";
static NSString *const kMSDistributeServiceName = @"Distribute";

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

@property(nonatomic) MSDistribute *sut;
@property(nonatomic) id parserMock;
@property(nonatomic) id settingsMock;

@end

@implementation MSDistributeTests

- (void)setUp {
  [super setUp];
  [MSKeychainUtil clear];
  self.sut = [MSDistribute new];
  self.settingsMock = [MSMockUserDefaults new];

  // Make sure we disable the debug-mode checks so we can actually test the logic.
  [MSDistributeTestUtil mockUpdatesAllowedConditions];

  // MSBasicMachOParser may fail on test projects' main bundle. It's mocked to prevent it.
  id parserMock = OCMClassMock([MSBasicMachOParser class]);
  self.parserMock = parserMock;
  OCMStub([parserMock machOParserForMainBundle]).andReturn(self.parserMock);
  OCMStub([self.parserMock uuid])
      .andReturn([[NSUUID alloc] initWithUUIDString:@"CD55E7A9-7AD1-4CA6-B722-3D133F487DA9"]);
}

- (void)tearDown {
  [super tearDown];
  [MSKeychainUtil clear];
  [self.parserMock stopMocking];
  [self.settingsMock stopMocking];
  [MSDistributeTestUtil unMockUpdatesAllowedConditions];
}

- (void)testInstallURL {

  // If
  XCTestExpectation *openURLCalledExpectation = [self expectationWithDescription:@"openURL Called."];
  NSArray *bundleArray = @[
    @{ @"CFBundleURLSchemes" : @[ [NSString stringWithFormat:@"mobilecenter-%@", kMSTestAppSecret] ] }
  ];
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);
  NSDictionary<NSString *, id> *plist = @{ @"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1" };
  OCMStub([bundleMock infoDictionary]).andReturn(plist);
  OCMStub([bundleMock objectForInfoDictionaryKey:@"CFBundleURLTypes"]).andReturn(bundleArray);
  OCMStub([bundleMock objectForInfoDictionaryKey:@"MSAppName"]).andReturn(@"Something");
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock openURLInEmbeddedSafari:[OCMArg any] fromClass:[OCMArg any]]).andDo(nil);

  // Disable for now to bypass initializing sender.
  [distributeMock setEnabled:NO];
  [distributeMock startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];

  // Enable again.
  [distributeMock setEnabled:YES];

  // When
  dispatch_async(dispatch_get_main_queue(), ^{
    [openURLCalledExpectation fulfill];
  });
  NSURL *url = [distributeMock buildTokenRequestURLWithAppSecret:kMSTestAppSecret releaseHash:kMSTestReleaseHash];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
  NSMutableDictionary<NSString *, NSString *> *queryStrings = [NSMutableDictionary<NSString *, NSString *> new];
  [components.queryItems
      enumerateObjectsUsingBlock:^(__kindof NSURLQueryItem *_Nonnull queryItem, __attribute__((unused)) NSUInteger idx,
                                   __attribute__((unused)) BOOL *_Nonnull stop) {
        if (queryItem.value) {
          [queryStrings setObject:(NSString * _Nonnull)queryItem.value forKey:queryItem.name];
        }
      }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 assertThat(url, notNilValue());
                                 assertThatLong(queryStrings.count, equalToLong(4));
                                 assertThatBool([components.path containsString:kMSTestAppSecret], isTrue());
                                 assertThat(queryStrings[kMSURLQueryPlatformKey], is(kMSURLQueryPlatformValue));
                                 assertThat(
                                     queryStrings[kMSURLQueryRedirectIdKey],
                                     is([NSString stringWithFormat:kMSDefaultCustomSchemeFormat, kMSTestAppSecret]));
                                 assertThat(queryStrings[kMSURLQueryRequestIdKey], notNilValue());
                                 assertThat(queryStrings[kMSURLQueryReleaseHashKey], equalTo(kMSTestReleaseHash));
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testMalformedUpdateURL {

  // If
  NSString *badAppSecret = @"weird\\app\\secret";
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn([NSBundle bundleForClass:[self class]]);

  // When
  NSURL *url = [self.sut buildTokenRequestURLWithAppSecret:badAppSecret releaseHash:kMSTestReleaseHash];

  assertThat(url, nilValue());
}

- (void)testOpenURLInSafariApp {

  // If
  XCTestExpectation *openURLCalledExpectation = [self expectationWithDescription:@"openURL Called."];
  NSURL *url = [NSURL URLWithString:@"https://contoso.com"];
  id appMock = OCMClassMock([UIApplication class]);
  OCMStub([appMock sharedApplication]).andReturn(appMock);
  OCMStub([appMock canOpenURL:url]).andReturn(YES);
  OCMStub([appMock openURL:url]).andDo(nil);

  // When
  [self.sut openURLInSafariApp:url];
  dispatch_async(dispatch_get_main_queue(), ^{
    [openURLCalledExpectation fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 OCMVerify([appMock openURL:url]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testOpenURLInEmbeddedSafari {

  // If
  NSURL *url = [NSURL URLWithString:@"https://contoso.com"];

  // When
  @try {
    [self.sut openURLInEmbeddedSafari:url fromClass:[SFSafariViewController class]];
  } @catch (__attribute__((unused)) NSException *ex) {

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
  [MSDistribute setApiUrl:testUrl];
  MSDistribute *distribute = [MSDistribute sharedInstance];

  // Then
  XCTAssertTrue([[distribute apiUrl] isEqualToString:testUrl]);
}

- (void)testSetInstallUrlWorks {

  // If
  NSString *testUrl = @"https://example.com";
  NSArray *bundleArray = @[
    @{ @"CFBundleURLSchemes" : @[ [NSString stringWithFormat:@"mobilecenter-%@", kMSTestAppSecret] ] }
  ];
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);
  NSDictionary<NSString *, id> *plist = @{ @"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1" };
  OCMStub([bundleMock infoDictionary]).andReturn(plist);
  OCMStub([bundleMock objectForInfoDictionaryKey:@"CFBundleURLTypes"]).andReturn(bundleArray);

  // When
  [MSDistribute setInstallUrl:testUrl];
  MSDistribute *distribute = [MSDistribute sharedInstance];
  NSURL *url = [distribute buildTokenRequestURLWithAppSecret:kMSTestAppSecret releaseHash:kMSTestReleaseHash];

  // Then
  XCTAssertTrue([[distribute installUrl] isEqualToString:testUrl]);
  XCTAssertTrue([url.absoluteString hasPrefix:testUrl]);
}

- (void)testDefaultInstallUrlWorks {

  // If
  NSArray *bundleArray = @[
    @{ @"CFBundleURLSchemes" : @[ [NSString stringWithFormat:@"mobilecenter-%@", kMSTestAppSecret] ] }
  ];
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);
  NSDictionary<NSString *, id> *plist = @{ @"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1" };
  OCMStub([bundleMock infoDictionary]).andReturn(plist);
  OCMStub([bundleMock objectForInfoDictionaryKey:@"CFBundleURLTypes"]).andReturn(bundleArray);

  // When
  NSString *instalURL = [self.sut installUrl];
  NSURL *tokenRequestURL = [self.sut buildTokenRequestURLWithAppSecret:kMSTestAppSecret releaseHash:kMSTestReleaseHash];

  // Then
  XCTAssertNotNil(instalURL);
  XCTAssertTrue([tokenRequestURL.absoluteString hasPrefix:kMSDefaultInstallUrl]);
}

- (void)testDefaultApiUrlWorks {

  // Then
  XCTAssertNotNil([self.sut apiUrl]);
  XCTAssertTrue([[self.sut apiUrl] isEqualToString:kMSDefaultApiUrl]);
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

- (void)testShowConfirmationAlert {

  // If
  id mobileCenterMock = OCMPartialMock(self.sut);
  id alertControllerMock = OCMClassMock([MSAlertController class]);
  MSReleaseDetails *details = [MSReleaseDetails new];
  OCMStub([alertControllerMock alertControllerWithTitle:[OCMArg any] message:[OCMArg any]])
      .andReturn(alertControllerMock);
  details.releaseNotes = @"Release Note";
  details.mandatoryUpdate = false;

  // When
  XCTestExpectation *expection = [self expectationWithDescription:@"Confirmation alert has been displayed"];
  [mobileCenterMock showConfirmationAlert:details];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expection fulfill];
  });

  [self waitForExpectationsWithTimeout:1
                               handler:^(__attribute__((unused)) NSError *error) {

                                 // Then
                                 OCMVerify([alertControllerMock alertControllerWithTitle:[OCMArg any]
                                                                                 message:details.releaseNotes]);
                                 OCMVerify(
                                     [alertControllerMock addDefaultActionWithTitle:[OCMArg any] handler:[OCMArg any]]);
                                 OCMVerify(
                                     [alertControllerMock addCancelActionWithTitle:[OCMArg any] handler:[OCMArg any]]);
                               }];
}

- (void)testShowConfirmationAlertForMandatoryUpdate {

  // If
  id mobileCenterMock = OCMPartialMock(self.sut);
  id alertControllerMock = OCMClassMock([MSAlertController class]);
  MSReleaseDetails *details = [MSReleaseDetails new];
  OCMStub([alertControllerMock alertControllerWithTitle:[OCMArg any] message:[OCMArg any]])
      .andReturn(alertControllerMock);
  details.releaseNotes = @"Release Note";
  details.mandatoryUpdate = true;

  // When
  XCTestExpectation *expection = [self expectationWithDescription:@"Confirmation alert has been displayed"];
  [mobileCenterMock showConfirmationAlert:details];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expection fulfill];
  });

  [self waitForExpectationsWithTimeout:1
                               handler:^(__attribute__((unused)) NSError *error) {

                                 // Then
                                 OCMVerify([alertControllerMock alertControllerWithTitle:[OCMArg any]
                                                                                 message:details.releaseNotes]);
                                 OCMReject(
                                     [alertControllerMock addDefaultActionWithTitle:[OCMArg any] handler:[OCMArg any]]);
                                 OCMVerify(
                                     [alertControllerMock addCancelActionWithTitle:[OCMArg any] handler:[OCMArg any]]);
                               }];
}

- (void)testOpenUrl {

  // If
  NSString *scheme = [NSString stringWithFormat:kMSDefaultCustomSchemeFormat, kMSTestAppSecret];
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock sharedInstance]).andReturn(distributeMock);
  OCMStub([distributeMock checkLatestRelease:[OCMArg any] releaseHash:kMSTestReleaseHash]).andDo(nil);
  [self mockMSPackageHash];

  // Disable for now to bypass initializing sender.
  [distributeMock setEnabled:NO];
  [distributeMock startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];

  // Enable again.
  [distributeMock setEnabled:YES];
  NSURL *url = [NSURL URLWithString:@"invalid://?"];

  // When
  [MSDistribute openUrl:url];

  // Then
  OCMReject([distributeMock checkLatestRelease:[OCMArg any] releaseHash:[OCMArg any]]);

  // If
  url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://?", scheme]];

  // When
  [MSDistribute openUrl:url];

  // Then
  OCMReject([distributeMock checkLatestRelease:[OCMArg any] releaseHash:[OCMArg any]]);

  // If
  NSString *requestId = @"FIRST-REQUEST";
  url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://?request_id=%@", scheme, requestId]];

  // When
  [MSDistribute openUrl:url];

  // Then
  OCMReject([distributeMock checkLatestRelease:[OCMArg any] releaseHash:[OCMArg any]]);

  // If
  NSString *token = @"TOKEN";
  url = [NSURL
      URLWithString:[NSString stringWithFormat:@"%@://?request_id=%@&update_token=%@", scheme, requestId, token]];

  // When
  [MSDistribute openUrl:url];

  // Then
  OCMReject([distributeMock checkLatestRelease:[OCMArg any] releaseHash:[OCMArg any]]);

  // If
  id userDefaultsMock = OCMClassMock([MSUserDefaults class]);
  OCMStub([userDefaultsMock shared]).andReturn(userDefaultsMock);
  OCMStub([userDefaultsMock objectForKey:kMSUpdateTokenRequestIdKey]).andReturn(requestId);

  url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://?request_id=%@&update_token=%@",
                                                        [NSString stringWithFormat:kMSDefaultCustomSchemeFormat,
                                                                                   @"Invalid-app-secret"],
                                                        requestId, token]];

  // When
  [MSDistribute openUrl:url];

  // Then
  OCMReject([distributeMock checkLatestRelease:[OCMArg any] releaseHash:[OCMArg any]]);

  // If
  url = [NSURL
      URLWithString:[NSString stringWithFormat:@"%@://?request_id=%@&update_token=%@", scheme, requestId, token]];

  // When
  [MSDistribute openUrl:url];

  // Then
  OCMVerify([distributeMock checkLatestRelease:token releaseHash:kMSTestReleaseHash]);

  // If
  [distributeMock setEnabled:NO];

  // When
  [MSDistribute openUrl:url];

  // Then
  OCMReject([distributeMock checkLatestRelease:[OCMArg any] releaseHash:[OCMArg any]]);
}

- (void)testApplyEnabledStateTrueForDebugConfig {

  // If
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock checkLatestRelease:[OCMArg any] releaseHash:[OCMArg any]]).andDo(nil);
  OCMStub([distributeMock requestUpdateToken:[OCMArg any]]).andDo(nil);

  // When
  [distributeMock applyEnabledState:YES];

  // Then
  XCTAssertNil([self.settingsMock objectForKey:kMSUpdateTokenRequestIdKey]);
  XCTAssertNil([self.settingsMock objectForKey:kMSIgnoredReleaseIdKey]);

  // When
  [distributeMock applyEnabledState:NO];

  // Then
  XCTAssertNil([self.settingsMock objectForKey:kMSUpdateTokenRequestIdKey]);
  XCTAssertNil([self.settingsMock objectForKey:kMSIgnoredReleaseIdKey]);
}

- (void)testApplyEnabledStateTrue {

  // If
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock checkLatestRelease:[OCMArg any] releaseHash:[OCMArg any]]).andDo(nil);
  OCMStub([distributeMock requestUpdateToken:[OCMArg any]]).andDo(nil);
  [self mockMSPackageHash];

  // When
  [distributeMock applyEnabledState:YES];

  // Then
  OCMVerify([distributeMock requestUpdateToken:kMSTestReleaseHash]);

  // If
  [MSKeychainUtil storeString:@"UpdateToken" forKey:kMSUpdateTokenKey];

  // When
  [distributeMock applyEnabledState:YES];

  // Then
  OCMVerify([distributeMock checkLatestRelease:[OCMArg any] releaseHash:kMSTestReleaseHash]);

  // If
  [self.settingsMock setObject:@"RequestID" forKey:kMSUpdateTokenRequestIdKey];
  [self.settingsMock setObject:@"ReleaseID" forKey:kMSIgnoredReleaseIdKey];

  // Then
  XCTAssertNotNil([self.settingsMock objectForKey:kMSUpdateTokenRequestIdKey]);
  XCTAssertNotNil([self.settingsMock objectForKey:kMSIgnoredReleaseIdKey]);

  // When
  [distributeMock applyEnabledState:NO];

  // Then
  XCTAssertNil([self.settingsMock objectForKey:kMSUpdateTokenRequestIdKey]);
  XCTAssertNil([self.settingsMock objectForKey:kMSIgnoredReleaseIdKey]);
}

- (void)testcheckForUpdatesAllConditionsMet {

  // If
  [MSDistributeTestUtil unMockUpdatesAllowedConditions];
  id mobileCenterMock = OCMClassMock([MSMobileCenter class]);
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock checkLatestRelease:[OCMArg any] releaseHash:[OCMArg any]]).andDo(nil);
  OCMStub([distributeMock requestUpdateToken:[OCMArg any]]).andDo(nil);
  id utilityMock = [self mockMSPackageHash];

  // When
  OCMStub([mobileCenterMock isDebuggerAttached]).andReturn(NO);
  OCMStub([utilityMock isRunningInDebugConfiguration]).andReturn(NO);
  OCMStub([utilityMock currentAppEnvironment]).andReturn(MSEnvironmentOther);

  // Then
  XCTAssertTrue([self.sut checkForUpdatesAllowed]);

  // When
  [distributeMock applyEnabledState:YES];

  // Then
  OCMVerify([distributeMock requestUpdateToken:kMSTestReleaseHash]);
}

- (void)testcheckForUpdatesDebuggerAttached {

  // When
  [MSDistributeTestUtil unMockUpdatesAllowedConditions];
  id mobileCenterMock = OCMClassMock([MSMobileCenter class]);
  id utilityMock = OCMClassMock([MSUtility class]);
  OCMStub([mobileCenterMock isDebuggerAttached]).andReturn(YES);
  OCMStub([utilityMock isRunningInDebugConfiguration]).andReturn(NO);
  OCMStub([utilityMock currentAppEnvironment]).andReturn(MSEnvironmentOther);

  // Then
  XCTAssertFalse([self.sut checkForUpdatesAllowed]);
}

- (void)testcheckForUpdatesDebugConfig {

  // When
  [MSDistributeTestUtil unMockUpdatesAllowedConditions];
  id mobileCenterMock = OCMClassMock([MSMobileCenter class]);
  id utilityMock = OCMClassMock([MSUtility class]);
  OCMStub([mobileCenterMock isDebuggerAttached]).andReturn(NO);
  OCMStub([utilityMock isRunningInDebugConfiguration]).andReturn(YES);
  OCMStub([utilityMock currentAppEnvironment]).andReturn(MSEnvironmentOther);

  // Then
  XCTAssertFalse([self.sut checkForUpdatesAllowed]);
}

- (void)testcheckForUpdatesInvalidEnvironment {

  // When
  [MSDistributeTestUtil unMockUpdatesAllowedConditions];
  id mobileCenterMock = OCMClassMock([MSMobileCenter class]);
  id utilityMock = OCMClassMock([MSUtility class]);
  OCMStub([mobileCenterMock isDebuggerAttached]).andReturn(NO);
  OCMStub([utilityMock isRunningInDebugConfiguration]).andReturn(NO);
  OCMStub([utilityMock currentAppEnvironment]).andReturn(MSEnvironmentTestFlight);

  // Then
  XCTAssertFalse([self.sut checkForUpdatesAllowed]);
}

- (void)testNotDeleteUpdateToken {

  // If
  id userDefaultsMock = OCMClassMock([MSUserDefaults class]);
  OCMStub([userDefaultsMock shared]).andReturn(userDefaultsMock);
  OCMStub([userDefaultsMock objectForKey:kMSSDKHasLaunchedWithDistribute]).andReturn(@1);
  id keychainMock = OCMClassMock([MSKeychainUtil class]);

  // When
  [MSDistribute new];

  // Then
  OCMReject([keychainMock deleteStringForKey:kMSUpdateTokenKey]);
}

- (void)testDeleteUpdateTokenAfterReinstall {

  // If
  id userDefaultsMock = OCMClassMock([MSUserDefaults class]);
  OCMStub([userDefaultsMock shared]).andReturn(userDefaultsMock);
  OCMStub([userDefaultsMock objectForKey:kMSSDKHasLaunchedWithDistribute]).andReturn(nil);
  id keychainMock = OCMClassMock([MSKeychainUtil class]);

  // When
  [MSDistribute new];

  // Then
  OCMVerify([keychainMock deleteStringForKey:kMSUpdateTokenKey]);
  OCMVerify([userDefaultsMock setObject:@(1) forKey:kMSSDKHasLaunchedWithDistribute]);
}

- (void)testWithoutNetwork {

  // If
  id reachabilityMock = OCMClassMock([MS_Reachability class]);
  OCMStub([reachabilityMock reachabilityForInternetConnection]).andReturn(reachabilityMock);
  [reachabilityMock setValue:NotReachable forKey:@"currentReachabilityStatus"];
  id distributeMock = OCMPartialMock(self.sut);

  // When
  [distributeMock requestUpdateToken:kMSTestReleaseHash];

  // Then
  OCMReject([distributeMock buildTokenRequestURLWithAppSecret:[OCMArg any] releaseHash:kMSTestReleaseHash]);
}

- (void)testPackageHash {

  // If
  // cd55e7a9-7ad1-4ca6-b722-3d133f487da9:1.0:1 -> 1ddf47f8dda8928174c419d530adcc13bb63cebfaf823d83ad5269b41e638ef4
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);
  NSDictionary<NSString *, id> *plist = @{ @"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1" };
  OCMStub([bundleMock infoDictionary]).andReturn(plist);

  // When
  NSString *hash = MSPackageHash();

  // Then
  assertThat(hash, equalTo(@"1ddf47f8dda8928174c419d530adcc13bb63cebfaf823d83ad5269b41e638ef4"));
}

- (void)testDismissEmbeddedSafari {

  // If
  XCTestExpectation *safariDismissedExpectation = [self expectationWithDescription:@"Safari dismissed processed"];
  id viewControllerMock = OCMClassMock([UIViewController class]);
  self.sut.safariHostingViewController = nil;

  // When
  [self.sut dismissEmbeddedSafari];
  dispatch_async(dispatch_get_main_queue(), ^{
    [safariDismissedExpectation fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 OCMReject([viewControllerMock dismissViewControllerAnimated:OCMOCK_ANY
                                                                                  completion:OCMOCK_ANY]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testDismissEmbeddedSafariWithNilVC {

  // If
  XCTestExpectation *safariDismissedExpectation = [self expectationWithDescription:@"Safari dismissed processed"];
  self.sut.safariHostingViewController = nil;

  // When
  [self.sut dismissEmbeddedSafari];
  dispatch_async(dispatch_get_main_queue(), ^{
    [safariDismissedExpectation fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {

                                 // No exceptions so far test succeeded.
                                 assertThat(self.sut.safariHostingViewController, nilValue());
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testDismissEmbeddedSafariWithNilSelf {

  // If
  XCTestExpectation *safariDismissedExpectation = [self expectationWithDescription:@"Safari dismissed processed"];
  self.sut.safariHostingViewController = nil;

  // When
  [self.sut dismissEmbeddedSafari];
  self.sut = nil;

  dispatch_async(dispatch_get_main_queue(), ^{
    [safariDismissedExpectation fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {

                                 // No exceptions so far test succeeded.
                                 assertThat(self.sut, nilValue());
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testDismissEmbeddedSafariWithValidVC {

  // If
  XCTestExpectation *safariDismissedExpectation = [self expectationWithDescription:@"Safari dismissed processed"];
  id viewControllerMock = OCMClassMock([UIViewController class]);
  self.sut.safariHostingViewController = viewControllerMock;

  // When
  [self.sut dismissEmbeddedSafari];
  dispatch_async(dispatch_get_main_queue(), ^{
    [safariDismissedExpectation fulfill];
  });

  // Then
  [self
      waitForExpectationsWithTimeout:1
                             handler:^(NSError *error) {
                               OCMVerify([viewControllerMock dismissViewControllerAnimated:YES completion:OCMOCK_ANY]);
                               if (error) {
                                 XCTFail(@"Expectation Failed with error: %@", error);
                               }
                             }];
}

- (void)testDismissEmbeddedSafariWhenOpenURL {

  // If
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock sharedInstance]).andReturn(distributeMock);
  OCMStub([distributeMock isEnabled]).andReturn(YES);
  ((MSDistribute *)distributeMock).appSecret = kMSTestAppSecret;
  id userDefaultsMock = OCMClassMock([MSUserDefaults class]);
  OCMStub([userDefaultsMock shared]).andReturn(userDefaultsMock);
  OCMStub([userDefaultsMock objectForKey:kMSUpdateTokenRequestIdKey]).andReturn(@"FIRST-REQUEST");
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://?request_id=FIRST-REQUEST&update_token=token",
                                                               [NSString stringWithFormat:kMSDefaultCustomSchemeFormat,
                                                                                          kMSTestAppSecret]]];
  XCTestExpectation *safariDismissedExpectation = [self expectationWithDescription:@"Safari dismissed processed"];
  id viewControllerMock = OCMClassMock([UIViewController class]);
  self.sut.safariHostingViewController = viewControllerMock;

  // When
  [MSDistribute openUrl:url];
  dispatch_async(dispatch_get_main_queue(), ^{
    [safariDismissedExpectation fulfill];
  });

  // Then
  [self
      waitForExpectationsWithTimeout:1
                             handler:^(NSError *error) {
                               OCMVerify([viewControllerMock dismissViewControllerAnimated:YES completion:OCMOCK_ANY]);
                               if (error) {
                                 XCTFail(@"Expectation Failed with error: %@", error);
                               }
                             }];
}

- (void)testDismissEmbeddedSafariWhenDisabling {

  // If
  XCTestExpectation *safariDismissedExpectation = [self expectationWithDescription:@"Safari dismissed processed"];
  id viewControllerMock = OCMClassMock([UIViewController class]);
  self.sut.safariHostingViewController = viewControllerMock;

  // When
  [self.sut applyEnabledState:NO];
  dispatch_async(dispatch_get_main_queue(), ^{
    [safariDismissedExpectation fulfill];
  });

  // Then
  [self
      waitForExpectationsWithTimeout:1
                             handler:^(NSError *error) {
                               OCMVerify([viewControllerMock dismissViewControllerAnimated:YES completion:OCMOCK_ANY]);
                               if (error) {
                                 XCTFail(@"Expectation Failed with error: %@", error);
                               }
                             }];
}

- (void)testShowDistributeDisabledAlert {

  // If
  id mobileCenterMock = OCMPartialMock(self.sut);
  id alertControllerMock = OCMClassMock([MSAlertController class]);
  OCMStub([alertControllerMock alertControllerWithTitle:[OCMArg any] message:[OCMArg any]])
      .andReturn(alertControllerMock);

  // When
  XCTestExpectation *expection = [self expectationWithDescription:@"Distribute disabled alert has been displayed"];
  [mobileCenterMock showDistributeDisabledAlert];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expection fulfill];
  });

  [self waitForExpectationsWithTimeout:1
                               handler:^(__attribute__((unused)) NSError *error) {

                                 // Then
                                 OCMVerify([alertControllerMock alertControllerWithTitle:[OCMArg any] message:nil]);
                                 OCMVerify(
                                     [alertControllerMock addCancelActionWithTitle:[OCMArg any] handler:[OCMArg any]]);
                               }];
}

- (void)testStartDownload {

  // If
  MSReleaseDetails *details = [MSReleaseDetails new];
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock closeApp]).andDo(nil);
  id utilityMock = OCMClassMock([MSUtility class]);
  OCMStub(ClassMethod([utilityMock sharedAppOpenUrl:[OCMArg any] options:[OCMArg any] completionHandler:[OCMArg any]]))
      .andDo(^(NSInvocation *invocation) {
        void (^handler)(MSOpenURLState);
        [invocation getArgument:&handler atIndex:4];
        handler(MSOpenURLStateUnknown);
      });

  // When
  details.mandatoryUpdate = YES;
  [distributeMock startDownload:details];

  // Then
  OCMVerify([distributeMock closeApp]);
}

- (void)testStartDownloadFailed {

  // If
  MSReleaseDetails *details = [MSReleaseDetails new];
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock closeApp]).andDo(nil);
  id utilityMock = OCMClassMock([MSUtility class]);
  OCMStub(ClassMethod([utilityMock sharedAppOpenUrl:[OCMArg any] options:[OCMArg any] completionHandler:[OCMArg any]]))
      .andDo(^(NSInvocation *invocation) {
        void (^handler)(MSOpenURLState);
        [invocation getArgument:&handler atIndex:4];
        handler(MSOpenURLStateFailed);
      });

  // When
  details.mandatoryUpdate = YES;
  [distributeMock startDownload:details];

  // Then
  OCMReject([distributeMock closeApp]);
}

- (void)testServiceNameIsCorrect {
  XCTAssertEqual([MSDistribute serviceName], kMSDistributeServiceName);
}

- (void)testUpdateURLWithUnregisteredScheme {

  // If
  NSArray *bundleArray = @[ @{ @"CFBundleURLSchemes" : @[ @"mobilecenter-IAMSUPERSECRET" ] } ];

  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);

  NSDictionary<NSString *, id> *plist = @{ @"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1" };
  OCMStub([bundleMock infoDictionary]).andReturn(plist);
  OCMStub([bundleMock objectForInfoDictionaryKey:@"CFBundleURLTypes"]).andReturn(bundleArray);
  id distributeMock = OCMPartialMock(self.sut);

  // When
  NSURL *url = [distributeMock buildTokenRequestURLWithAppSecret:kMSTestAppSecret releaseHash:kMSTestReleaseHash];

  // Then
  assertThat(url, nilValue());
}

- (void)testIsNewerVersionFunction {
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);
  NSDictionary<NSString *, id> *plist = @{ @"CFBundleShortVersionString" : @"10.0", @"CFBundleVersion" : @"10" };
  OCMStub([bundleMock infoDictionary]).andReturn(plist);

  // If
  MSReleaseDetails *newerRelease = [self generateReleaseDetailsWithVersion:@"20" andShortVersion:@"20.0"];

  // When
  BOOL result = [[MSDistribute sharedInstance] isNewerVersion:newerRelease];

  // Then
  XCTAssertTrue(result);

  // If
  MSReleaseDetails *olderRelease = [self generateReleaseDetailsWithVersion:@"5" andShortVersion:@"5.0"];

  // When
  result = [[MSDistribute sharedInstance] isNewerVersion:olderRelease];

  // Then
  XCTAssertFalse(result);

  // If
  MSReleaseDetails *sameRelease = [self generateReleaseDetailsWithVersion:@"10" andShortVersion:@"10.0"];
  sameRelease.packageHashes = [[NSArray alloc] initWithObjects:MSPackageHash(), nil];

  // When
  result = [[MSDistribute sharedInstance] isNewerVersion:sameRelease];

  // Then
  XCTAssertFalse(result);
}

- (MSReleaseDetails *)generateReleaseDetailsWithVersion:(NSString *)version andShortVersion:(NSString *)shortVersion {
  MSReleaseDetails *releaseDetails = [MSReleaseDetails new];
  releaseDetails.version = version;
  releaseDetails.shortVersion = shortVersion;
  return releaseDetails;
}

- (id)mockMSPackageHash {
  id utilityMock = OCMClassMock([MSUtility class]);
  OCMStub(ClassMethod([utilityMock sha256:[OCMArg any]])).andReturn(kMSTestReleaseHash);
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);
  NSDictionary<NSString *, id> *plist = @{ @"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1" };
  OCMStub([bundleMock infoDictionary]).andReturn(plist);
  return utilityMock;
}

@end
