// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <UIKit/UIKit.h>

#import "MSAlertController.h"
#import "MSAppCenterInternal.h"
#import "MSAppCenterUserDefaultsPrivate.h"
#import "MSBasicMachOParser.h"
#import "MSChannelGroupDefault.h"
#import "MSChannelUnitDefault.h"
#import "MSConstants+Internal.h"
#import "MSDependencyConfiguration.h"
#import "MSDistribute.h"
#import "MSDistributeInfoTracker.h"
#import "MSDistributeInternal.h"
#import "MSDistributePrivate.h"
#import "MSDistributeTestUtil.h"
#import "MSDistributeUtil.h"
#import "MSDistributionStartSessionLog.h"
#import "MSGuidedAccessUtil.h"
#import "MSHttpCall.h"
#import "MSHttpClient.h"
#import "MSHttpTestUtil.h"
#import "MSLoggerInternal.h"
#import "MSMockKeychainUtil.h"
#import "MSMockReachability.h"
#import "MSMockUserDefaults.h"
#import "MSSessionContext.h"
#import "MSSessionContextPrivate.h"
#import "MSTestFrameworks.h"
#import "MSUtility+StringFormatting.h"
#import "MS_Reachability.h"

static NSString *const kMSTestAppSecret = @"IAMSECRET";
static NSString *const kMSTestReleaseHash = @"RELEASEHASH";
static NSString *const kMSTestUpdateToken = @"UPDATETOKEN";
static NSString *const kMSTestDistributionGroupId = @"DISTRIBUTIONGROUPID";
static NSString *const kMSTestDownloadedDistributionGroupId = @"DOWNLOADEDDISTRIBUTIONGROUPID";
static NSString *const kMSDistributeServiceName = @"Distribute";
static NSString *const kMSUpdateTokenApiPathFormat = @"/apps/%@/private-update-setup";
static NSString *const kMSDefaultURLFormat = @"https://fakeurl.com";

// Mocked SFSafariViewController for url validation.
@interface SFSafariViewControllerMock : UIViewController

@property(class, nonatomic) NSURL *url;

- (instancetype)initWithURL:(NSURL *)url;

@end

static NSURL *sfURL;

@implementation SFSafariViewControllerMock

- (instancetype)initWithURL:(NSURL *)url {
  if ((self = [self init])) {
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

@interface UIApplication (ForTests)

// Available since iOS 10.
- (void)openURL:(NSURL *)url options:(NSDictionary<NSString *, id> *)options completionHandler:(void (^__nullable)(BOOL success))completion;

@end

static NSURL *sfURL;

@interface MSDistributeTests : XCTestCase

@property(nonatomic) MSDistribute *sut;
@property(nonatomic) id parserMock;
@property(nonatomic) id settingsMock;
@property(nonatomic) id keychainUtilMock;
@property(nonatomic) id bundleMock;
@property(nonatomic) id alertControllerMock;
@property(nonatomic) id distributeInfoTrackerMock;
@property(nonatomic) id reachabilityMock;

@end

@interface MSHttpClient ()
- (void)requestCompletedWithHttpCall:(MSHttpCall *)httpCall data:(NSData *)data response:(NSURLResponse *)response error:(NSError *)error;
@end

@implementation MSDistributeTests

- (void)setUp {
  [super setUp];
  [MSLogger setCurrentLogLevel:MSLogLevelVerbose];
  self.keychainUtilMock = [MSMockKeychainUtil new];
  self.sut = [MSDistribute new];
  self.settingsMock = [MSMockUserDefaults new];

  // Mock network.
  [MSHttpTestUtil stubHttp200Response];

  // Mock NSBundle
  self.bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([self.bundleMock mainBundle]).andReturn(self.bundleMock);

  // Make sure we disable the debug-mode checks so we can actually test the logic.
  [MSDistributeTestUtil mockUpdatesAllowedConditions];

  // MSBasicMachOParser may fail on test projects' main bundle. It's mocked to prevent it.
  id parserMock = OCMClassMock([MSBasicMachOParser class]);
  self.parserMock = parserMock;
  OCMStub([parserMock machOParserForMainBundle]).andReturn(self.parserMock);
  OCMStub([self.parserMock uuid]).andReturn([[NSUUID alloc] initWithUUIDString:@"CD55E7A9-7AD1-4CA6-B722-3D133F487DA9"]);

  // Mock alert.
  self.alertControllerMock = OCMClassMock([MSAlertController class]);
  OCMStub([self.alertControllerMock alertControllerWithTitle:OCMOCK_ANY message:OCMOCK_ANY]).andReturn(self.alertControllerMock);

  // Mock DistributeInfoTracker.
  self.distributeInfoTrackerMock = OCMClassMock([MSDistributeInfoTracker class]);
  self.sut.distributeInfoTracker = self.distributeInfoTrackerMock;

  // Mock reachability.
  [MSMockReachability setCurrentNetworkStatus:ReachableViaWiFi];
  self.reachabilityMock = [MSMockReachability startMocking];

  // Clear all previous sessions and tokens.
  [MSSessionContext resetSharedInstance];
}

- (void)tearDown {

  // Clear
  [MSDistribute resetSharedInstance];
  [MSHttpTestUtil removeAllStubs];
  [self.keychainUtilMock stopMocking];
  [self.parserMock stopMocking];
  [self.settingsMock stopMocking];
  [self.bundleMock stopMocking];
  [self.alertControllerMock stopMocking];
  [self.distributeInfoTrackerMock stopMocking];
  [MSDistributeTestUtil unMockUpdatesAllowedConditions];

  // Wait all tasks in tests. This doesn't work properly when this class only runs for testing.
  // Repro: Remove expectation related code in `testOpenUrlWithUpdateSetupFailure` and test the class.
  XCTestExpectation *expectation = [self expectationWithDescription:@"tearDown"];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });
  [self waitForExpectations:@[ expectation ] timeout:1];

  [super tearDown];
}

- (void)testMigrateOnInit {
  [MSDistribute sharedInstance];
  NSString *key = [NSString stringWithFormat:kMSMockMigrationKey, @"Distribute"];
  XCTAssertNotNil([self.settingsMock objectForKey:key]);
}

- (void)testInstallURL {

  // If
  XCTestExpectation *openURLCalledExpectation = [self expectationWithDescription:@"openURL Called."];
  NSArray *bundleArray = @[ @{kMSCFBundleURLSchemes : @[ [NSString stringWithFormat:@"appcenter-%@", kMSTestAppSecret] ]} ];
  OCMStub([self.bundleMock objectForInfoDictionaryKey:kMSCFBundleURLTypes]).andReturn(bundleArray);
  OCMStub([self.bundleMock objectForInfoDictionaryKey:@"MSAppName"]).andReturn(@"Something");
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock openURLInSafariViewControllerWith:OCMOCK_ANY fromClass:OCMOCK_ANY]).andDo(nil);

  // Disable for now to bypass initializing ingestion.
  [self.sut setEnabled:NO];
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                        appSecret:kMSTestAppSecret
          transmissionTargetToken:nil
                  fromApplication:YES];

  // Enable again.
  [self.sut setEnabled:YES];

  // When
  dispatch_async(dispatch_get_main_queue(), ^{
    [openURLCalledExpectation fulfill];
  });
  NSURL *url = [self.sut buildTokenRequestURLWithAppSecret:kMSTestAppSecret releaseHash:kMSTestReleaseHash isTesterApp:false];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
  NSMutableDictionary<NSString *, NSString *> *queryStrings = [NSMutableDictionary<NSString *, NSString *> new];
  [components.queryItems enumerateObjectsUsingBlock:^(__kindof NSURLQueryItem *_Nonnull queryItem, __attribute__((unused)) NSUInteger idx,
                                                      __attribute__((unused)) BOOL *_Nonnull stop) {
    if (queryItem.value) {
      queryStrings[queryItem.name] = queryItem.value;
    }
  }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 assertThat(url, notNilValue());
                                 assertThatLong(queryStrings.count, equalToLong(5));
                                 assertThatBool([components.path containsString:kMSTestAppSecret], isTrue());
                                 assertThat(queryStrings[kMSURLQueryPlatformKey], is(kMSURLQueryPlatformValue));
                                 assertThat(queryStrings[kMSURLQueryRedirectIdKey],
                                            is([NSString stringWithFormat:kMSDefaultCustomSchemeFormat, kMSTestAppSecret]));
                                 assertThat(queryStrings[kMSURLQueryRequestIdKey], notNilValue());
                                 assertThat(queryStrings[kMSURLQueryReleaseHashKey], equalTo(kMSTestReleaseHash));
                                 assertThat(queryStrings[kMSURLQueryEnableUpdateSetupFailureRedirectKey], equalTo(@"true"));
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
  [distributeMock stopMocking];
}

- (void)testMalformedUpdateURL {

  // If
  NSString *badAppSecret = @"weird\\app\\secret";

  // When
  NSURL *url = [self.sut buildTokenRequestURLWithAppSecret:badAppSecret releaseHash:kMSTestReleaseHash isTesterApp:false];

  // Then
  assertThat(url, nilValue());
}

- (void)testOpenURLInSafariViewControllerWithUrl {

  // If
  NSURL *url = [NSURL URLWithString:@"https://contoso.com"];

  // When
  @try {
    [self.sut openURLInSafariViewControllerWith:url fromClass:[SFSafariViewControllerMock class]];
  } @catch (__attribute__((unused)) NSException *ex) {

    /**
     * TODO: This is not a UI test so we expect it to fail with NSInternalInconsistencyException exception. Hopefully it doesn't prevent the
     * URL to be set. Maybe introduce UI testing for this case in the future.
     */
  }

  // Then
  assertThat(SFSafariViewControllerMock.url, is(url));
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
  NSArray *bundleArray = @[ @{kMSCFBundleURLSchemes : @[ [NSString stringWithFormat:@"appcenter-%@", kMSTestAppSecret] ]} ];
  OCMStub([self.bundleMock objectForInfoDictionaryKey:kMSCFBundleURLTypes]).andReturn(bundleArray);

  // When
  [MSDistribute setInstallUrl:testUrl];
  MSDistribute *distribute = [MSDistribute sharedInstance];
  NSURL *url = [distribute buildTokenRequestURLWithAppSecret:kMSTestAppSecret releaseHash:kMSTestReleaseHash isTesterApp:false];

  // Then
  XCTAssertTrue([[distribute installUrl] isEqualToString:testUrl]);
  XCTAssertTrue([url.absoluteString hasPrefix:testUrl]);
}

- (void)testDefaultInstallUrlWorks {

  // If
  NSArray *bundleArray = @[ @{kMSCFBundleURLSchemes : @[ [NSString stringWithFormat:@"appcenter-%@", kMSTestAppSecret] ]} ];
  OCMStub([self.bundleMock objectForInfoDictionaryKey:kMSCFBundleURLTypes]).andReturn(bundleArray);

  // When
  NSString *installURL = [self.sut installUrl];
  NSURL *tokenRequestURL = [self.sut buildTokenRequestURLWithAppSecret:kMSTestAppSecret releaseHash:kMSTestReleaseHash isTesterApp:false];

  // Then
  XCTAssertNotNil(installURL);
  XCTAssertTrue([tokenRequestURL.absoluteString hasPrefix:kMSDefaultInstallUrl]);
}

- (void)testDefaultApiUrlWorks {

  // Then
  XCTAssertNotNil([self.sut apiUrl]);
  XCTAssertTrue([[self.sut apiUrl] isEqualToString:kMSDefaultApiUrl]);
}

- (void)testInitializationPriority {

  // If
  MSDistribute *distribute = [MSDistribute sharedInstance];

  // Then
  XCTAssertEqual([distribute initializationPriority], MSInitializationPriorityHigh);
}

- (void)testHandleInvalidUpdate {

  // If
  MSReleaseDetails *details = [MSReleaseDetails new];
  id distributeMock = OCMPartialMock(self.sut);
  OCMReject([distributeMock showConfirmationAlert:OCMOCK_ANY]);
  OCMStub([distributeMock showConfirmationAlert:OCMOCK_ANY]).andDo(nil);

  // When
  [self.sut handleUpdate:details];

  // If
  details.id = @1;
  details.downloadUrl = [NSURL URLWithString:@"https://contoso.com/valid/url"];

  // When
  [self.sut handleUpdate:details];

  // If
  details.status = @"available";
  details.minOs = @"1000.0";

  // When
  [self.sut handleUpdate:details];

  // If
  details.minOs = @"1.0";
  OCMStub([distributeMock isNewerVersion:OCMOCK_ANY]).andReturn(NO);

  // When
  [self.sut handleUpdate:details];

  // Then
  OCMVerifyAll(distributeMock);

  // Clear
  [distributeMock stopMocking];
}

- (void)testHandleValidUpdate {

  // If
  MSReleaseDetails *details = [MSReleaseDetails new];
  id distributeMock = OCMPartialMock(self.sut);
  __block int showConfirmationAlertCounter = 0;
  OCMStub([distributeMock showConfirmationAlert:OCMOCK_ANY]).andDo(^(__attribute((unused)) NSInvocation *invocation) {
    showConfirmationAlertCounter++;
  });
  OCMStub([distributeMock isNewerVersion:OCMOCK_ANY]).andReturn(YES);
  details.id = @1;
  details.downloadUrl = [NSURL URLWithString:@"https://contoso.com/valid/url"];
  details.status = @"available";
  details.minOs = @"1.0";

  // When
  [self.sut handleUpdate:details];

  // Then
  OCMVerify([distributeMock showConfirmationAlert:details]);

  /*
   * The reason of this additional checking is that OCMock doesn't work properly sometimes for OCMVerify and OCMReject. The test won't be
   * failed even though the above line is changed to OCMReject, we are preventing the issue by adding more explicit checks.
   */
  XCTAssertEqual(showConfirmationAlertCounter, 1);

  // Clear
  [distributeMock stopMocking];
}

/**
 * This test is for various cases after update is postponed. This test doesn't
 * complete handleUpdate method and just
 * check whether it passes the check and then move to the next step or not.
 */
- (void)testHandleUpdateAfterPostpone {

  // If
  id distributeMock = OCMPartialMock(self.sut);
  __block int isNewerVersionCounter = 0;
  OCMStub([distributeMock isNewerVersion:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    isNewerVersionCounter++;

    // Return NO and exit the method.
    BOOL enabled = NO;
    NSValue *returnValue = [NSValue valueWithBytes:&enabled objCType:@encode(BOOL)];
    [invocation setReturnValue:&returnValue];
  });
  int actualCounter = 0;
  MSReleaseDetails *details = [self generateReleaseDetailsWithVersion:@"1" andShortVersion:@"1.0"];
  details.id = @1;
  details.downloadUrl = [NSURL URLWithString:@"https://contoso.com/valid/url"];
  details.status = @"available";
  details.mandatoryUpdate = false;
  [MS_APP_CENTER_USER_DEFAULTS setObject:@((long long)[MSUtility nowInMilliseconds] - 100000) forKey:kMSPostponedTimestampKey];

  // When
  BOOL result = [self.sut handleUpdate:details];

  // Then
  XCTAssertFalse(result);
  XCTAssertEqual(isNewerVersionCounter, actualCounter++);

  // If
  details.mandatoryUpdate = true;

  // When
  [self.sut handleUpdate:details];

  // Then
  XCTAssertEqual(isNewerVersionCounter, actualCounter++);

  // If
  details.mandatoryUpdate = false;
  [MS_APP_CENTER_USER_DEFAULTS setObject:@1 forKey:kMSPostponedTimestampKey];

  // When
  [self.sut handleUpdate:details];

  // Then
  XCTAssertEqual(isNewerVersionCounter, actualCounter++);

  // If
  details.mandatoryUpdate = true;
  [MS_APP_CENTER_USER_DEFAULTS setObject:@1 forKey:kMSPostponedTimestampKey];

  // When
  [self.sut handleUpdate:details];

  // Then
  XCTAssertEqual(isNewerVersionCounter, actualCounter++);

  // If
  details.mandatoryUpdate = false;
  [MS_APP_CENTER_USER_DEFAULTS setObject:@((long long)[MSUtility nowInMilliseconds] + kMSDayInMillisecond * 2)
                                  forKey:kMSPostponedTimestampKey];

  // When
  [self.sut handleUpdate:details];

  // Then
  XCTAssertEqual(isNewerVersionCounter, actualCounter++);

  // If
  details.mandatoryUpdate = true;
  [MS_APP_CENTER_USER_DEFAULTS setObject:@((long long)[MSUtility nowInMilliseconds] + kMSDayInMillisecond * 2)
                                  forKey:kMSPostponedTimestampKey];

  // When
  [self.sut handleUpdate:details];

  // Then
  XCTAssertEqual(isNewerVersionCounter, actualCounter++);

  // Clear
  [distributeMock stopMocking];
}

- (void)testShowConfirmationAlert {

  // If
  NSString *appName = @"Test App";
  OCMStub([self.bundleMock objectForInfoDictionaryKey:@"CFBundleDisplayName"]).andReturn(appName);
  MSReleaseDetails *details = [MSReleaseDetails new];
  details.shortVersion = @"2.5";
  details.version = @"11";
  details.releaseNotes = @"Release notes";
  details.releaseNotesUrl = [NSURL URLWithString:@"https://contoso.com/release_notes"];
  details.mandatoryUpdate = false;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wformat-nonliteral"
  NSString *message = [NSString stringWithFormat:MSDistributeLocalizedString(@"MSDistributeAppUpdateAvailableOptionalUpdateMessage"),
                                                 appName, details.shortVersion, details.version];
#pragma clang diagnostic pop

  // When
  XCTestExpectation *expectation = [self expectationWithDescription:@"Confirmation alert has been displayed"];
  [self.sut showConfirmationAlert:details];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });

  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }

                                 // Then
                                 OCMVerify([self.alertControllerMock alertControllerWithTitle:OCMOCK_ANY message:message]);
                                 OCMVerify([self.alertControllerMock
                                     addDefaultActionWithTitle:MSDistributeLocalizedString(@"MSDistributeAskMeInADay")
                                                       handler:OCMOCK_ANY]);
                                 OCMVerify([self.alertControllerMock
                                     addDefaultActionWithTitle:MSDistributeLocalizedString(@"MSDistributeViewReleaseNotes")
                                                       handler:OCMOCK_ANY]);
                                 OCMVerify([self.alertControllerMock addPreferredActionWithTitle:OCMOCK_ANY handler:OCMOCK_ANY]);
                               }];
}

- (void)testShowConfirmationAlertWithoutViewReleaseNotesButton {

  // If
  NSString *appName = @"Test App";
  OCMStub([self.bundleMock objectForInfoDictionaryKey:@"CFBundleDisplayName"]).andReturn(appName);
  OCMReject([self.alertControllerMock addDefaultActionWithTitle:MSDistributeLocalizedString(@"MSDistributeViewReleaseNotes")
                                                        handler:OCMOCK_ANY]);
  MSReleaseDetails *details = [MSReleaseDetails new];
  details.shortVersion = @"2.5";
  details.version = @"11";
  details.mandatoryUpdate = false;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wformat-nonliteral"
  NSString *message = [NSString stringWithFormat:MSDistributeLocalizedString(@"MSDistributeAppUpdateAvailableOptionalUpdateMessage"),
                                                 appName, details.shortVersion, details.version];
#pragma clang diagnostic pop

  // When
  XCTestExpectation *expectation = [self expectationWithDescription:@"Confirmation alert has been displayed"];
  [self.sut showConfirmationAlert:details];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });

  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }

                                 // Then
                                 OCMVerify([self.alertControllerMock alertControllerWithTitle:OCMOCK_ANY message:message]);
                                 OCMVerify([self.alertControllerMock
                                     addDefaultActionWithTitle:MSDistributeLocalizedString(@"MSDistributeAskMeInADay")
                                                       handler:OCMOCK_ANY]);
                                 OCMVerify([self.alertControllerMock addPreferredActionWithTitle:OCMOCK_ANY handler:OCMOCK_ANY]);
                                 OCMVerifyAll(self.alertControllerMock);
                               }];
}

- (void)testShowConfirmationAlertForMandatoryUpdate {

  // If
  NSString *appName = @"Test App";
  OCMStub([self.bundleMock objectForInfoDictionaryKey:@"CFBundleDisplayName"]).andReturn(appName);
  OCMReject([self.alertControllerMock addDefaultActionWithTitle:MSDistributeLocalizedString(@"MSDistributeAskMeInADay")
                                                        handler:OCMOCK_ANY]);
  MSReleaseDetails *details = [MSReleaseDetails new];
  details.shortVersion = @"2.5";
  details.version = @"11";
  details.releaseNotes = @"Release notes";
  details.releaseNotesUrl = [NSURL URLWithString:@"https://contoso.com/release_notes"];
  details.mandatoryUpdate = true;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wformat-nonliteral"
  NSString *message = [NSString stringWithFormat:MSDistributeLocalizedString(@"MSDistributeAppUpdateAvailableMandatoryUpdateMessage"),
                                                 appName, details.shortVersion, details.version];
#pragma clang diagnostic pop

  // When
  XCTestExpectation *expectation = [self expectationWithDescription:@"Confirmation alert has been displayed"];
  [self.sut showConfirmationAlert:details];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });

  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }

                                 // Then
                                 OCMVerify([self.alertControllerMock alertControllerWithTitle:OCMOCK_ANY message:message]);
                                 OCMVerify([self.alertControllerMock
                                     addDefaultActionWithTitle:MSDistributeLocalizedString(@"MSDistributeViewReleaseNotes")
                                                       handler:OCMOCK_ANY]);
                                 OCMVerify([self.alertControllerMock addPreferredActionWithTitle:OCMOCK_ANY handler:OCMOCK_ANY]);
                                 OCMVerifyAll(self.alertControllerMock);
                               }];
}

- (void)testShowConfirmationAlertWithoutViewReleaseNotesButtonForMandatoryUpdate {

  // If
  NSString *appName = @"Test App";
  OCMStub([self.bundleMock objectForInfoDictionaryKey:@"CFBundleDisplayName"]).andReturn(appName);
  OCMReject([self.alertControllerMock addDefaultActionWithTitle:MSDistributeLocalizedString(@"MSDistributeAskMeInADay")
                                                        handler:OCMOCK_ANY]);
  OCMReject([self.alertControllerMock addDefaultActionWithTitle:MSDistributeLocalizedString(@"MSDistributeViewReleaseNotes")
                                                        handler:OCMOCK_ANY]);
  MSReleaseDetails *details = [MSReleaseDetails new];
  details.shortVersion = @"2.5";
  details.version = @"11";
  details.mandatoryUpdate = true;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wformat-nonliteral"
  NSString *message = [NSString stringWithFormat:MSDistributeLocalizedString(@"MSDistributeAppUpdateAvailableMandatoryUpdateMessage"),
                                                 appName, details.shortVersion, details.version];
#pragma clang diagnostic pop

  // When
  XCTestExpectation *expectation = [self expectationWithDescription:@"Confirmation alert has been displayed"];
  [self.sut showConfirmationAlert:details];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });

  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }

                                 // Then
                                 OCMVerify([self.alertControllerMock alertControllerWithTitle:OCMOCK_ANY message:message]);
                                 OCMVerify([self.alertControllerMock addPreferredActionWithTitle:OCMOCK_ANY handler:OCMOCK_ANY]);
                                 OCMVerifyAll(self.alertControllerMock);
                               }];
}

- (void)testShowConfirmationAlertForMandatoryUpdateWhileNoNetwork {

  // If
  [MSMockReachability setCurrentNetworkStatus:NotReachable];
  self.sut.appSecret = kMSTestAppSecret;
  XCTestExpectation *expectation = [self expectationWithDescription:@"Confirmation alert for private distribution has been displayed"];

  // Mock alert.
  OCMReject([self.alertControllerMock addDefaultActionWithTitle:MSDistributeLocalizedString(@"MSDistributeAskMeInADay")
                                                        handler:OCMOCK_ANY]);

  // Mock Bundle.
  NSString *appName = @"Test App";
  OCMStub([self.bundleMock objectForInfoDictionaryKey:@"CFBundleDisplayName"]).andReturn(appName);

  // Init mandatory release.
  MSReleaseDetails *details = [MSReleaseDetails new];

  // Use UUID to identify this release and verify later.
  details.id = @(42);
  details.shortVersion = @"2.5";
  details.version = @"11";
  details.downloadUrl = [NSURL URLWithString:@"https://contoso.com"];
  details.releaseNotes = @"Release notes";
  details.releaseNotesUrl = [NSURL URLWithString:@"https://contoso.com/release_notes"];
  details.mandatoryUpdate = YES;
  details.status = @"available";
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wformat-nonliteral"
  NSString *message = [NSString stringWithFormat:MSDistributeLocalizedString(@"MSDistributeAppUpdateAvailableMandatoryUpdateMessage"),
                                                 appName, details.shortVersion, details.version];
#pragma clang diagnostic pop
  id appCenterMock = OCMClassMock([MSAppCenter class]);
  OCMStub([appCenterMock isDebuggerAttached]).andReturn(YES);

  // Mock reachability.
  id reachabilityMock = OCMClassMock([MS_Reachability class]);
  OCMStub([reachabilityMock reachabilityForInternetConnection]).andReturn(reachabilityMock);
  OCMStub([reachabilityMock currentReachabilityStatus]).andDo(^(NSInvocation *invocation) {
    NetworkStatus test = NotReachable;
    [invocation setReturnValue:&test];
  });

  // Persist release to be picked up.
  [MS_APP_CENTER_USER_DEFAULTS setObject:[details serializeToDictionary] forKey:kMSMandatoryReleaseKey];
  [self.sut handleUpdate:details];

  // When
  [self.sut checkLatestRelease:@"whateverToken" distributionGroupId:@"whateverGroupId" releaseHash:@"whateverReleaseHash"];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }

                                 // Then
                                 OCMVerify([self.alertControllerMock alertControllerWithTitle:OCMOCK_ANY message:message]);
                                 OCMVerify([self.alertControllerMock
                                     addDefaultActionWithTitle:MSDistributeLocalizedString(@"MSDistributeViewReleaseNotes")
                                                       handler:OCMOCK_ANY]);
                                 OCMVerify([self.alertControllerMock addPreferredActionWithTitle:OCMOCK_ANY handler:OCMOCK_ANY]);
                                 OCMVerifyAll(self.alertControllerMock);
                               }];

  // If
  expectation = [self expectationWithDescription:@"Confirmation alert for public distribution has been displayed"];

  // When
  [self.sut checkLatestRelease:nil distributionGroupId:@"whateverGroupId" releaseHash:@"whateverReleaseHash"];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }

                                 // Then
                                 OCMVerify([self.alertControllerMock alertControllerWithTitle:OCMOCK_ANY message:message]);
                                 OCMVerify([self.alertControllerMock
                                     addDefaultActionWithTitle:MSDistributeLocalizedString(@"MSDistributeViewReleaseNotes")
                                                       handler:OCMOCK_ANY]);
                                 OCMVerify([self.alertControllerMock addPreferredActionWithTitle:OCMOCK_ANY handler:OCMOCK_ANY]);
                                 OCMVerifyAll(self.alertControllerMock);
                               }];
  [appCenterMock stopMocking];
}

- (void)testDoNotShowConfirmationAlertIfNoMandatoryReleaseWhileNoNetwork {

  // If
  [MSMockReachability setCurrentNetworkStatus:NotReachable];
  self.sut.appSecret = kMSTestAppSecret;
  XCTestExpectation *expectation = [self expectationWithDescription:@"Confirmation alert for private distribution has been displayed"];

  // Mock alert.
  OCMReject([self.alertControllerMock alertControllerWithTitle:OCMOCK_ANY message:OCMOCK_ANY]);
  OCMReject([self.alertControllerMock addDefaultActionWithTitle:OCMOCK_ANY handler:OCMOCK_ANY]);
  OCMReject([self.alertControllerMock addCancelActionWithTitle:OCMOCK_ANY handler:OCMOCK_ANY]);

  // Mock reachability.
  id reachabilityMock = OCMClassMock([MS_Reachability class]);
  OCMStub([reachabilityMock reachabilityForInternetConnection]).andReturn(reachabilityMock);
  OCMStub([reachabilityMock currentReachabilityStatus]).andDo(^(NSInvocation *invocation) {
    NetworkStatus test = NotReachable;
    [invocation setReturnValue:&test];
  });

  id appCenterMock = OCMClassMock([MSAppCenter class]);
  OCMStub([appCenterMock isDebuggerAttached]).andReturn(YES);

  // When
  [self.sut checkLatestRelease:@"whateverToken" distributionGroupId:@"whateverGroupId" releaseHash:@"whateverReleaseHash"];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 // Then
                                 OCMVerifyAll(self.alertControllerMock);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  // If
  expectation = [self expectationWithDescription:@"Confirmation alert for public distribution has been displayed"];

  // When
  [self.sut checkLatestRelease:nil distributionGroupId:@"whateverGroupId" releaseHash:@"whateverReleaseHash"];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 // Then
                                 OCMVerifyAll(self.alertControllerMock);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
  [appCenterMock stopMocking];
}

- (void)testCheckLatestReleaseRemoveKeysOnNonRecoverableError {

  // If
  id distributeMock = OCMPartialMock(self.sut);

  // Mock the HTTP client. Use dependency configuration to simplify MSHttpClient mock.
  id httpClientMock = OCMPartialMock([MSHttpClient new]);
  [MSDependencyConfiguration setHttpClient:httpClientMock];
  OCMReject([distributeMock handleUpdate:OCMOCK_ANY]);
  self.sut.appSecret = kMSTestAppSecret;
  [distributeMock setValue:@(YES) forKey:@"updateFlowInProgress"];
  id reachabilityMock = OCMClassMock([MS_Reachability class]);
  OCMStub([reachabilityMock reachabilityForInternetConnection]).andReturn(reachabilityMock);
  OCMStub([reachabilityMock currentReachabilityStatus]).andReturn(ReachableViaWiFi);
  XCTestExpectation *expectation = [self expectationWithDescription:@"Request completed."];
  OCMStub([httpClientMock requestCompletedWithHttpCall:OCMOCK_ANY data:OCMOCK_ANY response:OCMOCK_ANY error:OCMOCK_ANY])
      .andForwardToRealObject()
      .andDo(^(__unused NSInvocation *invocation) {
        [expectation fulfill];
      });

  // Non recoverable error.
  [MSHttpTestUtil stubHttp404Response];

  // When
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                        appSecret:kMSTestAppSecret
          transmissionTargetToken:nil
                  fromApplication:YES];
  [self.sut checkLatestRelease:kMSTestUpdateToken distributionGroupId:kMSTestDistributionGroupId releaseHash:kMSTestReleaseHash];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 // Then
                                 XCTAssertNil([MSMockKeychainUtil stringForKey:kMSUpdateTokenKey statusCode:nil]);
                                 OCMVerify([self.distributeInfoTrackerMock removeDistributionGroupId]);
                                 XCTAssertNil([self.settingsMock objectForKey:kMSSDKHasLaunchedWithDistribute]);
                                 XCTAssertNil([self.settingsMock objectForKey:kMSUpdateTokenRequestIdKey]);
                                 XCTAssertNil([self.settingsMock objectForKey:kMSPostponedTimestampKey]);
                                 XCTAssertNil([self.settingsMock objectForKey:kMSDistributionGroupIdKey]);
                                 XCTAssertFalse(self.sut.updateFlowInProgress);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  // Clean up
  MSDependencyConfiguration.httpClient = nil;
}

- (void)testCheckLatestReleaseOnRecoverableError {

  // If
  [MSKeychainUtil storeString:kMSTestUpdateToken forKey:kMSUpdateTokenKey];
  id distributeMock = OCMPartialMock(self.sut);

  // Mock the HTTP client.
  id httpClientMock = OCMPartialMock([MSHttpClient new]);
  id httpClientClassMock = OCMClassMock([MSHttpClient class]);
  OCMStub([httpClientClassMock alloc]).andReturn(httpClientMock);
  OCMStub([httpClientMock initWithMaxHttpConnectionsPerHost:4]).andReturn(httpClientMock);
  OCMReject([distributeMock handleUpdate:OCMOCK_ANY]);
  self.sut.appSecret = kMSTestAppSecret;
  [distributeMock setValue:@(YES) forKey:@"updateFlowInProgress"];
  id reachabilityMock = OCMClassMock([MS_Reachability class]);
  OCMStub([reachabilityMock reachabilityForInternetConnection]).andReturn(reachabilityMock);
  OCMStub([reachabilityMock currentReachabilityStatus]).andReturn(ReachableViaWiFi);
  XCTestExpectation *expectation = [self expectationWithDescription:@"Request completed."];
  OCMStub([httpClientMock requestCompletedWithHttpCall:OCMOCK_ANY data:OCMOCK_ANY response:OCMOCK_ANY error:OCMOCK_ANY])
      .andForwardToRealObject()
      .andDo(^(__unused NSInvocation *invocation) {
        [expectation fulfill];
      });
  OCMClassMock([MSHttpCall class]);
  id httpCallMock = OCMPartialMock([MSHttpCall alloc]);
  OCMStub([httpCallMock alloc]).andReturn(httpCallMock);
  OCMStub([httpCallMock startRetryTimerWithStatusCode:500 retryAfter:OCMOCK_ANY event:OCMOCK_ANY]).andDo(nil);

  // Recoverable error.
  [MSHttpTestUtil stubHttp500Response];

  // When
  [self.settingsMock setObject:@1 forKey:kMSSDKHasLaunchedWithDistribute];
  [self.settingsMock setObject:@1 forKey:kMSUpdateTokenRequestIdKey];
  [self.settingsMock setObject:@1 forKey:kMSPostponedTimestampKey];
  [self.settingsMock setObject:@1 forKey:kMSDistributionGroupIdKey];
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                        appSecret:kMSTestAppSecret
          transmissionTargetToken:nil
                  fromApplication:YES];
  [self.sut checkLatestRelease:kMSTestUpdateToken distributionGroupId:kMSTestDistributionGroupId releaseHash:kMSTestReleaseHash];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 // Then
                                 OCMVerifyAll(distributeMock);
                                 OCMVerify([httpCallMock startRetryTimerWithStatusCode:500 retryAfter:OCMOCK_ANY event:OCMOCK_ANY]);
                                 XCTAssertNotNil([MSKeychainUtil stringForKey:kMSUpdateTokenKey statusCode:nil]);
                                 XCTAssertNotNil([self.settingsMock objectForKey:kMSSDKHasLaunchedWithDistribute]);
                                 XCTAssertNotNil([self.settingsMock objectForKey:kMSUpdateTokenRequestIdKey]);
                                 XCTAssertNotNil([self.settingsMock objectForKey:kMSPostponedTimestampKey]);
                                 XCTAssertNotNil([self.settingsMock objectForKey:kMSDistributionGroupIdKey]);
                                 XCTAssertTrue(self.sut.updateFlowInProgress);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  // Clear
  [distributeMock stopMocking];
  [httpClientClassMock stopMocking];
}

- (void)testPersistLastMandatoryUpdate {

  // If
  MSReleaseDetails *details = [MSReleaseDetails new];
  details.releaseNotes = MS_UUID_STRING;
  details.id = @(42);
  details.downloadUrl = [NSURL URLWithString:@"https://contoso.com"];
  details.mandatoryUpdate = YES;
  details.status = @"available";

  // Mock MSDistribute isNewerVersion to return YES.
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock isNewerVersion:OCMOCK_ANY]).andReturn(YES);

  // This is very important that UIWindow doesn't allow accessing `makeKeyAndVisible` method from non-UI tests.
  // Stub `showConfirmationAlert:` to bypass UI related interaction.
  OCMStub([distributeMock showConfirmationAlert:OCMOCK_ANY]).andDo(nil);

  // When
  [self.sut handleUpdate:details];

  // Then
  NSMutableDictionary *persistedDict = [self.settingsMock objectForKey:kMSMandatoryReleaseKey];
  MSReleaseDetails *persistedRelease = [[MSReleaseDetails alloc] initWithDictionary:persistedDict];
  assertThat(persistedRelease, notNilValue());
  assertThat([details serializeToDictionary], is(persistedDict));

  // Clear
  [distributeMock stopMocking];
}

- (void)testDoNotPersistLastReleaseIfNotMandatory {

  // If
  id distributeMock = OCMPartialMock(self.sut);
  MSReleaseDetails *details = [MSReleaseDetails new];
  details.releaseNotes = MS_UUID_STRING;
  details.id = @(42);
  details.downloadUrl = [NSURL URLWithString:@"https://contoso.com"];
  details.mandatoryUpdate = NO;
  details.status = @"available";

  // This is very important that UIWindow doesn't allow accessing `makeKeyAndVisible` method from non-UI tests.
  // Stub `showConfirmationAlert:` to bypass UI related interaction.
  OCMStub([distributeMock showConfirmationAlert:OCMOCK_ANY]).andDo(nil);

  // When
  [self.sut handleUpdate:details];

  // Then
  NSMutableDictionary *persistedDict = [self.settingsMock objectForKey:kMSMandatoryReleaseKey];
  assertThat(persistedDict, nilValue());
}

- (void)testOpenUrlWithInvalidUrl {

  // If
  NSString *requestId = @"FIRST-REQUEST";
  NSString *token = @"TOKEN";
  NSString *scheme = [NSString stringWithFormat:kMSDefaultCustomSchemeFormat, kMSTestAppSecret];
  id distributeMock = OCMPartialMock(self.sut);
  [self.sut setUpdateTrack:MSUpdateTrackPrivate];
  OCMReject([distributeMock checkLatestRelease:OCMOCK_ANY distributionGroupId:OCMOCK_ANY releaseHash:OCMOCK_ANY]);
  OCMStub([distributeMock sharedInstance]).andReturn(distributeMock);
  id appCenterMock = OCMClassMock([MSAppCenter class]);
  OCMStub([appCenterMock isConfigured]).andReturn(YES);
  id utilityMock = [self mockMSPackageHash];

  // When
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://?", scheme]];
  [self.settingsMock setObject:requestId forKey:kMSUpdateTokenRequestIdKey];
  BOOL result = [self.sut openURL:url];

  // Then
  XCTAssertFalse(result);

  // Disable for now to bypass initializing ingestion.
  [self.sut setEnabled:NO];
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                        appSecret:kMSTestAppSecret
          transmissionTargetToken:nil
                  fromApplication:YES];

  // Enable again.
  [self.sut setEnabled:YES];

  url = [NSURL URLWithString:@"invalid://?"];

  // When
  [self.settingsMock setObject:requestId forKey:kMSUpdateTokenRequestIdKey];
  result = [self.sut openURL:url];

  // Then
  XCTAssertFalse(result);

  // If
  url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://?", scheme]];

  // When
  [self.settingsMock setObject:requestId forKey:kMSUpdateTokenRequestIdKey];
  result = [self.sut openURL:url];

  // Then
  XCTAssertTrue(result);

  // If
  url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://?request_id=%@", scheme, requestId]];

  // When
  [self.settingsMock setObject:requestId forKey:kMSUpdateTokenRequestIdKey];
  result = [self.sut openURL:url];

  // Then
  XCTAssertTrue(result);

  // If
  [MS_APP_CENTER_USER_DEFAULTS setObject:requestId forKey:kMSUpdateTokenRequestIdKey];
  url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://?request_id=%@&update_token=%@",
                                                        [NSString stringWithFormat:kMSDefaultCustomSchemeFormat, @"Invalid-app-secret"],
                                                        requestId, token]];

  // When
  [self.settingsMock setObject:requestId forKey:kMSUpdateTokenRequestIdKey];
  result = [self.sut openURL:url];

  // Then
  XCTAssertFalse(result);

  // Clear
  [distributeMock stopMocking];
  [appCenterMock stopMocking];
  [utilityMock stopMocking];
}

- (void)testOpenUrlWithCheckLatestRelease {

  // If
  NSString *requestId = @"FIRST-REQUEST";
  NSString *distributionGroupId = @"GROUP-ID";
  NSString *token = @"TOKEN";
  NSString *scheme = [NSString stringWithFormat:kMSDefaultCustomSchemeFormat, kMSTestAppSecret];
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock checkLatestRelease:OCMOCK_ANY distributionGroupId:OCMOCK_ANY releaseHash:kMSTestReleaseHash]).andDo(nil);
  OCMStub([distributeMock sharedInstance]).andReturn(distributeMock);
  id appCenterMock = OCMClassMock([MSAppCenter class]);
  OCMStub([appCenterMock isConfigured]).andReturn(YES);
  id utilityMock = [self mockMSPackageHash];

  // Disable for now to bypass initializing ingestion.
  [self.sut setEnabled:NO];
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                        appSecret:kMSTestAppSecret
          transmissionTargetToken:nil
                  fromApplication:YES];

  // Enable again.
  [self.sut setEnabled:YES];

  // If
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://?request_id=%@&update_token=%@", scheme, requestId, token]];

  // When
  [MS_APP_CENTER_USER_DEFAULTS setObject:requestId forKey:kMSUpdateTokenRequestIdKey];
  BOOL result = [self.sut openURL:url];

  // Then
  XCTAssertTrue(result);
  OCMVerify([distributeMock checkLatestRelease:token distributionGroupId:OCMOCK_ANY releaseHash:kMSTestReleaseHash]);

  // If
  url = [NSURL
      URLWithString:[NSString stringWithFormat:@"%@://?request_id=%@&distribution_group_id=%@", scheme, requestId, distributionGroupId]];

  // When
  [MS_APP_CENTER_USER_DEFAULTS setObject:requestId forKey:kMSUpdateTokenRequestIdKey];
  result = [self.sut openURL:url];

  // Then
  XCTAssertTrue(result);
  OCMVerify([distributeMock checkLatestRelease:nil distributionGroupId:distributionGroupId releaseHash:kMSTestReleaseHash]);
  OCMVerify([self.distributeInfoTrackerMock updateDistributionGroupId:distributionGroupId]);

  // Not allow checkLatestRelease more.
  OCMReject([distributeMock checkLatestRelease:OCMOCK_ANY distributionGroupId:OCMOCK_ANY releaseHash:OCMOCK_ANY]);

  // If
  [self.sut setEnabled:NO];

  // When
  [self.sut openURL:url];

  // Then
  XCTAssertTrue(result);

  // Clear
  [utilityMock stopMocking];
  [appCenterMock stopMocking];
  [distributeMock stopMocking];
}

- (void)testOpenUrlWithFirstSessionLogUpdate {

  // If
  NSString *requestId = @"FIRST-REQUEST";
  NSString *distributionGroupId = @"GROUP-ID";
  NSString *token = @"TOKEN";
  NSString *scheme = [NSString stringWithFormat:kMSDefaultCustomSchemeFormat, kMSTestAppSecret];

  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock checkLatestRelease:OCMOCK_ANY distributionGroupId:OCMOCK_ANY releaseHash:kMSTestReleaseHash]).andDo(nil);
  OCMStub([distributeMock sharedInstance]).andReturn(distributeMock);
  id appCenterMock = OCMClassMock([MSAppCenter class]);
  OCMStub([appCenterMock isConfigured]).andReturn(YES);
  id utilityMock = [self mockMSPackageHash];

  // Disable for now to bypass initializing ingestion.
  [self.sut setEnabled:NO];
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                        appSecret:kMSTestAppSecret
          transmissionTargetToken:nil
                  fromApplication:YES];
  id channelUnitMock = OCMProtocolMock(@protocol(MSChannelUnitProtocol));
  self.sut.channelUnit = channelUnitMock;
  __block MSDistributionStartSessionLog *log;
  __block int invocations = 0;

  // FIXME: This stub used `[OCMArg isKindOfClass:[MSDistributionStartSessionLog class]]` but it causes object retain issue
  // after finishing test. Use `checkWithBlock:` for now to have the test run without the issue. This is an unexpected behavior
  // happening when `MSSessionContext` is used along with `MSChannelUnitDefault` mock.
  OCMStub([channelUnitMock enqueueItem:[OCMArg checkWithBlock:^BOOL(id value) {
                             return [value isKindOfClass:[MSDistributionStartSessionLog class]];
                           }]
                                 flags:MSFlagsDefault])
      .andDo(^(NSInvocation *invocation) {
        ++invocations;
        [invocation getArgument:&log atIndex:2];
      });

  // Enable again.
  [self.sut setEnabled:YES];

  // If
  NSURL *url = [NSURL
      URLWithString:[NSString stringWithFormat:@"%@://?request_id=%@&distribution_group_id=%@", scheme, requestId, distributionGroupId]];

  // When
  [[MSSessionContext sharedInstance] setSessionId:@"Session1"];
  [MS_APP_CENTER_USER_DEFAULTS setObject:requestId forKey:kMSUpdateTokenRequestIdKey];
  BOOL result = [self.sut openURL:url];

  // Then
  XCTAssertTrue(result);
  XCTAssertEqual(invocations, 1);
  XCTAssertNotNil(log);
  OCMVerify([self.distributeInfoTrackerMock updateDistributionGroupId:distributionGroupId]);
  XCTAssertEqualObjects([MS_APP_CENTER_USER_DEFAULTS objectForKey:kMSDistributionGroupIdKey], distributionGroupId);
  [MSSessionContext resetSharedInstance];
  invocations = 0;

  // If
  url = [NSURL
      URLWithString:[NSString stringWithFormat:@"%@://?request_id=%@&distribution_group_id=%@", scheme, requestId, distributionGroupId]];

  // When
  [[MSSessionContext sharedInstance] setSessionId:nil];
  [MS_APP_CENTER_USER_DEFAULTS setObject:requestId forKey:kMSUpdateTokenRequestIdKey];
  result = [self.sut openURL:url];

  // Then
  XCTAssertTrue(result);
  XCTAssertEqual(invocations, 0);
  OCMReject([self.distributeInfoTrackerMock updateDistributionGroupId:OCMOCK_ANY]);

  // If
  url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://?request_id=%@&update_token=%@", scheme, requestId, token]];

  // When
  [MS_APP_CENTER_USER_DEFAULTS setObject:requestId forKey:kMSUpdateTokenRequestIdKey];
  result = [self.sut openURL:url];

  // Then
  XCTAssertTrue(result);
  XCTAssertEqual(invocations, 0);
  OCMReject([self.distributeInfoTrackerMock updateDistributionGroupId:OCMOCK_ANY]);

  // If
  [self.sut setEnabled:NO];

  // When
  [self.sut openURL:url];

  // Then
  XCTAssertTrue(result);
  XCTAssertEqual(invocations, 0);
  OCMReject([self.distributeInfoTrackerMock updateDistributionGroupId:OCMOCK_ANY]);

  // Clear
  [channelUnitMock stopMocking];
  [utilityMock stopMocking];
  [appCenterMock stopMocking];
  [distributeMock stopMocking];
}

- (void)testOpenUrlWithUpdateSetupFailure {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Start update processed"];
  NSString *scheme = [NSString stringWithFormat:kMSDefaultCustomSchemeFormat, kMSTestAppSecret];
  NSString *requestId = @"FIRST-REQUEST";
  NSString *updateSetupFailureMessage = @"in-app updates setup failed";
  id distributeMock = OCMPartialMock(self.sut);
  OCMReject([distributeMock checkLatestRelease:OCMOCK_ANY distributionGroupId:OCMOCK_ANY releaseHash:OCMOCK_ANY]);
  OCMStub([distributeMock sharedInstance]).andReturn(distributeMock);
  id appCenterMock = OCMClassMock([MSAppCenter class]);
  OCMStub([appCenterMock isConfigured]).andReturn(YES);
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                        appSecret:kMSTestAppSecret
          transmissionTargetToken:nil
                  fromApplication:YES];

  // If
  NSURL *url = [NSURL
      URLWithString:[NSString stringWithFormat:@"%@://?request_id=%@&update_setup_failed=%@", scheme, requestId,
                                               [updateSetupFailureMessage
                                                   stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet
                                                                                                          URLHostAllowedCharacterSet]]]];

  // When
  [self.settingsMock setObject:requestId forKey:kMSUpdateTokenRequestIdKey];
  BOOL result = [self.sut openURL:url];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 // Then
                                 XCTAssertTrue(result);
                                 OCMVerify([distributeMock showUpdateSetupFailedAlert:updateSetupFailureMessage]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  // Clear
  [distributeMock stopMocking];
  [appCenterMock stopMocking];
}

- (void)testApplyEnabledStateTrueForDebugConfig {

  // If
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock checkLatestRelease:OCMOCK_ANY distributionGroupId:OCMOCK_ANY releaseHash:OCMOCK_ANY]).andDo(nil);
  OCMStub([distributeMock requestInstallInformationWith:OCMOCK_ANY]).andDo(nil);

  // When
  [self.sut applyEnabledState:YES];

  // Then
  XCTAssertNil([self.settingsMock objectForKey:kMSUpdateTokenRequestIdKey]);

  // When
  [self.sut applyEnabledState:NO];

  // Then
  XCTAssertNil([self.settingsMock objectForKey:kMSUpdateTokenRequestIdKey]);
  XCTAssertNil([self.settingsMock objectForKey:kMSSDKHasLaunchedWithDistribute]);
  XCTAssertNil([self.settingsMock objectForKey:kMSPostponedTimestampKey]);

  // Clear
  [distributeMock stopMocking];
}

- (void)testApplyEnabledStateTrue {

  // If
  NSDictionary<NSString *, id> *plist = @{@"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1"};
  OCMStub([self.bundleMock infoDictionary]).andReturn(plist);
  id distributeMock = OCMPartialMock(self.sut);
  [self.sut setUpdateTrack:MSUpdateTrackPrivate];
  OCMStub([distributeMock checkLatestRelease:OCMOCK_ANY distributionGroupId:OCMOCK_ANY releaseHash:OCMOCK_ANY]).andDo(nil);
  OCMStub([distributeMock requestInstallInformationWith:OCMOCK_ANY]).andDo(nil);
  id utilityMock = [self mockMSPackageHash];

  // When
  [self.sut applyEnabledState:YES];

  // Then
  OCMVerify([distributeMock requestInstallInformationWith:kMSTestReleaseHash]);

  // If, private distribution
  [MSKeychainUtil storeString:@"UpdateToken" forKey:kMSUpdateTokenKey];
  [self.settingsMock setObject:@"DistributionGroupId" forKey:kMSDistributionGroupIdKey];
  [distributeMock setValue:@(NO) forKey:@"updateFlowInProgress"];

  // When
  [self.sut applyEnabledState:YES];

  // Then
  OCMVerify([distributeMock checkLatestRelease:@"UpdateToken" distributionGroupId:@"DistributionGroupId" releaseHash:kMSTestReleaseHash]);

  // If, public distribution
  [MSKeychainUtil deleteStringForKey:kMSUpdateTokenKey];
  [distributeMock setValue:@(NO) forKey:@"updateFlowInProgress"];

  // When
  [self.sut applyEnabledState:YES];

  // Then
  OCMVerify([distributeMock checkLatestRelease:@"UpdateToken" distributionGroupId:@"DistributionGroupId" releaseHash:kMSTestReleaseHash]);

  // If
  [self.settingsMock setObject:@"RequestID" forKey:kMSUpdateTokenRequestIdKey];
  [distributeMock setValue:@(NO) forKey:@"updateFlowInProgress"];

  // Then
  XCTAssertNotNil([self.settingsMock objectForKey:kMSUpdateTokenRequestIdKey]);

  // When
  [self.sut applyEnabledState:NO];

  // Then
  XCTAssertNil([self.settingsMock objectForKey:kMSUpdateTokenRequestIdKey]);
  XCTAssertNil([self.settingsMock objectForKey:kMSSDKHasLaunchedWithDistribute]);
  XCTAssertNil([self.settingsMock objectForKey:kMSPostponedTimestampKey]);
  XCTAssertNil([MSKeychainUtil stringForKey:kMSUpdateTokenKey statusCode:nil]);

  // Clear
  [distributeMock stopMocking];
  [utilityMock stopMocking];
}

- (void)testCheckForUpdatesAllowedAllConditionsMet {

  // If
  [MSDistributeTestUtil unMockUpdatesAllowedConditions];
  id appCenterMock = OCMClassMock([MSAppCenter class]);
  id distributeMock = OCMPartialMock(self.sut);
  id guidedAccessMock = OCMClassMock([MSGuidedAccessUtil class]);
  [self.sut setUpdateTrack:MSUpdateTrackPrivate];
  OCMStub([distributeMock checkLatestRelease:OCMOCK_ANY distributionGroupId:OCMOCK_ANY releaseHash:OCMOCK_ANY]).andDo(nil);
  OCMStub([distributeMock requestInstallInformationWith:OCMOCK_ANY]).andDo(nil);
  id utilityMock = [self mockMSPackageHash];
  OCMStub([guidedAccessMock isGuidedAccessEnabled]).andReturn(NO);

  // When
  OCMStub([appCenterMock isDebuggerAttached]).andReturn(NO);
  OCMStub([utilityMock currentAppEnvironment]).andReturn(MSEnvironmentOther);

  // Then
  XCTAssertTrue([distributeMock checkForUpdatesAllowed]);

  // When
  [self.sut applyEnabledState:YES];

  // Then
  OCMVerify([distributeMock requestInstallInformationWith:kMSTestReleaseHash]);

  // Clear
  [distributeMock stopMocking];
  [appCenterMock stopMocking];
  [utilityMock stopMocking];
  [guidedAccessMock stopMocking];
}

- (void)testRequestInstallInformationNotifiesUserNonCheck {

  // If
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock checkForUpdatesAllowed]).andReturn(NO);
  id reachabilityMock = OCMClassMock([MS_Reachability class]);
  OCMStub([reachabilityMock reachabilityForInternetConnection]).andReturn(NO);

  // When
  [self.sut requestInstallInformationWith:OCMOCK_ANY];

  // Then
  // This is only called when checkForUpdatesAllowed returns YES.
  OCMReject([reachabilityMock reachabilityForInternetConnection]);

  // Clear
  [distributeMock stopMocking];
}

- (void)testOpenURLInAuthenticationSession API_AVAILABLE(ios(11)) {

  // If
  NSURL *fakeURL = [NSURL URLWithString:kMSDefaultURLFormat];
  id appCenterMock = OCMClassMock([MSAppCenter class]);
  OCMStub([appCenterMock sharedInstance]).andReturn(appCenterMock);
  OCMStub([appCenterMock isSdkConfigured]).andReturn(YES);
  OCMStub([appCenterMock isConfigured]).andReturn(YES);

  // Recreate service.
  MSDistribute *distribute = [MSDistribute new];
  distribute.distributeInfoTracker = self.distributeInfoTrackerMock;
  [distribute startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                          appSecret:kMSTestAppSecret
            transmissionTargetToken:nil
                    fromApplication:YES];

  // Then
  XCTAssertNil(distribute.authenticationSession);

  // When
  [distribute openURLInAuthenticationSessionWith:fakeURL];

  // Then
  XCTAssertNotNil(distribute.authenticationSession);
  XCTAssert([distribute.authenticationSession isKindOfClass:[SFAuthenticationSession class]]);

  // Clear
  [appCenterMock stopMocking];
}

- (void)testCheckForUpdatesAllowedDebuggerAttached {

  // When
  [MSDistributeTestUtil unMockUpdatesAllowedConditions];
  id appCenterMock = OCMClassMock([MSAppCenter class]);
  id utilityMock = OCMClassMock([MSUtility class]);
  id guidedAccessMock = OCMClassMock([MSGuidedAccessUtil class]);
  OCMStub([appCenterMock isDebuggerAttached]).andReturn(YES);
  OCMStub([utilityMock currentAppEnvironment]).andReturn(MSEnvironmentOther);
  OCMStub([guidedAccessMock isGuidedAccessEnabled]).andReturn(NO);

  // Then
  XCTAssertFalse([self.sut checkForUpdatesAllowed]);

  // Clear
  [appCenterMock stopMocking];
  [utilityMock stopMocking];
  [guidedAccessMock stopMocking];
}

- (void)testCheckForUpdatesAllowedInvalidEnvironment {

  // When
  [MSDistributeTestUtil unMockUpdatesAllowedConditions];
  id appCenterMock = OCMClassMock([MSAppCenter class]);
  id utilityMock = OCMClassMock([MSUtility class]);
  id guidedAccessMock = OCMClassMock([MSGuidedAccessUtil class]);
  OCMStub([appCenterMock isDebuggerAttached]).andReturn(NO);
  OCMStub([utilityMock currentAppEnvironment]).andReturn(MSEnvironmentTestFlight);
  OCMStub([guidedAccessMock isGuidedAccessEnabled]).andReturn(NO);

  // Then
  XCTAssertFalse([self.sut checkForUpdatesAllowed]);

  // Clear
  [appCenterMock stopMocking];
  [utilityMock stopMocking];
  [guidedAccessMock stopMocking];
}

- (void)testCheckForUpdatesAllowedInGuidedAccessMode {

  // When
  [MSDistributeTestUtil unMockUpdatesAllowedConditions];
  id appCenterMock = OCMClassMock([MSAppCenter class]);
  id utilityMock = OCMClassMock([MSUtility class]);
  id guidedAccessMock = OCMClassMock([MSGuidedAccessUtil class]);
  OCMStub([appCenterMock isDebuggerAttached]).andReturn(NO);
  OCMStub([utilityMock currentAppEnvironment]).andReturn(MSEnvironmentOther);
  OCMStub([guidedAccessMock isGuidedAccessEnabled]).andReturn(YES);

  // Then
  XCTAssertFalse([self.sut checkForUpdatesAllowed]);

  // Clear
  [appCenterMock stopMocking];
  [utilityMock stopMocking];
  [guidedAccessMock stopMocking];
}

- (void)testSetupUpdatesWithPreviousFailureOnSamePackageHashForPrivateTrack {

  // If
  [MSDistributeTestUtil unMockUpdatesAllowedConditions];
  id appCenterMock = OCMClassMock([MSAppCenter class]);
  id distributeMock = OCMPartialMock(self.sut);
  id guidedAccessMock = OCMClassMock([MSGuidedAccessUtil class]);
  id utilityMock = [self mockMSPackageHash];
  [self.sut setUpdateTrack:MSUpdateTrackPrivate];
  OCMStub([appCenterMock isDebuggerAttached]).andReturn(NO);
  OCMStub([utilityMock currentAppEnvironment]).andReturn(MSEnvironmentOther);
  OCMStub([guidedAccessMock isGuidedAccessEnabled]).andReturn(NO);
  [self.settingsMock setObject:kMSTestReleaseHash forKey:kMSUpdateSetupFailedPackageHashKey];

  // When
  [self.sut applyEnabledState:YES];

  // Then
  OCMVerify([distributeMock requestInstallInformationWith:kMSTestReleaseHash]);
  OCMReject([distributeMock buildTokenRequestURLWithAppSecret:OCMOCK_ANY releaseHash:kMSTestReleaseHash isTesterApp:false]);
  OCMReject([distributeMock openUrlInAuthenticationSessionOrSafari:OCMOCK_ANY]);
  XCTAssertEqual([self.settingsMock objectForKey:kMSUpdateSetupFailedPackageHashKey], kMSTestReleaseHash);

  // Clear
  [distributeMock stopMocking];
  [appCenterMock stopMocking];
  [utilityMock stopMocking];
  [guidedAccessMock stopMocking];
}

- (void)testSetupUpdatesWithPreviousFailureOnDifferentPackageHashForPrivateTrack {

  // If
  [MSDistributeTestUtil unMockUpdatesAllowedConditions];
  id reachabilityMock = OCMClassMock([MS_Reachability class]);
  id appCenterMock = OCMClassMock([MSAppCenter class]);
  id distributeMock = OCMPartialMock(self.sut);
  id utilityMock = [self mockMSPackageHash];
  id guidedAccessMock = OCMClassMock([MSGuidedAccessUtil class]);
  OCMStub([reachabilityMock reachabilityForInternetConnection]).andReturn(reachabilityMock);
  OCMStub([reachabilityMock currentReachabilityStatus]).andReturn(ReachableViaWiFi);
  [self.sut setUpdateTrack:MSUpdateTrackPrivate];
  OCMStub([appCenterMock isDebuggerAttached]).andReturn(NO);
  OCMStub([utilityMock currentAppEnvironment]).andReturn(MSEnvironmentOther);
  OCMStub([guidedAccessMock isGuidedAccessEnabled]).andReturn(NO);
  [self.settingsMock setObject:@"different-release-hash" forKey:kMSUpdateSetupFailedPackageHashKey];

  // Then
  XCTAssertNotNil([self.settingsMock objectForKey:kMSUpdateSetupFailedPackageHashKey]);
  XCTAssertNotEqual([self.settingsMock objectForKey:kMSUpdateSetupFailedPackageHashKey], kMSTestReleaseHash);

  // When
  [self.sut applyEnabledState:YES];

  // Then
  OCMVerify([distributeMock requestInstallInformationWith:kMSTestReleaseHash]);
  OCMVerify([distributeMock buildTokenRequestURLWithAppSecret:OCMOCK_ANY releaseHash:kMSTestReleaseHash isTesterApp:false]);
  OCMReject([distributeMock openUrlInAuthenticationSessionOrSafari:OCMOCK_ANY]);
  XCTAssertNil([self.settingsMock objectForKey:kMSUpdateSetupFailedPackageHashKey]);

  // Clear
  [distributeMock stopMocking];
  [appCenterMock stopMocking];
  [utilityMock stopMocking];
  [guidedAccessMock stopMocking];
}

- (void)testSetupUpdatesWithPreviousFailureOnSamePackageHashWhenItChangedToPublicTrack {

  // If
  [MSDistributeTestUtil unMockUpdatesAllowedConditions];
  id appCenterMock = OCMClassMock([MSAppCenter class]);
  id distributeMock = OCMPartialMock(self.sut);
  id guidedAccessMock = OCMClassMock([MSGuidedAccessUtil class]);
  id ingestionMock = OCMClassMock([MSDistributeIngestion class]);
  id utilityMock = [self mockMSPackageHash];
  [self.sut setUpdateTrack:MSUpdateTrackPublic];
  self.sut.ingestion = ingestionMock;
  OCMStub([appCenterMock isDebuggerAttached]).andReturn(NO);
  OCMStub([utilityMock currentAppEnvironment]).andReturn(MSEnvironmentOther);
  OCMStub([guidedAccessMock isGuidedAccessEnabled]).andReturn(NO);
  [self.settingsMock setObject:kMSTestReleaseHash forKey:kMSUpdateSetupFailedPackageHashKey];

  // When
  [self.sut applyEnabledState:YES];

  // Then
  OCMVerify([ingestionMock checkForPublicUpdateWithQueryStrings:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
  OCMReject([distributeMock openUrlInAuthenticationSessionOrSafari:OCMOCK_ANY]);
  XCTAssertEqual([self.settingsMock objectForKey:kMSUpdateSetupFailedPackageHashKey], kMSTestReleaseHash);

  // Clear
  [distributeMock stopMocking];
  [appCenterMock stopMocking];
  [utilityMock stopMocking];
  [guidedAccessMock stopMocking];
  [ingestionMock stopMocking];
}

- (void)testSetupUpdatesWithPreviousFailureOnDifferentPackageHashWhenItChangedToPublicTrack {

  // If
  [MSDistributeTestUtil unMockUpdatesAllowedConditions];
  id reachabilityMock = OCMClassMock([MS_Reachability class]);
  id appCenterMock = OCMClassMock([MSAppCenter class]);
  id distributeMock = OCMPartialMock(self.sut);
  id guidedAccessMock = OCMClassMock([MSGuidedAccessUtil class]);
  id ingestionMock = OCMClassMock([MSDistributeIngestion class]);
  id utilityMock = [self mockMSPackageHash];
  OCMStub([reachabilityMock reachabilityForInternetConnection]).andReturn(reachabilityMock);
  OCMStub([reachabilityMock currentReachabilityStatus]).andReturn(ReachableViaWiFi);
  [self.sut setUpdateTrack:MSUpdateTrackPublic];
  self.sut.ingestion = ingestionMock;
  OCMStub([appCenterMock isDebuggerAttached]).andReturn(NO);
  OCMStub([utilityMock currentAppEnvironment]).andReturn(MSEnvironmentOther);
  OCMStub([guidedAccessMock isGuidedAccessEnabled]).andReturn(NO);
  [self.settingsMock setObject:@"different-release-hash" forKey:kMSUpdateSetupFailedPackageHashKey];

  // Then
  XCTAssertNotNil([self.settingsMock objectForKey:kMSUpdateSetupFailedPackageHashKey]);
  XCTAssertNotEqual([self.settingsMock objectForKey:kMSUpdateSetupFailedPackageHashKey], kMSTestReleaseHash);

  // When
  [self.sut applyEnabledState:YES];

  // Then
  OCMVerify([ingestionMock checkForPublicUpdateWithQueryStrings:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
  OCMReject([distributeMock openUrlInAuthenticationSessionOrSafari:OCMOCK_ANY]);
  XCTAssertNotNil([self.settingsMock objectForKey:kMSUpdateSetupFailedPackageHashKey]);

  // Clear
  [distributeMock stopMocking];
  [appCenterMock stopMocking];
  [utilityMock stopMocking];
  [guidedAccessMock stopMocking];
  [ingestionMock stopMocking];
}

- (void)testBrowserNotOpenedWhenTesterAppUsedForUpdateSetup {

  // If
  id reachabilityMock = OCMClassMock([MS_Reachability class]);
  OCMStub([reachabilityMock reachabilityForInternetConnection]).andReturn(reachabilityMock);
  OCMStub([reachabilityMock currentReachabilityStatus]).andReturn(ReachableViaWiFi);
  [MSDistributeTestUtil unMockUpdatesAllowedConditions];
  id appCenterMock = OCMClassMock([MSAppCenter class]);
  id distributeMock = OCMPartialMock(self.sut);
  id guidedAccessMock = OCMClassMock([MSGuidedAccessUtil class]);
  id utilityMock = [self mockMSPackageHash];
  OCMStub([guidedAccessMock isGuidedAccessEnabled]).andReturn(NO);
  [self.sut setUpdateTrack:MSUpdateTrackPrivate];
  OCMStub([distributeMock buildTokenRequestURLWithAppSecret:OCMOCK_ANY releaseHash:OCMOCK_ANY isTesterApp:false])
      .andReturn([NSURL URLWithString:@"https://some_url"]);
  OCMStub([distributeMock buildTokenRequestURLWithAppSecret:OCMOCK_ANY releaseHash:OCMOCK_ANY isTesterApp:true])
      .andReturn([NSURL URLWithString:@"some_url://"]);
  OCMStub([distributeMock openUrlUsingSharedApp:OCMOCK_ANY]).andReturn(YES);
  OCMReject([distributeMock openUrlInAuthenticationSessionOrSafari:OCMOCK_ANY]);
  XCTestExpectation *expectation = [self expectationWithDescription:@"Start update processed"];

  // When
  OCMStub([appCenterMock isDebuggerAttached]).andReturn(NO);
  OCMStub([utilityMock currentAppEnvironment]).andReturn(MSEnvironmentOther);

  // Then
  XCTAssertTrue([distributeMock checkForUpdatesAllowed]);

  // When
  [self.sut applyEnabledState:YES];
  [self.sut startUpdateOnStart:NO];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });

  // Then
  OCMVerify([distributeMock requestInstallInformationWith:kMSTestReleaseHash]);
  OCMVerify([distributeMock buildTokenRequestURLWithAppSecret:OCMOCK_ANY releaseHash:kMSTestReleaseHash isTesterApp:true]);
  OCMVerify([distributeMock buildTokenRequestURLWithAppSecret:OCMOCK_ANY releaseHash:kMSTestReleaseHash isTesterApp:false]);
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 // Then
                                 OCMVerify([distributeMock openUrlUsingSharedApp:OCMOCK_ANY]);
                                 OCMVerifyAll(distributeMock);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  // Clear
  [distributeMock stopMocking];
  [appCenterMock stopMocking];
  [utilityMock stopMocking];
  [guidedAccessMock stopMocking];
}

- (void)testNotDeleteUpdateToken {

  // If
  [MS_APP_CENTER_USER_DEFAULTS setObject:@1 forKey:kMSSDKHasLaunchedWithDistribute];
  id keychainMock = OCMClassMock([MSKeychainUtil class]);
  OCMReject([keychainMock deleteStringForKey:kMSUpdateTokenKey]);

  // When
  [MSDistribute new];

  // Clear
  [keychainMock stopMocking];
}

- (void)testDeleteUpdateTokenAfterReinstall {

  // If
  id keychainMock = OCMClassMock([MSKeychainUtil class]);

  // When
  [MSDistribute new];

  // Then
  OCMVerify([keychainMock deleteStringForKey:kMSUpdateTokenKey]);
  XCTAssertTrue([[self.settingsMock objectForKey:kMSSDKHasLaunchedWithDistribute] boolValue]);

  // Clear
  [keychainMock stopMocking];
}

- (void)testWithoutNetwork {

  // If
  id reachabilityMock = OCMClassMock([MS_Reachability class]);
  OCMStub([reachabilityMock reachabilityForInternetConnection]).andReturn(reachabilityMock);
  OCMStub([reachabilityMock currentReachabilityStatus]).andReturn(NotReachable);
  [MSMockReachability setCurrentNetworkStatus:NotReachable];
  id distributeMock = OCMPartialMock(self.sut);
  OCMReject([distributeMock buildTokenRequestURLWithAppSecret:OCMOCK_ANY releaseHash:kMSTestReleaseHash isTesterApp:false]);

  // We should not touch UI in a unit testing environment.
  OCMStub([distributeMock openURLInSafariViewControllerWith:OCMOCK_ANY fromClass:OCMOCK_ANY]).andDo(nil);

  // When
  [self.sut requestInstallInformationWith:kMSTestReleaseHash];

  // Clear
  [distributeMock stopMocking];
}

- (void)testPackageHash {

  // If
  // cd55e7a9-7ad1-4ca6-b722-3d133f487da9:1.0:1 ->
  // 1ddf47f8dda8928174c419d530adcc13bb63cebfaf823d83ad5269b41e638ef4
  NSDictionary<NSString *, id> *plist = @{@"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1"};
  OCMStub([self.bundleMock infoDictionary]).andReturn(plist);

  // When
  NSString *hash = MSPackageHash();

  // Then
  assertThat(hash, equalTo(@"1ddf47f8dda8928174c419d530adcc13bb63cebfaf823d83ad5269b41e638ef4"));
}

- (void)testDismissEmbeddedSafari {

  // If
  XCTestExpectation *safariDismissedExpectation = [self expectationWithDescription:@"Safari dismissed processed"];
  id viewControllerMock = OCMClassMock([UIViewController class]);
  OCMReject([viewControllerMock dismissViewControllerAnimated:(BOOL)OCMOCK_ANY completion:OCMOCK_ANY]);
  self.sut.safariHostingViewController = nil;

  // When
  [self.sut dismissEmbeddedSafari];
  dispatch_async(dispatch_get_main_queue(), ^{
    [safariDismissedExpectation fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 // Then
                                 OCMVerifyAll(viewControllerMock);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
  [viewControllerMock stopMocking];
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
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 OCMVerify([viewControllerMock dismissViewControllerAnimated:YES completion:OCMOCK_ANY]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
  [viewControllerMock stopMocking];
}

- (void)testDismissEmbeddedSafariWhenOpenURL {

  // If
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock sharedInstance]).andReturn(distributeMock);
  OCMStub([distributeMock isEnabled]).andReturn(YES);
  OCMStub([distributeMock checkLatestRelease:OCMOCK_ANY distributionGroupId:OCMOCK_ANY releaseHash:OCMOCK_ANY]).andDo(nil);
  self.sut.appSecret = kMSTestAppSecret;
  [MS_APP_CENTER_USER_DEFAULTS setObject:@"FIRST-REQUEST" forKey:kMSUpdateTokenRequestIdKey];
  NSDictionary<NSString *, id> *plist = @{@"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1"};
  OCMStub([self.bundleMock infoDictionary]).andReturn(plist);
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://?request_id=FIRST-REQUEST&update_token=token",
                                                               [NSString stringWithFormat:kMSDefaultCustomSchemeFormat, kMSTestAppSecret]]];
  XCTestExpectation *safariDismissedExpectation = [self expectationWithDescription:@"Safari dismissed processed"];
  id viewControllerMock = OCMClassMock([UIViewController class]);
  self.sut.safariHostingViewController = viewControllerMock;

  // When
  [self.sut openURL:url];
  dispatch_async(dispatch_get_main_queue(), ^{
    [safariDismissedExpectation fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 OCMVerify([viewControllerMock dismissViewControllerAnimated:YES completion:OCMOCK_ANY]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
  [distributeMock stopMocking];
  [viewControllerMock stopMocking];
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
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 OCMVerify([viewControllerMock dismissViewControllerAnimated:YES completion:OCMOCK_ANY]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
  [viewControllerMock stopMocking];
}

- (void)testShowDistributeDisabledAlert {

  // When
  XCTestExpectation *expectation = [self expectationWithDescription:@"Distribute disabled alert has been displayed"];
  [self.sut showDistributeDisabledAlert];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });

  [self waitForExpectationsWithTimeout:1
                               handler:^(__attribute__((unused)) NSError *error) {
                                 // Then
                                 OCMVerify([self.alertControllerMock alertControllerWithTitle:OCMOCK_ANY message:nil]);
                                 OCMVerify([self.alertControllerMock addCancelActionWithTitle:OCMOCK_ANY handler:OCMOCK_ANY]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testStartDownload {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Start download"];
  MSReleaseDetails *details = [MSReleaseDetails new];
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock closeApp]).andDo(nil);
  id utilityMock = OCMClassMock([MSUtility class]);
  OCMStub(ClassMethod([utilityMock sharedAppOpenUrl:OCMOCK_ANY options:OCMOCK_ANY completionHandler:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        void (^handler)(MSOpenURLState);
        [invocation getArgument:&handler atIndex:4];
        handler(MSOpenURLStateUnknown);
      });

  // When
  details.mandatoryUpdate = YES;
  [self.sut startDownload:details];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(__attribute__((unused)) NSError *error) {
                                 OCMVerify([distributeMock closeApp]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  // Clear
  [distributeMock stopMocking];
  [utilityMock stopMocking];
}

- (void)testStartDownloadSucceeded {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Start download"];
  MSReleaseDetails *details = [MSReleaseDetails new];
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock closeApp]).andDo(nil);
  id utilityMock = OCMClassMock([MSUtility class]);
  OCMStub(ClassMethod([utilityMock sharedAppOpenUrl:OCMOCK_ANY options:OCMOCK_ANY completionHandler:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        void (^handler)(MSOpenURLState);
        [invocation getArgument:&handler atIndex:4];
        handler(MSOpenURLStateSucceed);
      });

  // When
  details.mandatoryUpdate = YES;
  [self.sut startDownload:details];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(__attribute__((unused)) NSError *error) {
                                 OCMVerify([distributeMock closeApp]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  // Clear
  [distributeMock stopMocking];
  [utilityMock stopMocking];
}

- (void)testStartDownloadFailed {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Start download"];
  MSReleaseDetails *details = [MSReleaseDetails new];
  id distributeMock = OCMPartialMock(self.sut);
  OCMReject([distributeMock closeApp]);
  OCMStub([distributeMock closeApp]).andDo(nil);
  id utilityMock = OCMClassMock([MSUtility class]);
  OCMStub(ClassMethod([utilityMock sharedAppOpenUrl:OCMOCK_ANY options:OCMOCK_ANY completionHandler:OCMOCK_ANY]))
      .andDo(^(NSInvocation *invocation) {
        void (^handler)(MSOpenURLState);
        [invocation getArgument:&handler atIndex:4];
        handler(MSOpenURLStateFailed);
      });

  // When
  details.mandatoryUpdate = YES;
  [self.sut startDownload:details];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(__attribute__((unused)) NSError *error) {
                                 OCMVerifyAll(distributeMock);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  // Clear
  [distributeMock stopMocking];
  [utilityMock stopMocking];
}

- (void)testServiceNameIsCorrect {
  XCTAssertEqual([MSDistribute serviceName], kMSDistributeServiceName);
}

- (void)testUpdateURLWithUnregisteredScheme {

  // If
  NSArray *bundleArray = @[ @{kMSCFBundleURLSchemes : @[ @"appcenter-IAMSUPERSECRET" ]} ];
  OCMStub([self.bundleMock objectForInfoDictionaryKey:kMSCFBundleURLTypes]).andReturn(bundleArray);

  // When
  NSURL *url = [self.sut buildTokenRequestURLWithAppSecret:kMSTestAppSecret releaseHash:kMSTestReleaseHash isTesterApp:false];

  // Then
  assertThat(url, nilValue());
}

- (void)testIsNewerVersionFunction {
  NSDictionary<NSString *, id> *plist = @{@"CFBundleShortVersionString" : @"10.0", @"CFBundleVersion" : @"10"};
  OCMStub([self.bundleMock infoDictionary]).andReturn(plist);

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
  sameRelease.packageHashes = @[ MSPackageHash() ];

  // When
  result = [[MSDistribute sharedInstance] isNewerVersion:sameRelease];

  // Then
  XCTAssertFalse(result);
}

- (void)testStartUpdateWhenApplicationDidBecomeActive {

  // If
  id notificationCenterMock = OCMPartialMock([NSNotificationCenter new]);
  OCMStub([notificationCenterMock defaultCenter]).andReturn(notificationCenterMock);
  MSDistribute *distribute = [MSDistribute new];
  id distributeMock = OCMPartialMock(distribute);
  __block int startUpdateCounter = 0;
  OCMStub([distributeMock startUpdateOnStart:OCMOCK_ANY]).andDo(^(__attribute((unused)) NSInvocation *invocation) {
    startUpdateCounter++;
  });

  // When
  id appCenterMock = OCMClassMock([MSAppCenter class]);
  OCMStub([appCenterMock sharedInstance]).andReturn(appCenterMock);
  OCMStub([appCenterMock isSdkConfigured]).andReturn(YES);
  OCMStub([appCenterMock isConfigured]).andReturn(YES);
  [distribute startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                          appSecret:kMSTestAppSecret
            transmissionTargetToken:nil
                    fromApplication:YES];

  // Then
  OCMVerify([distributeMock isEnabled]);
  XCTAssertEqual(startUpdateCounter, 1);

  // When
  [distribute setEnabled:NO];
  [notificationCenterMock postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];

  // Then
  OCMVerify([distributeMock isEnabled]);
  XCTAssertEqual(startUpdateCounter, 1);

  // When
  [distribute setEnabled:YES];

  // Then
  XCTAssertEqual(startUpdateCounter, 2);

  // When
  [notificationCenterMock postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];

  // Then
  OCMVerify([distributeMock isEnabled]);
  XCTAssertEqual(startUpdateCounter, 3);

  // Clear
  [appCenterMock stopMocking];
  [notificationCenterMock stopMocking];
  [distributeMock stopMocking];
}

- (void)testNotifyUpdateActionPostpone {

  // If
  id distributeMock = OCMPartialMock(self.sut);
  id utilityMock = OCMClassMock([MSUtility class]);
  double time = 1.1;
  OCMStub(ClassMethod([utilityMock nowInMilliseconds])).andReturn(time);
  [distributeMock setValue:OCMClassMock([MSReleaseDetails class]) forKey:@"releaseDetails"];
  [distributeMock setValue:@YES forKey:@"updateFlowInProgress"];

  // When
  [self.sut notifyUpdateAction:MSUpdateActionPostpone];

  // Then
  assertThat([self.settingsMock objectForKey:kMSPostponedTimestampKey], equalToLongLong((long long)time));
  XCTAssertFalse(self.sut.updateFlowInProgress);

  // Clear
  [distributeMock stopMocking];
  [utilityMock stopMocking];
}

- (void)testNotifyUpdateActionUpdateOneHash {

  // If
  id distributeMock = OCMPartialMock(self.sut);
  MSReleaseDetails *details = [MSReleaseDetails new];
  details.id = @1;
  details.packageHashes = @[ @"d5110dea0dc504b4d2924377fbbb2aaa9df8d4cc08e693b1160c389f5bc865a8" ];
  [distributeMock setValue:details forKey:@"releaseDetails"];
  [distributeMock setValue:@YES forKey:@"updateFlowInProgress"];

  // When
  [self.sut notifyUpdateAction:MSUpdateActionUpdate];

  // Then
  OCMVerify([distributeMock storeDownloadedReleaseDetails:details]);

  // Clear
  [distributeMock stopMocking];
}

- (void)testNotifyUpdateActionUpdateSeveralHashes {

  // If
  id distributeMock = OCMPartialMock(self.sut);
  MSReleaseDetails *details = [MSReleaseDetails new];
  details.id = @1;
  details.packageHashes = @[
    @"d5110dea0dc504b4d2924377fbbb2aaa9df8d4cc08e693b1160c389f5bc865a8",
    @"842d928f551d3bcae224221b563ce338839d897060d194a262ba3dfba4811c71", @"a7f2d4eed734b55a107d5a71195c8e18c21dcbde3d90c8b586c0af47b4dd4d6c"
  ];
  [distributeMock setValue:details forKey:@"releaseDetails"];
  [distributeMock setValue:@YES forKey:@"updateFlowInProgress"];

  // When
  [self.sut notifyUpdateAction:MSUpdateActionUpdate];

  // Then
  OCMVerify([distributeMock storeDownloadedReleaseDetails:details]);

  // Clear
  [distributeMock stopMocking];
}

- (void)testNotifyUpdateActionSelectedButDisabled {

  // If
  id distributeMock = OCMPartialMock(self.sut);
  MSReleaseDetails *details = [MSReleaseDetails new];
  [distributeMock setValue:details forKey:@"releaseDetails"];
  OCMStub([distributeMock isEnabled]).andReturn(NO);
  [distributeMock setValue:@YES forKey:@"updateFlowInProgress"];

  // This is very important that UIWindow doesn't allow accessing `makeKeyAndVisible` method from non-UI tests.
  // Stub `showDistributeDisabledAlert` to bypass UI related interaction.
  OCMStub([distributeMock showDistributeDisabledAlert]).andDo(nil);

  // When
  [self.sut notifyUpdateAction:MSUpdateActionUpdate];

  // Then
  OCMVerify([distributeMock showDistributeDisabledAlert]);

  // Clear
  [distributeMock stopMocking];
}

- (void)testNotifyUpdateActionTwice {

  // If
  id distributeMock = OCMPartialMock(self.sut);
  id utilityMock = OCMClassMock([MSUtility class]);
  double time = 1.1;
  OCMStub(ClassMethod([utilityMock nowInMilliseconds])).andReturn(time);
  [distributeMock setValue:OCMClassMock([MSReleaseDetails class]) forKey:@"releaseDetails"];
  [distributeMock setValue:@YES forKey:@"updateFlowInProgress"];

  // When
  [self.sut notifyUpdateAction:MSUpdateActionPostpone];

  // Then
  assertThat([self.settingsMock objectForKey:kMSPostponedTimestampKey], equalToLongLong((long long)time));

  // If
  [MS_APP_CENTER_USER_DEFAULTS removeObjectForKey:kMSPostponedTimestampKey];

  // When
  [self.sut notifyUpdateAction:MSUpdateActionPostpone];

  // Then
  XCTAssertNil([self.settingsMock objectForKey:kMSPostponedTimestampKey]);

  // Clear
  [distributeMock stopMocking];
  [utilityMock stopMocking];
}

- (void)testNotifyUpdateActionIgnoredWithoutReleaseDetails {

  // If
  id distributeMock = OCMPartialMock(self.sut);
  [distributeMock setValue:nil forKey:@"releaseDetails"];
  [distributeMock setValue:@YES forKey:@"updateFlowInProgress"];

  // When
  [self.sut notifyUpdateAction:MSUpdateActionPostpone];

  // Then
  XCTAssertNil([self.settingsMock objectForKey:kMSPostponedTimestampKey]);
  XCTAssertFalse(self.sut.updateFlowInProgress);

  // Clear
  [distributeMock stopMocking];
}

- (void)testNotifyUpdateActionIgnoredWhenUpdateFlowIsNotInProgress {

  // If
  id distributeMock = OCMPartialMock(self.sut);
  [distributeMock setValue:OCMClassMock([MSReleaseDetails class]) forKey:@"releaseDetails"];
  [distributeMock setValue:@NO forKey:@"updateFlowInProgress"];

  // When
  [self.sut notifyUpdateAction:MSUpdateActionPostpone];

  // Then
  XCTAssertNil([self.settingsMock objectForKey:kMSPostponedTimestampKey]);
  XCTAssertNil(self.sut.releaseDetails);

  // Clear
  [distributeMock stopMocking];
}

- (void)testSetDelegate {

  // Then
  XCTAssertNil([[MSDistribute sharedInstance] delegate]);

  // If
  id delegateMock = OCMProtocolMock(@protocol(MSDistributeDelegate));

  // When
  [MSDistribute setDelegate:delegateMock];
  id strongDelegate = [[MSDistribute sharedInstance] delegate];

  // Then
  XCTAssertEqual(strongDelegate, delegateMock);
}

- (void)testDefaultUpdateAlert {

  // If
  XCTestExpectation *showConfirmationAlertExpectation = [self expectationWithDescription:@"showConfirmationAlert Called."];

  MSReleaseDetails *details = [MSReleaseDetails new];
  details.status = @"available";
  id detailsMock = OCMPartialMock(details);
  OCMStub([detailsMock isValid]).andReturn(YES);
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock isNewerVersion:detailsMock]).andReturn(YES);
  OCMStub([distributeMock showConfirmationAlert:detailsMock]).andDo(nil);

  // When
  [self.sut handleUpdate:detailsMock];
  dispatch_async(dispatch_get_main_queue(), ^{
    [showConfirmationAlertExpectation fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 OCMVerify([distributeMock showConfirmationAlert:detailsMock]);
                               }];
  [detailsMock stopMocking];
  [distributeMock stopMocking];
}

- (void)testDefaultUpdateAlertWithDelegate {

  // If
  XCTestExpectation *showConfirmationAlertExpectation = [self expectationWithDescription:@"showConfirmationAlert Called."];

  MSReleaseDetails *details = [MSReleaseDetails new];
  details.status = @"available";
  id detailsMock = OCMPartialMock(details);
  OCMStub([detailsMock isValid]).andReturn(YES);
  id delegateMock = OCMProtocolMock(@protocol(MSDistributeDelegate));
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock isNewerVersion:detailsMock]).andReturn(YES);
  OCMStub([distributeMock showConfirmationAlert:detailsMock]).andDo(nil);

  // When
  OCMStub([delegateMock distribute:distributeMock releaseAvailableWithDetails:OCMOCK_ANY]).andReturn(NO);
  [self.sut setDelegate:delegateMock];
  [self.sut handleUpdate:detailsMock];
  dispatch_async(dispatch_get_main_queue(), ^{
    [showConfirmationAlertExpectation fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 OCMVerify([[distributeMock delegate] distribute:distributeMock releaseAvailableWithDetails:detailsMock]);
                                 OCMVerify([distributeMock showConfirmationAlert:detailsMock]);
                               }];
  [detailsMock stopMocking];
  [distributeMock stopMocking];
}

- (void)testCustomizedUpdateAlert {

  // If
  XCTestExpectation *showConfirmationAlertExpectation = [self expectationWithDescription:@"showConfirmationAlert Called."];

  MSReleaseDetails *details = [MSReleaseDetails new];
  details.status = @"available";
  id detailsMock = OCMPartialMock(details);
  OCMStub([detailsMock isValid]).andReturn(YES);
  id delegateMock = OCMProtocolMock(@protocol(MSDistributeDelegate));
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock isNewerVersion:detailsMock]).andReturn(YES);
  OCMStub([distributeMock showConfirmationAlert:detailsMock]).andDo(nil);

  // When
  OCMStub([delegateMock distribute:distributeMock releaseAvailableWithDetails:OCMOCK_ANY]).andReturn(YES);
  [self.sut setDelegate:delegateMock];
  [self.sut handleUpdate:detailsMock];
  dispatch_async(dispatch_get_main_queue(), ^{
    [showConfirmationAlertExpectation fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 OCMVerify([[distributeMock delegate] distribute:distributeMock releaseAvailableWithDetails:detailsMock]);
                               }];
  [detailsMock stopMocking];
  [distributeMock stopMocking];
}

- (void)testWillNotReportReleaseInstallForPrivateGroupWithoutStoredReleaseHash {

  // If
  [self.settingsMock removeObjectForKey:kMSDownloadedReleaseHashKey];

  // When
  NSMutableDictionary *reportingParametersForUpdatedRelease = [self.sut getReportingParametersForUpdatedRelease:NO
                                                                                    currentInstalledReleaseHash:kMSTestReleaseHash
                                                                                            distributionGroupId:kMSTestDistributionGroupId];

  // Then
  assertThat(reportingParametersForUpdatedRelease, nilValue());
}

- (void)testWillNotReportReleaseInstallForPrivateGroupWhenReleaseHashesDoNotMatch {

  // If
  [self.settingsMock setObject:@"ReleaseHash2" forKey:kMSDownloadedReleaseHashKey];

  // When
  NSMutableDictionary *reportingParametersForUpdatedRelease = [self.sut getReportingParametersForUpdatedRelease:NO
                                                                                    currentInstalledReleaseHash:kMSTestReleaseHash
                                                                                            distributionGroupId:kMSTestDistributionGroupId];

  // Then
  assertThat(reportingParametersForUpdatedRelease, nilValue());
}

- (void)testReportReleaseInstallForPrivateGroupWhenReleaseHashesMatch {

  // If
  [self.settingsMock setObject:@1 forKey:kMSDownloadedReleaseIdKey];
  [self.settingsMock setObject:kMSTestReleaseHash forKey:kMSDownloadedReleaseHashKey];

  // When
  NSMutableDictionary *reportingParametersForUpdatedRelease = [self.sut getReportingParametersForUpdatedRelease:NO
                                                                                    currentInstalledReleaseHash:kMSTestReleaseHash
                                                                                            distributionGroupId:kMSTestDistributionGroupId];

  // Then
  assertThat(reportingParametersForUpdatedRelease[kMSURLQueryDistributionGroupIdKey], equalTo(kMSTestDistributionGroupId));
  assertThat(reportingParametersForUpdatedRelease[kMSURLQueryInstallIdKey], equalTo(nil));
  assertThat(reportingParametersForUpdatedRelease[kMSURLQueryDownloadedReleaseIdKey], equalTo(@1));
}

- (void)testReportReleaseInstallForPublicGroupWhenReleaseHashesMatch {

  // If
  NSString *installId = [[MSAppCenter installId] UUIDString];
  [self.settingsMock setObject:@1 forKey:kMSDownloadedReleaseIdKey];
  [self.settingsMock setObject:kMSTestReleaseHash forKey:kMSDownloadedReleaseHashKey];

  // When
  NSMutableDictionary *reportingParametersForUpdatedRelease = [self.sut getReportingParametersForUpdatedRelease:YES
                                                                                    currentInstalledReleaseHash:kMSTestReleaseHash
                                                                                            distributionGroupId:kMSTestDistributionGroupId];

  // Then
  assertThat(reportingParametersForUpdatedRelease[kMSURLQueryDistributionGroupIdKey], equalTo(kMSTestDistributionGroupId));
  assertThat(reportingParametersForUpdatedRelease[kMSURLQueryInstallIdKey], equalTo(installId));
  assertThat(reportingParametersForUpdatedRelease[kMSURLQueryDownloadedReleaseIdKey], equalTo(@1));
}

- (void)testCheckLatestFirstNewDistributionGroupId {

  // If
  NSString *distributionGroupId = @"GROUP-ID";
  id distributeMock = OCMPartialMock(self.sut);
  [self.sut setUpdateTrack:MSUpdateTrackPrivate];

  // Mock the HTTP client.
  id httpClientMock = OCMPartialMock([MSHttpClient new]);
  id httpClientClassMock = OCMClassMock([MSHttpClient class]);
  OCMStub([httpClientClassMock alloc]).andReturn(httpClientMock);
  OCMStub([httpClientMock initWithMaxHttpConnectionsPerHost:4]).andReturn(httpClientMock);
  self.sut.appSecret = kMSTestAppSecret;
  id reachabilityMock = OCMClassMock([MS_Reachability class]);
  OCMStub([reachabilityMock reachabilityForInternetConnection]).andReturn(reachabilityMock);
  OCMStub([reachabilityMock currentReachabilityStatus]).andReturn(ReachableViaWiFi);

  // Mock the http client calls.
  XCTestExpectation *expectation = [self expectationWithDescription:@"Request completed."];
  OCMStub([httpClientMock requestCompletedWithHttpCall:OCMOCK_ANY data:OCMOCK_ANY response:OCMOCK_ANY error:OCMOCK_ANY])
      .andForwardToRealObject()
      .andDo(^(__unused NSInvocation *invocation) {
        [expectation fulfill];
      });

  // Create JSON response data.
  NSDictionary *dict = @{@"distribution_group_id" : distributionGroupId};
  NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
  [MSHttpTestUtil stubResponseWithData:data statusCode:200 headers:nil name:@"httpStub_200"];

  // When
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                        appSecret:kMSTestAppSecret
          transmissionTargetToken:nil
                  fromApplication:YES];
  [self.sut checkLatestRelease:kMSTestUpdateToken distributionGroupId:kMSTestDistributionGroupId releaseHash:kMSTestReleaseHash];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 OCMVerify([self.distributeInfoTrackerMock updateDistributionGroupId:distributionGroupId]);
                                 NSString *actualDistributionGroupId = [MS_APP_CENTER_USER_DEFAULTS objectForKey:kMSDistributionGroupIdKey];
                                 XCTAssertEqualObjects(actualDistributionGroupId, distributionGroupId);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  // Clear
  [distributeMock stopMocking];
  [httpClientClassMock stopMocking];
}

- (void)testCheckLatestReleaseReportReleaseInstall {

  // If
  id keychainMock = OCMClassMock([MSKeychainUtil class]);
  id distributeMock = OCMPartialMock(self.sut);
  [self.sut setUpdateTrack:MSUpdateTrackPrivate];

  // Mock the HTTP client.
  id httpClientMock = OCMPartialMock([MSHttpClient new]);
  id httpClientClassMock = OCMClassMock([MSHttpClient class]);
  OCMStub([httpClientClassMock alloc]).andReturn(httpClientMock);
  OCMStub([httpClientMock initWithMaxHttpConnectionsPerHost:4]).andReturn(httpClientMock);
  OCMReject([distributeMock handleUpdate:OCMOCK_ANY]);
  self.sut.appSecret = kMSTestAppSecret;
  id reachabilityMock = OCMClassMock([MS_Reachability class]);
  OCMStub([reachabilityMock reachabilityForInternetConnection]).andReturn(reachabilityMock);
  OCMStub([reachabilityMock currentReachabilityStatus]).andReturn(ReachableViaWiFi);
  XCTestExpectation *expectation = [self expectationWithDescription:@"Request completed."];
  OCMStub([httpClientMock requestCompletedWithHttpCall:OCMOCK_ANY data:OCMOCK_ANY response:OCMOCK_ANY error:OCMOCK_ANY])
      .andForwardToRealObject()
      .andDo(^(__unused NSInvocation *invocation) {
        [expectation fulfill];
      });
  OCMClassMock([MSHttpCall class]);
  id httpCallMock = OCMPartialMock([MSHttpCall alloc]);
  OCMStub([httpCallMock alloc]).andReturn(httpCallMock);
  OCMReject([httpCallMock startRetryTimerWithStatusCode:404 retryAfter:OCMOCK_ANY event:OCMOCK_ANY]);
  [MSHttpTestUtil stubHttp404Response];
  [self.settingsMock setObject:@1 forKey:kMSDownloadedReleaseIdKey];
  [self.settingsMock setObject:kMSTestReleaseHash forKey:kMSDownloadedReleaseHashKey];

  // When
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                        appSecret:kMSTestAppSecret
          transmissionTargetToken:nil
                  fromApplication:YES];
  [self.sut checkLatestRelease:kMSTestUpdateToken distributionGroupId:kMSTestDistributionGroupId releaseHash:kMSTestReleaseHash];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 OCMVerify([distributeMock getReportingParametersForUpdatedRelease:NO
                                                                       currentInstalledReleaseHash:kMSTestReleaseHash
                                                                               distributionGroupId:kMSTestDistributionGroupId]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  // Clear
  [distributeMock stopMocking];
  [keychainMock stopMocking];
  [httpClientClassMock stopMocking];
}

- (void)testShouldChangeDistributionGroupIdIfStoredIdDoesntMatchDownloadedId {

  // If
  id distributeMock = OCMPartialMock(self.sut);
  id utilityMock = [self mockMSPackageHash];
  OCMStub([distributeMock checkLatestRelease:OCMOCK_ANY distributionGroupId:OCMOCK_ANY releaseHash:OCMOCK_ANY]).andDo(nil);
  OCMStub([distributeMock requestInstallInformationWith:OCMOCK_ANY]).andDo(nil);
  [self.settingsMock setObject:kMSTestReleaseHash forKey:kMSDownloadedReleaseHashKey];
  [self.settingsMock setObject:kMSTestDistributionGroupId forKey:kMSDistributionGroupIdKey];
  [self.settingsMock setObject:kMSTestDownloadedDistributionGroupId forKey:kMSDownloadedDistributionGroupIdKey];

  // When
  [self.sut startUpdateOnStart:NO];

  // Then
  OCMVerify([distributeMock changeDistributionGroupIdAfterAppUpdateIfNeeded:kMSTestReleaseHash]);
  assertThat([self.settingsMock objectForKey:kMSDistributionGroupIdKey], equalTo(kMSTestDownloadedDistributionGroupId));
  XCTAssertNil([self.settingsMock objectForKey:kMSDownloadedDistributionGroupIdKey]);

  // Stop mocking
  [distributeMock stopMocking];
  [utilityMock stopMocking];
}

- (void)testShouldNotAttemptUpdateIfKeychainIsInaccessible {

  // If
  id distributeMock = OCMPartialMock(self.sut);
  id utilityMock = [self mockMSPackageHash];
  [MSMockKeychainUtil mockStatusCode:errSecInteractionNotAllowed forKey:kMSUpdateTokenKey];
  [self.settingsMock setObject:kMSTestReleaseHash forKey:kMSDownloadedReleaseHashKey];
  [self.settingsMock setObject:kMSTestDistributionGroupId forKey:kMSDistributionGroupIdKey];
  [self.settingsMock setObject:kMSTestDownloadedDistributionGroupId forKey:kMSDownloadedDistributionGroupIdKey];

  // Then
  OCMReject([distributeMock requestInstallInformationWith:OCMOCK_ANY]);
  OCMReject([distributeMock checkLatestRelease:OCMOCK_ANY distributionGroupId:OCMOCK_ANY releaseHash:OCMOCK_ANY]);

  // When
  [self.sut startUpdateOnStart:NO];

  // Then
  XCTAssertFalse(self.sut.updateFlowInProgress);

  // Stop mocking
  [distributeMock stopMocking];
  [utilityMock stopMocking];
}

- (void)testShouldStillAttemptUpdateIfKeychainItemNotFound {

  // If
  id distributeMock = OCMPartialMock(self.sut);
  id utilityMock = [self mockMSPackageHash];
  __block BOOL checkLatestReleaseCalled = NO;
  OCMStub([distributeMock checkLatestRelease:OCMOCK_ANY distributionGroupId:OCMOCK_ANY releaseHash:OCMOCK_ANY])
      .andDo(^(__attribute((unused)) NSInvocation *invocation) {
        checkLatestReleaseCalled = YES;
      });
  [MSMockKeychainUtil mockStatusCode:errSecItemNotFound forKey:kMSUpdateTokenKey];
  [self.settingsMock setObject:kMSTestReleaseHash forKey:kMSDownloadedReleaseHashKey];
  [self.settingsMock setObject:kMSTestDistributionGroupId forKey:kMSDistributionGroupIdKey];
  [self.settingsMock setObject:kMSTestDownloadedDistributionGroupId forKey:kMSDownloadedDistributionGroupIdKey];

  // When
  [self.sut startUpdateOnStart:NO];

  // Then
  XCTAssertTrue(checkLatestReleaseCalled);

  // Stop mocking
  [distributeMock stopMocking];
  [utilityMock stopMocking];
}

- (void)testShouldChangeDistributionGroupIdIfStoredIdIsNil {

  // If
  id distributeMock = OCMPartialMock(self.sut);
  id utilityMock = [self mockMSPackageHash];
  OCMStub([distributeMock checkLatestRelease:OCMOCK_ANY distributionGroupId:OCMOCK_ANY releaseHash:OCMOCK_ANY]).andDo(nil);
  OCMStub([distributeMock requestInstallInformationWith:OCMOCK_ANY]).andDo(nil);
  [self.settingsMock setObject:kMSTestReleaseHash forKey:kMSDownloadedReleaseHashKey];
  [self.settingsMock removeObjectForKey:kMSDistributionGroupIdKey];
  [self.settingsMock setObject:kMSTestDownloadedDistributionGroupId forKey:kMSDownloadedDistributionGroupIdKey];

  // When
  [self.sut startUpdateOnStart:NO];

  // Then
  OCMVerify([distributeMock changeDistributionGroupIdAfterAppUpdateIfNeeded:kMSTestReleaseHash]);
  assertThat([self.settingsMock objectForKey:kMSDistributionGroupIdKey], equalTo(kMSTestDownloadedDistributionGroupId));
  XCTAssertNil([self.settingsMock objectForKey:kMSDownloadedDistributionGroupIdKey]);

  // Stop mocking
  [distributeMock stopMocking];
  [utilityMock stopMocking];
}

- (void)testShouldNotChangeDistributionGroupIdIfStoredIdMatchDownloadedId {

  // If
  id distributeMock = OCMPartialMock(self.sut);
  id utilityMock = [self mockMSPackageHash];
  OCMStub([distributeMock checkLatestRelease:OCMOCK_ANY distributionGroupId:OCMOCK_ANY releaseHash:OCMOCK_ANY]).andDo(nil);
  OCMStub([distributeMock requestInstallInformationWith:OCMOCK_ANY]).andDo(nil);
  [self.settingsMock setObject:kMSTestReleaseHash forKey:kMSDownloadedReleaseHashKey];
  [self.settingsMock setObject:kMSTestDistributionGroupId forKey:kMSDistributionGroupIdKey];
  [self.settingsMock setObject:kMSTestDistributionGroupId forKey:kMSDownloadedDistributionGroupIdKey];

  // When
  [self.sut startUpdateOnStart:NO];

  // Then
  OCMVerify([distributeMock changeDistributionGroupIdAfterAppUpdateIfNeeded:kMSTestReleaseHash]);
  assertThat([self.settingsMock objectForKey:kMSDistributionGroupIdKey], equalTo(kMSTestDistributionGroupId));
  assertThat([self.settingsMock objectForKey:kMSDownloadedDistributionGroupIdKey], equalTo(nil));

  // Stop mocking
  [distributeMock stopMocking];
  [utilityMock stopMocking];
}

- (void)testShouldNotChangeDistributionGroupIdIfAppWasntUpdated {

  // If
  id distributeMock = OCMPartialMock(self.sut);
  id utilityMock = [self mockMSPackageHash];
  OCMStub([distributeMock checkLatestRelease:OCMOCK_ANY distributionGroupId:OCMOCK_ANY releaseHash:OCMOCK_ANY]).andDo(nil);
  OCMStub([distributeMock requestInstallInformationWith:OCMOCK_ANY]).andDo(nil);
  [self.settingsMock removeObjectForKey:kMSDownloadedReleaseHashKey];
  [self.settingsMock setObject:kMSTestDistributionGroupId forKey:kMSDistributionGroupIdKey];
  [self.settingsMock removeObjectForKey:kMSDownloadedDistributionGroupIdKey];

  // When
  [self.sut startUpdateOnStart:NO];

  // Then
  OCMVerify([distributeMock changeDistributionGroupIdAfterAppUpdateIfNeeded:kMSTestReleaseHash]);
  assertThat([self.settingsMock objectForKey:kMSDistributionGroupIdKey], equalTo(kMSTestDistributionGroupId));
  XCTAssertNil([self.settingsMock objectForKey:kMSDownloadedDistributionGroupIdKey]);

  // Stop mocking
  [distributeMock stopMocking];
  [utilityMock stopMocking];
}
- (void)testShouldNotChangeDistributionGroupIdIfStoredIdIsNil {

  // If
  id distributeMock = OCMPartialMock(self.sut);
  id utilityMock = [self mockMSPackageHash];
  OCMStub([distributeMock checkLatestRelease:OCMOCK_ANY distributionGroupId:OCMOCK_ANY releaseHash:OCMOCK_ANY]).andDo(nil);
  OCMStub([distributeMock requestInstallInformationWith:OCMOCK_ANY]).andDo(nil);
  [self.settingsMock setObject:kMSTestReleaseHash forKey:kMSDownloadedReleaseHashKey];
  [self.settingsMock setObject:kMSTestDistributionGroupId forKey:kMSDistributionGroupIdKey];
  [self.settingsMock removeObjectForKey:kMSDownloadedDistributionGroupIdKey];

  // When
  [self.sut startUpdateOnStart:NO];

  // Then
  OCMVerify([distributeMock changeDistributionGroupIdAfterAppUpdateIfNeeded:kMSTestReleaseHash]);
  assertThat([self.settingsMock objectForKey:kMSDistributionGroupIdKey], equalTo(kMSTestDistributionGroupId));
  XCTAssertNil([self.settingsMock objectForKey:kMSDownloadedDistributionGroupIdKey]);

  // Stop mocking
  [distributeMock stopMocking];
  [utilityMock stopMocking];
}

- (void)testStoreDownloadedReleaseDetails {

  // If
  MSReleaseDetails *details = [MSReleaseDetails new];
  details.id = @1;
  details.packageHashes = @[ kMSTestReleaseHash ];
  details.distributionGroupId = kMSTestDistributionGroupId;

  // When
  [self.sut storeDownloadedReleaseDetails:details];

  // Then
  assertThat([self.settingsMock objectForKey:kMSDownloadedReleaseIdKey], equalTo(@1));
  assertThat([self.settingsMock objectForKey:kMSDownloadedReleaseHashKey], equalTo(kMSTestReleaseHash));
  assertThat([self.settingsMock objectForKey:kMSDownloadedDistributionGroupIdKey], equalTo(kMSTestDistributionGroupId));
}

- (void)testStoreDownloadedReleaseDetailsWithNilValues {

  // If
  [self.settingsMock removeObjectForKey:kMSDownloadedReleaseIdKey];
  [self.settingsMock removeObjectForKey:kMSDownloadedReleaseHashKey];
  [self.settingsMock removeObjectForKey:kMSDownloadedDistributionGroupIdKey];

  // When
  [self.sut storeDownloadedReleaseDetails:nil];

  // Then
  assertThat([self.settingsMock objectForKey:kMSDownloadedReleaseIdKey], equalTo(nil));
  assertThat([self.settingsMock objectForKey:kMSDownloadedReleaseHashKey], equalTo(nil));
  assertThat([self.settingsMock objectForKey:kMSDownloadedDistributionGroupIdKey], equalTo(nil));

  // If
  MSReleaseDetails *details = [MSReleaseDetails new];

  // When
  [self.sut storeDownloadedReleaseDetails:details];

  // Then
  assertThat([self.settingsMock objectForKey:kMSDownloadedReleaseIdKey], equalTo(nil));
  assertThat([self.settingsMock objectForKey:kMSDownloadedReleaseHashKey], equalTo(nil));
  assertThat([self.settingsMock objectForKey:kMSDownloadedDistributionGroupIdKey], equalTo(nil));
}

- (void)testRemoveDownloadedReleaseDetailsIfUpdated {

  // If
  id utilityMock = [self mockMSPackageHash];
  [self.settingsMock setObject:@1 forKey:kMSDownloadedReleaseIdKey];
  [self.settingsMock setObject:kMSTestReleaseHash forKey:kMSDownloadedReleaseHashKey];

  // When
  [self.sut removeDownloadedReleaseDetailsIfUpdated:kMSTestReleaseHash];

  // Then
  XCTAssertNil([self.settingsMock objectForKey:kMSDownloadedReleaseIdKey]);
  XCTAssertNil([self.settingsMock objectForKey:kMSDownloadedReleaseHashKey]);

  // Clear
  [utilityMock stopMocking];
}

- (void)testStartUpdateWhenEnabledButDidNotStart {
  NSString *isEnabledKey = @"MSAppCenterIsEnabled";
  [MS_APP_CENTER_USER_DEFAULTS setObject:@YES forKey:isEnabledKey];

  // If
  id notificationCenterMock = OCMPartialMock([NSNotificationCenter new]);
  OCMStub([notificationCenterMock defaultCenter]).andReturn(notificationCenterMock);
  MSDistribute *distribute = [MSDistribute new];
  id distributeMock = OCMPartialMock(distribute);
  OCMReject([distributeMock startUpdateOnStart:OCMOCK_ANY]);

  // When
  [distribute setEnabled:YES];
  [notificationCenterMock postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];

  // Then
  OCMVerify([distributeMock canBeUsed]);

  // When
  [distribute setEnabled:YES];

  // When
  [notificationCenterMock postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];

  // Then
  OCMVerify([distributeMock canBeUsed]);
  OCMVerifyAll(distributeMock);

  // Clear
  [notificationCenterMock stopMocking];
  [distributeMock stopMocking];
}

- (void)testHideAppSecret {

  // If
  id mockLogger = OCMClassMock([MSLogger class]);
  id distributeMock = OCMPartialMock(self.sut);
  id appCenterMock = OCMClassMock([MSAppCenter class]);
  OCMReject([distributeMock checkLatestRelease:OCMOCK_ANY distributionGroupId:OCMOCK_ANY releaseHash:OCMOCK_ANY]);
  OCMStub([distributeMock sharedInstance]).andReturn(distributeMock);
  OCMStub([appCenterMock isConfigured]).andReturn(YES);
  OCMReject([[mockLogger ignoringNonObjectArgs] logMessage:[OCMArg checkWithBlock:^BOOL(MSLogMessageProvider messageProvider) {
                                                  return [messageProvider() containsString:kMSTestAppSecret];
                                                }]
                                                     level:0
                                                       tag:OCMOCK_ANY
                                                      file:[OCMArg anyPointer]
                                                  function:[OCMArg anyPointer]
                                                      line:0]);

  // When
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                        appSecret:kMSTestAppSecret
          transmissionTargetToken:nil
                  fromApplication:YES];
  NSString *urlPath = [NSString stringWithFormat:@"%@/%@", kMSDefaultURLFormat, kMSTestAppSecret];
  NSURLComponents *components = [NSURLComponents componentsWithString:urlPath];
  [self.sut openURLInAuthenticationSessionWith:components.URL];

  // Then
  OCMVerifyAll(mockLogger);

  // Clear
  [mockLogger stopMocking];
  [appCenterMock stopMocking];
  [distributeMock stopMocking];
}

- (void)testOpenURLInAuthenticationSessionFails API_AVAILABLE(ios(11)) {

  // If
  NSURL *fakeURL = [NSURL URLWithString:kMSDefaultURLFormat];
  id appCenterMock = OCMClassMock([MSAppCenter class]);
  OCMStub([appCenterMock sharedInstance]).andReturn(appCenterMock);
  OCMStub([appCenterMock isSdkConfigured]).andReturn(YES);
  OCMStub([appCenterMock isConfigured]).andReturn(YES);
  SFAuthenticationSession *authenticationSessionMock = OCMPartialMock([SFAuthenticationSession alloc]);
  OCMStub([authenticationSessionMock start]).andThrow([NSException exceptionWithName:@"" reason:@"" userInfo:nil]);
  self.sut.authenticationSession = authenticationSessionMock;
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                        appSecret:kMSTestAppSecret
          transmissionTargetToken:nil
                  fromApplication:YES];

  // When
  [self.sut openURLInAuthenticationSessionWith:fakeURL];

  // Then
  /* No crash. */

  // Clear
  [appCenterMock stopMocking];
}

- (void)testDependencyCallUsesInjectedHttpClient {

  // If
  id httpClient = OCMClassMock([MSHttpClient class]);
  [MSDependencyConfiguration setHttpClient:httpClient];
  MSDistribute *distribute = [MSDistribute new];

  // When
  [distribute startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                          appSecret:kMSTestAppSecret
            transmissionTargetToken:nil
                    fromApplication:YES];

  // Then
  XCTAssertEqual(distribute.ingestion.httpClient, httpClient);

  // Cleanup
  MSDependencyConfiguration.httpClient = nil;
  [httpClient stopMocking];
}

- (void)testReadAndSetUpdateTrack {

  // If - Default state is public
  XCTAssertEqual(MSDistribute.updateTrack, MSUpdateTrackPublic);

  // When
  MSDistribute.updateTrack = MSUpdateTrackPrivate;

  // Then
  XCTAssertEqual(MSDistribute.updateTrack, MSUpdateTrackPrivate);

  // When
  MSDistribute.updateTrack = MSUpdateTrackPublic;

  // Then
  XCTAssertEqual(MSDistribute.updateTrack, MSUpdateTrackPublic);
}

- (void)testSetInvalidUpdateTrack {

  // If
  MSDistribute.updateTrack = MSUpdateTrackPrivate;

  // When
  MSDistribute.updateTrack = 100;

  // Then
  XCTAssertEqual(MSDistribute.updateTrack, MSUpdateTrackPrivate);
}

- (void)testSetUpdateTrackWhenDisabled {

  // If
  [MSDistribute setEnabled:NO];

  // When
  MSDistribute.updateTrack = MSUpdateTrackPrivate;

  // Then
  XCTAssertEqual(MSDistribute.updateTrack, MSUpdateTrackPrivate);

  // When
  MSDistribute.updateTrack = MSUpdateTrackPublic;

  // Then
  XCTAssertEqual(MSDistribute.updateTrack, MSUpdateTrackPublic);
}

- (void)testDefaultUpdateTrackIsPublic {

  // Then
  XCTAssertEqual(MSDistribute.updateTrack, MSUpdateTrackPublic);
}

- (void)testSetUpdateTrackAfterStartDoesNothing {

  // If
  id distributeMock = OCMPartialMock(self.sut);
  [distributeMock setValue:@(MSUpdateTrackPublic) forKey:@"updateTrack"];
  [distributeMock setValue:@(YES) forKey:@"started"];
  OCMStub([distributeMock sharedInstance]).andReturn(distributeMock);

  // When
  [self.sut setUpdateTrack:MSUpdateTrackPrivate];

  // Then
  XCTAssertEqual(self.sut.updateTrack, MSUpdateTrackPublic);

  // Clear
  [distributeMock stopMocking];
}

- (void)testPrivateTrackNotGettingUpdateWithoutUpdateToken {

  // If
  id ingestionMock = OCMClassMock([MSDistributeIngestion class]);
  id distributeMock = OCMPartialMock(self.sut);
  [distributeMock setValue:ingestionMock forKey:@"ingestion"];
  [distributeMock setValue:@(MSUpdateTrackPrivate) forKey:@"updateTrack"];
  OCMReject([ingestionMock checkForPrivateUpdateWithUpdateToken:OCMOCK_ANY queryStrings:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
  OCMReject([ingestionMock checkForPublicUpdateWithQueryStrings:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
  OCMStub([distributeMock canBeUsed]).andReturn(YES);

  // When
  [self.sut checkLatestRelease:nil distributionGroupId:@"whateverGroupId" releaseHash:@"whateverReleaseHash"];

  // Then
  OCMVerifyAll(ingestionMock);

  // Clear
  [ingestionMock stopMocking];
  [distributeMock stopMocking];
}

- (void)testCompleteUpdateFlowWhenReleaseDetailsIsNotValid {

  // If
  id distributeMock = OCMPartialMock(self.sut);

  // Mock the HTTP client.
  id httpClientMock = OCMPartialMock([MSHttpClient new]);
  id httpClientClassMock = OCMClassMock([MSHttpClient class]);
  OCMStub([httpClientClassMock alloc]).andReturn(httpClientMock);
  OCMStub([httpClientMock initWithMaxHttpConnectionsPerHost:4]).andReturn(httpClientMock);
  OCMReject([distributeMock handleUpdate:OCMOCK_ANY]);
  self.sut.appSecret = kMSTestAppSecret;
  [distributeMock setValue:@(YES) forKey:@"updateFlowInProgress"];
  id reachabilityMock = OCMClassMock([MS_Reachability class]);
  OCMStub([reachabilityMock reachabilityForInternetConnection]).andReturn(reachabilityMock);
  OCMStub([reachabilityMock currentReachabilityStatus]).andReturn(ReachableViaWiFi);
  XCTestExpectation *expectation = [self expectationWithDescription:@"Request completed."];
  OCMStub([httpClientMock requestCompletedWithHttpCall:OCMOCK_ANY data:OCMOCK_ANY response:OCMOCK_ANY error:OCMOCK_ANY])
      .andForwardToRealObject()
      .andDo(^(__unused NSInvocation *invocation) {
        [expectation fulfill];
      });

  // Receive 200 OK success with invalid response body.
  [MSHttpTestUtil stubResponseWithData:nil statusCode:200 headers:nil name:@"httpStub_200_NoData"];

  // When
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                        appSecret:kMSTestAppSecret
          transmissionTargetToken:nil
                  fromApplication:YES];
  [self.sut checkLatestRelease:kMSTestUpdateToken distributionGroupId:kMSTestDistributionGroupId releaseHash:kMSTestReleaseHash];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertFalse(self.sut.updateFlowInProgress);
                               }];

  // Clear
  [httpClientClassMock stopMocking];
}

- (void)testCompleteUpdateFlowWhenUpdateNotAllowed {

  // If
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock canBeUsed]).andReturn(YES);
  OCMStub([distributeMock checkForUpdatesAllowed]).andReturn(NO);
  [distributeMock setValue:@(YES) forKey:@"updateFlowInProgress"];

  // When
  [self.sut checkLatestRelease:@"whateverToken" distributionGroupId:@"whateverGroupId" releaseHash:@"whateverReleaseHash"];

  // Then
  XCTAssertFalse(self.sut.updateFlowInProgress);

  // Clear
  [distributeMock stopMocking];
}

- (void)testCompleteUpdateFlowWhenUpdateStopped {

  // If
  id distributeMock = OCMPartialMock(self.sut);

  // Mock the HTTP client. Use dependency configuration to simplify MSHttpClient mock.
  id httpClientMock = OCMPartialMock([MSHttpClient new]);
  [MSDependencyConfiguration setHttpClient:httpClientMock];
  self.sut.appSecret = kMSTestAppSecret;
  [distributeMock setValue:@(YES) forKey:@"updateFlowInProgress"];
  id reachabilityMock = OCMClassMock([MS_Reachability class]);
  OCMStub([reachabilityMock reachabilityForInternetConnection]).andReturn(reachabilityMock);
  OCMStub([reachabilityMock currentReachabilityStatus]).andReturn(ReachableViaWiFi);
  XCTestExpectation *expectation = [self expectationWithDescription:@"Request completed."];
  OCMStub([httpClientMock requestCompletedWithHttpCall:OCMOCK_ANY data:OCMOCK_ANY response:OCMOCK_ANY error:OCMOCK_ANY])
      .andForwardToRealObject()
      .andDo(^(__unused NSInvocation *invocation) {
        [expectation fulfill];
      });

  // handleUpdate returns NO to simulate
  // 1. A valid MSReleaseDetails but isValid returns NO.
  // 2. A valid MSReleaseDetails without status field.
  // 3. Update was postponed within a day.
  // 4. The release doesn't meet minimum OS version requirement.
  // 5. The release is already installed.
  OCMStub([distributeMock handleUpdate:OCMOCK_ANY]).andReturn(NO);

  // Receive 200 OK success with valid response body.
  MSReleaseDetails *details = [self generateReleaseDetailsWithVersion:@"1.0" andShortVersion:@"1"];
  NSData *data = [NSJSONSerialization dataWithJSONObject:[details serializeToDictionary] options:0 error:nil];
  [MSHttpTestUtil stubResponseWithData:data statusCode:200 headers:nil name:@"httpStub_200"];

  // When
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                        appSecret:kMSTestAppSecret
          transmissionTargetToken:nil
                  fromApplication:YES];
  [self.sut checkLatestRelease:kMSTestUpdateToken distributionGroupId:kMSTestDistributionGroupId releaseHash:kMSTestReleaseHash];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertFalse(self.sut.updateFlowInProgress);
                               }];

  // Clean up
  MSDependencyConfiguration.httpClient = nil;
}

- (void)testCompleteUpdateFlowWhenReleaseNoteIsClicked {

  // If
  NSString *appName = @"Test App";
  OCMStub([self.bundleMock objectForInfoDictionaryKey:@"CFBundleDisplayName"]).andReturn(appName);
  MSReleaseDetails *details = [MSReleaseDetails new];
  details.shortVersion = @"2.5";
  details.version = @"11";
  details.releaseNotes = @"Release notes";
  details.releaseNotesUrl = [NSURL URLWithString:@"https://contoso.com/release_notes"];
  details.mandatoryUpdate = false;
  self.sut.updateFlowInProgress = YES;

  typedef void (^MSHandler)(UIAlertAction *action);
  OCMStub([self.alertControllerMock addDefaultActionWithTitle:MSDistributeLocalizedString(@"MSDistributeViewReleaseNotes")
                                                      handler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSHandler handler;
        [invocation getArgument:&handler atIndex:3];

        // Simulating a button click for release note.
        handler(nil);
      });

  // When
  XCTestExpectation *expectation = [self expectationWithDescription:@"Confirmation alert has been displayed"];
  [self.sut showConfirmationAlert:details];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertFalse(self.sut.updateFlowInProgress);
                               }];
}

#pragma mark - Helper

- (MSReleaseDetails *)generateReleaseDetailsWithVersion:(NSString *)version andShortVersion:(NSString *)shortVersion {
  MSReleaseDetails *releaseDetails = [MSReleaseDetails new];
  releaseDetails.version = version;
  releaseDetails.shortVersion = shortVersion;
  return releaseDetails;
}

- (id)mockMSPackageHash {
  id utilityMock = OCMClassMock([MSUtility class]);
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wcast-qual"
  OCMStub(ClassMethod([utilityMock sha256:OCMOCK_ANY])).andReturn(kMSTestReleaseHash);
#pragma GCC diagnostic pop

  NSDictionary<NSString *, id> *plist = @{@"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1"};
  OCMStub([self.bundleMock infoDictionary]).andReturn(plist);
  return utilityMock;
}

@end
