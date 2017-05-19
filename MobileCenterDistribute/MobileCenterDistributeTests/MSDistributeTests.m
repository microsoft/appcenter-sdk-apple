#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "MS_Reachability.h"
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
#import "MSUtility.h"
#import "MSUtility+Application.h"
#import "MSUtility+Date.h"
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

@interface UIApplication (ForTests)

// Available since iOS 10.
- (void)openURL:(NSURL*)url options:(NSDictionary<NSString *, id> *)options completionHandler:(void (^ __nullable)(BOOL success))completion;

@end

static NSURL *sfURL;

@interface MSDistributeTests : XCTestCase

@property(nonatomic) MSDistribute *sut;
@property(nonatomic) id parserMock;
@property(nonatomic) id settingsMock;
@property(nonatomic) id bundleMock;

@end

@implementation MSDistributeTests

- (void)setUp {
  [super setUp];
  [MSKeychainUtil clear];
  self.sut = [MSDistribute new];
  self.settingsMock = [MSMockUserDefaults new];

  // Mock NSBundle
  self.bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([self.bundleMock mainBundle]).andReturn(self.bundleMock);

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
  [self.bundleMock stopMocking];
  [MSDistributeTestUtil unMockUpdatesAllowedConditions];
}

- (void)testInstallURL {

  // If
  XCTestExpectation *openURLCalledExpectation = [self expectationWithDescription:@"openURL Called."];
  NSArray *bundleArray = @[
    @{ @"CFBundleURLSchemes" : @[ [NSString stringWithFormat:@"mobilecenter-%@", kMSTestAppSecret] ] }
  ];
  OCMStub([self.bundleMock objectForInfoDictionaryKey:@"CFBundleURLTypes"]).andReturn(bundleArray);
  OCMStub([self.bundleMock objectForInfoDictionaryKey:@"MSAppName"]).andReturn(@"Something");
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

  // When
  NSURL *url = [self.sut buildTokenRequestURLWithAppSecret:badAppSecret releaseHash:kMSTestReleaseHash];

  // Then
  assertThat(url, nilValue());
}

- (void)testOpenURLInSafariApp {

  // If
  XCTestExpectation *openURLCalledExpectation = [self expectationWithDescription:@"openURL Called."];
  NSURL *url = [NSURL URLWithString:@"https://contoso.com"];
  id appMock = OCMClassMock([UIApplication class]);
  OCMStub([appMock sharedApplication]).andReturn(appMock);
  OCMStub([appMock canOpenURL:url]).andReturn(YES);
  SEL selector = NSSelectorFromString(@"openURL:options:completionHandler:");
  BOOL newOpenURL = [appMock respondsToSelector:selector];
  if (newOpenURL) {
    OCMStub([appMock openURL:url options:[OCMArg any] completionHandler:[OCMArg any]]).andDo(nil);
  } else {
    OCMStub([appMock openURL:url]).andDo(nil);
  }

  // When
  [self.sut openURLInSafariApp:url];
  dispatch_async(dispatch_get_main_queue(), ^{
    [openURLCalledExpectation fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (newOpenURL) {
                                   OCMVerify([appMock openURL:url options:[OCMArg any] completionHandler:[OCMArg any]]);
                                 } else {
                                   OCMVerify([appMock openURL:url]);
                                 }
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
  OCMStub([self.bundleMock objectForInfoDictionaryKey:@"CFBundleURLTypes"]).andReturn(bundleArray);

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
  OCMStub([self.bundleMock objectForInfoDictionaryKey:@"CFBundleURLTypes"]).andReturn(bundleArray);

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

- (void)testHandleInvalidUpdate {

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
  OCMStub([distributeMock isNewerVersion:[OCMArg any]]).andReturn(NO);

  // When
  [distributeMock handleUpdate:details];

  // Then
  OCMReject([distributeMock showConfirmationAlert:[OCMArg any]]);
}

- (void)testHandleValidUpdate {

  // If
  MSReleaseDetails *details = [MSReleaseDetails new];
  id distributeMock = OCMPartialMock(self.sut);
  __block int showConfirmationAlertCounter = 0;
  OCMStub([distributeMock showConfirmationAlert:[OCMArg any]]).andDo(^(__attribute((unused)) NSInvocation *invocation) {
    showConfirmationAlertCounter++;
  });
  OCMStub([distributeMock isNewerVersion:[OCMArg any]]).andReturn(YES);
  details.id = @1;
  details.downloadUrl = [NSURL URLWithString:@"https://contoso.com/valid/url"];
  details.status = @"available";
  details.minOs = @"1.0";

  // When
  [distributeMock handleUpdate:details];

  // Then
  OCMVerify([distributeMock showConfirmationAlert:details]);

  /*
   * The reason of this additional checking is that OCMock doesn't work properly sometimes for OCMVerify and OCMReject.
   * The test won't be failed even though the above line is changed to OCMReject, we are preventing the issue by adding
   * more explict checks.
   */
  XCTAssertEqual(showConfirmationAlertCounter, 1);
}

/**
 * This test is for various cases after update is postponed. This test doesn't complete handleUpdate method and just
 * check whether it passes the check and then move to the next step or not.
 */
- (void)testHandleUpdateAfterPostpone {

  // If
  id distributeMock = OCMPartialMock(self.sut);
  __block int isNewerVersionCounter = 0;
  OCMStub([distributeMock isNewerVersion:[OCMArg any]]).andDo(^(__attribute((unused)) NSInvocation *invocation) {
    isNewerVersionCounter++;
  });
  int actualCounter = 0;
  MSReleaseDetails *details = [self generateReleaseDetailsWithVersion:@"1" andShortVersion:@"1.0"];
  details.id = @1;
  details.downloadUrl = [NSURL URLWithString:@"https://contoso.com/valid/url"];
  details.status = @"available";
  details.mandatoryUpdate = false;
  [MS_USER_DEFAULTS setObject:[NSNumber numberWithLongLong:(long long)[MSUtility nowInMilliseconds] - 100000]
                       forKey:kMSPostponedTimestampKey];

  // When
  BOOL result = [distributeMock handleUpdate:details];

  // Then
  XCTAssertFalse(result);
  OCMReject([distributeMock isNewerVersion:[OCMArg any]]);
  XCTAssertEqual(isNewerVersionCounter, 0);

  // If
  details.mandatoryUpdate = true;

  // When
  [distributeMock handleUpdate:details];

  // Then
  OCMVerify([distributeMock isNewerVersion:[OCMArg any]]);
  XCTAssertEqual(isNewerVersionCounter, ++actualCounter);

  // If
  details.mandatoryUpdate = false;
  [MS_USER_DEFAULTS setObject:@1 forKey:kMSPostponedTimestampKey];

  // When
  [distributeMock handleUpdate:details];

  // Then
  OCMVerify([distributeMock isNewerVersion:[OCMArg any]]);
  XCTAssertEqual(isNewerVersionCounter, ++actualCounter);

  // If
  details.mandatoryUpdate = true;
  [MS_USER_DEFAULTS setObject:@1 forKey:kMSPostponedTimestampKey];

  // When
  [distributeMock handleUpdate:details];

  // Then
  OCMVerify([distributeMock isNewerVersion:[OCMArg any]]);
  XCTAssertEqual(isNewerVersionCounter, ++actualCounter);

  // If
  details.mandatoryUpdate = false;
  [MS_USER_DEFAULTS
      setObject:[NSNumber numberWithLongLong:(long long)[MSUtility nowInMilliseconds] + kMSDayInMillisecond * 2]
         forKey:kMSPostponedTimestampKey];

  // When
  [distributeMock handleUpdate:details];

  // Then
  OCMVerify([distributeMock isNewerVersion:[OCMArg any]]);
  XCTAssertEqual(isNewerVersionCounter, ++actualCounter);

  // If
  details.mandatoryUpdate = true;
  [MS_USER_DEFAULTS
      setObject:[NSNumber numberWithLongLong:(long long)[MSUtility nowInMilliseconds] + kMSDayInMillisecond * 2]
         forKey:kMSPostponedTimestampKey];

  // When
  [distributeMock handleUpdate:details];

  // Then
  OCMVerify([distributeMock isNewerVersion:[OCMArg any]]);
  XCTAssertEqual(isNewerVersionCounter, ++actualCounter);
}

- (void)testShowConfirmationAlert {

  // If
  NSString *appName = @"Test App";
  OCMStub([self.bundleMock objectForInfoDictionaryKey:@"CFBundleDisplayName"]).andReturn(appName);
  id mobileCenterMock = OCMPartialMock(self.sut);
  id alertControllerMock = OCMClassMock([MSAlertController class]);
  MSReleaseDetails *details = [MSReleaseDetails new];
  OCMStub([alertControllerMock alertControllerWithTitle:[OCMArg any] message:[OCMArg any]])
      .andReturn(alertControllerMock);
  details.shortVersion = @"2.5";
  details.version = @"11";
  details.releaseNotes = @"Release notes";
  details.releaseNotesUrl = [NSURL URLWithString:@"https://contoso.com/release_notes"];
  details.mandatoryUpdate = false;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wformat-nonliteral"
  NSString *message =
      [NSString stringWithFormat:MSDistributeLocalizedString(@"MSDistributeAppUpdateAvailableOptionalUpdateMessage"),
                                 appName, details.shortVersion, details.version];
#pragma clang diagnostic pop

  // When
  XCTestExpectation *expection = [self expectationWithDescription:@"Confirmation alert has been displayed"];
  [mobileCenterMock showConfirmationAlert:details];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expection fulfill];
  });

  [self waitForExpectationsWithTimeout:1
                               handler:^(__attribute__((unused)) NSError *error) {

                                 // Then
                                 OCMVerify([alertControllerMock alertControllerWithTitle:[OCMArg any] message:message]);
                                 OCMVerify([alertControllerMock
                                     addDefaultActionWithTitle:MSDistributeLocalizedString(@"MSDistributeAskMeInADay")
                                                       handler:[OCMArg any]]);
                                 OCMVerify([alertControllerMock
                                     addDefaultActionWithTitle:MSDistributeLocalizedString(
                                                                   @"MSDistributeViewReleaseNotes")
                                                       handler:[OCMArg any]]);
                                 OCMVerify([alertControllerMock addPreferredActionWithTitle:[OCMArg any]
                                                                                    handler:[OCMArg any]]);
                               }];
}

- (void)testShowConfirmationAlertWithoutViewReleaseNotesButton {

  // If
  NSString *appName = @"Test App";
  OCMStub([self.bundleMock objectForInfoDictionaryKey:@"CFBundleDisplayName"]).andReturn(appName);
  id mobileCenterMock = OCMPartialMock(self.sut);
  id alertControllerMock = OCMClassMock([MSAlertController class]);
  MSReleaseDetails *details = [MSReleaseDetails new];
  OCMStub([alertControllerMock alertControllerWithTitle:[OCMArg any] message:[OCMArg any]])
      .andReturn(alertControllerMock);
  details.shortVersion = @"2.5";
  details.version = @"11";
  details.mandatoryUpdate = false;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wformat-nonliteral"
  NSString *message =
      [NSString stringWithFormat:MSDistributeLocalizedString(@"MSDistributeAppUpdateAvailableOptionalUpdateMessage"),
                                 appName, details.shortVersion, details.version];
#pragma clang diagnostic pop

  // When
  XCTestExpectation *expection = [self expectationWithDescription:@"Confirmation alert has been displayed"];
  [mobileCenterMock showConfirmationAlert:details];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expection fulfill];
  });

  [self waitForExpectationsWithTimeout:1
                               handler:^(__attribute__((unused)) NSError *error) {

                                 // Then
                                 OCMVerify([alertControllerMock alertControllerWithTitle:[OCMArg any] message:message]);
                                 OCMVerify([alertControllerMock
                                     addDefaultActionWithTitle:MSDistributeLocalizedString(@"MSDistributeAskMeInADay")
                                                       handler:[OCMArg any]]);
                                 OCMReject([alertControllerMock
                                     addDefaultActionWithTitle:MSDistributeLocalizedString(
                                                                   @"MSDistributeViewReleaseNotes")
                                                       handler:[OCMArg any]]);
                                 OCMVerify([alertControllerMock addPreferredActionWithTitle:[OCMArg any]
                                                                                    handler:[OCMArg any]]);
                               }];
}

- (void)testShowConfirmationAlertForMandatoryUpdate {

  // If
  NSString *appName = @"Test App";
  OCMStub([self.bundleMock objectForInfoDictionaryKey:@"CFBundleDisplayName"]).andReturn(appName);
  id mobileCenterMock = OCMPartialMock(self.sut);
  id alertControllerMock = OCMClassMock([MSAlertController class]);
  MSReleaseDetails *details = [MSReleaseDetails new];
  OCMStub([alertControllerMock alertControllerWithTitle:[OCMArg any] message:[OCMArg any]])
      .andReturn(alertControllerMock);
  details.shortVersion = @"2.5";
  details.version = @"11";
  details.releaseNotes = @"Release notes";
  details.releaseNotesUrl = [NSURL URLWithString:@"https://contoso.com/release_notes"];
  details.mandatoryUpdate = true;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wformat-nonliteral"
  NSString *message =
      [NSString stringWithFormat:MSDistributeLocalizedString(@"MSDistributeAppUpdateAvailableMandatoryUpdateMessage"),
                                 appName, details.shortVersion, details.version];
#pragma clang diagnostic pop

  // When
  XCTestExpectation *expection = [self expectationWithDescription:@"Confirmation alert has been displayed"];
  [mobileCenterMock showConfirmationAlert:details];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expection fulfill];
  });

  [self waitForExpectationsWithTimeout:1
                               handler:^(__attribute__((unused)) NSError *error) {

                                 // Then
                                 OCMVerify([alertControllerMock alertControllerWithTitle:[OCMArg any] message:message]);
                                 OCMReject([alertControllerMock
                                     addDefaultActionWithTitle:MSDistributeLocalizedString(@"MSDistributeAskMeInADay")
                                                       handler:[OCMArg any]]);
                                 OCMVerify([alertControllerMock
                                     addDefaultActionWithTitle:MSDistributeLocalizedString(
                                                                   @"MSDistributeViewReleaseNotes")
                                                       handler:[OCMArg any]]);
                                 OCMVerify([alertControllerMock addPreferredActionWithTitle:[OCMArg any]
                                                                                    handler:[OCMArg any]]);
                               }];
}

- (void)testShowConfirmationAlertWithoutViewReleaseNotesButtonForMandatoryUpdate {

  // If
  NSString *appName = @"Test App";
  OCMStub([self.bundleMock objectForInfoDictionaryKey:@"CFBundleDisplayName"]).andReturn(appName);
  id mobileCenterMock = OCMPartialMock(self.sut);
  id alertControllerMock = OCMClassMock([MSAlertController class]);
  MSReleaseDetails *details = [MSReleaseDetails new];
  OCMStub([alertControllerMock alertControllerWithTitle:[OCMArg any] message:[OCMArg any]])
      .andReturn(alertControllerMock);
  details.shortVersion = @"2.5";
  details.version = @"11";
  details.mandatoryUpdate = true;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wformat-nonliteral"
  NSString *message =
      [NSString stringWithFormat:MSDistributeLocalizedString(@"MSDistributeAppUpdateAvailableMandatoryUpdateMessage"),
                                 appName, details.shortVersion, details.version];
#pragma clang diagnostic pop

  // When
  XCTestExpectation *expection = [self expectationWithDescription:@"Confirmation alert has been displayed"];
  [mobileCenterMock showConfirmationAlert:details];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expection fulfill];
  });

  [self waitForExpectationsWithTimeout:1
                               handler:^(__attribute__((unused)) NSError *error) {

                                 // Then
                                 OCMVerify([alertControllerMock alertControllerWithTitle:[OCMArg any] message:message]);
                                 OCMReject([alertControllerMock
                                     addDefaultActionWithTitle:MSDistributeLocalizedString(@"MSDistributeAskMeInADay")
                                                       handler:[OCMArg any]]);
                                 OCMReject([alertControllerMock
                                     addDefaultActionWithTitle:MSDistributeLocalizedString(
                                                                   @"MSDistributeViewReleaseNotes")
                                                       handler:[OCMArg any]]);
                                 OCMVerify([alertControllerMock addPreferredActionWithTitle:[OCMArg any]
                                                                                    handler:[OCMArg any]]);
                               }];
}

- (void)testShowConfirmationAlertForMandatoryUpdateWhileNoNetwork {

  /*
   * If
   */
  XCTestExpectation *expection = [self expectationWithDescription:@"Confirmation alert has been displayed"];

  // Mock alert.
  id alertControllerMock = OCMClassMock([MSAlertController class]);
  OCMStub([alertControllerMock alertControllerWithTitle:[OCMArg any] message:[OCMArg any]])
      .andReturn(alertControllerMock);

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
  NSString *message =
      [NSString stringWithFormat:MSDistributeLocalizedString(@"MSDistributeAppUpdateAvailableMandatoryUpdateMessage"),
                                 appName, details.shortVersion, details.version];
#pragma clang diagnostic pop

  // Mock MSDistribute isNewerVersion to return YES.
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock isNewerVersion:[OCMArg any]]).andReturn(YES);

  // Mock reachability.
  id reachabilityMock = OCMClassMock([MS_Reachability class]);
  OCMStub([reachabilityMock reachabilityForInternetConnection]).andReturn(reachabilityMock);
  OCMStub([reachabilityMock currentReachabilityStatus]).andDo(^(NSInvocation *invocation) {
    NetworkStatus test = NotReachable;
    [invocation setReturnValue:&test];
  });

  // Persist release to be picked up.
  [MS_USER_DEFAULTS setObject:[details serializeToDictionary] forKey:kMSMandatoryReleaseKey];

  /*
   * When
   */
  [self.sut checkLatestRelease:@"whateverToken" releaseHash:@"whateverReleaseHash"];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expection fulfill];
  });
  [self waitForExpectationsWithTimeout:1
                               handler:^(__attribute__((unused)) NSError *error) {

                                 /*
                                  * Then
                                  */
                                 OCMVerify([alertControllerMock alertControllerWithTitle:[OCMArg any] message:message]);
                                 OCMReject([alertControllerMock
                                     addDefaultActionWithTitle:MSDistributeLocalizedString(@"MSDistributeAskMeInADay")
                                                       handler:[OCMArg any]]);
                                 OCMVerify([alertControllerMock
                                     addDefaultActionWithTitle:MSDistributeLocalizedString(
                                                                   @"MSDistributeViewReleaseNotes")
                                                       handler:[OCMArg any]]);
                                 OCMVerify([alertControllerMock addPreferredActionWithTitle:[OCMArg any]
                                                                                    handler:[OCMArg any]]);
                               }];
}

- (void)testDontShowConfirmationAlertIfNoMandatoryReleaseWhileNoNetwork {

  /*
   * If
   */
  XCTestExpectation *expection = [self expectationWithDescription:@"Confirmation alert has been displayed"];

  // Mock alert.
  id alertControllerMock = OCMClassMock([MSAlertController class]);
  OCMStub([alertControllerMock alertControllerWithTitle:[OCMArg any] message:[OCMArg any]])
      .andReturn(alertControllerMock);

  // Mock reachability.
  id reachabilityMock = OCMClassMock([MS_Reachability class]);
  OCMStub([reachabilityMock reachabilityForInternetConnection]).andReturn(reachabilityMock);
  OCMStub([reachabilityMock currentReachabilityStatus]).andDo(^(NSInvocation *invocation) {
    NetworkStatus test = NotReachable;
    [invocation setReturnValue:&test];
  });

  /*
   * When
   */
  [self.sut checkLatestRelease:@"whateverToken" releaseHash:@"whateverReleaseHash"];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expection fulfill];
  });
  [self waitForExpectationsWithTimeout:1
                               handler:^(__attribute__((unused)) NSError *error) {

                                 /*
                                  * Then
                                  */
                                 OCMReject(
                                     [alertControllerMock alertControllerWithTitle:[OCMArg any] message:[OCMArg any]]);
                                 OCMReject(
                                     [alertControllerMock addDefaultActionWithTitle:[OCMArg any] handler:[OCMArg any]]);
                                 OCMReject(
                                     [alertControllerMock addCancelActionWithTitle:[OCMArg any] handler:[OCMArg any]]);
                               }];
}

- (void)testPersistLastestMandatoryUpdate {

  // If
  MSReleaseDetails *details = [MSReleaseDetails new];
  details.releaseNotes = MS_UUID_STRING;
  details.id = @(42);
  details.downloadUrl = [NSURL URLWithString:@"https://contoso.com"];
  details.mandatoryUpdate = YES;
  details.status = @"available";

  // Mock MSDistribute isNewerVersion to return YES.
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock isNewerVersion:[OCMArg any]]).andReturn(YES);

  // When
  [self.sut handleUpdate:details];

  // Then
  NSMutableDictionary *persistedDict = [self.settingsMock objectForKey:kMSMandatoryReleaseKey];
  MSReleaseDetails *persistedRelease = [[MSReleaseDetails alloc] initWithDictionary:persistedDict];
  assertThat(persistedRelease, notNilValue());
  assertThat([details serializeToDictionary], is(persistedDict));
}

- (void)testDontPersistLastestReleaseIfNotMandatory {

  // If
  MSReleaseDetails *details = [MSReleaseDetails new];
  details.releaseNotes = MS_UUID_STRING;
  details.id = @(42);
  details.downloadUrl = [NSURL URLWithString:@"https://contoso.com"];
  details.mandatoryUpdate = NO;
  details.status = @"available";

  // When
  [self.sut handleUpdate:details];

  // Then
  NSMutableDictionary *persistedDict = [self.settingsMock objectForKey:kMSMandatoryReleaseKey];
  assertThat(persistedDict, nilValue());
}

- (void)testOpenUrl {

  // If
  NSString *scheme = [NSString stringWithFormat:kMSDefaultCustomSchemeFormat, kMSTestAppSecret];
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock sharedInstance]).andReturn(distributeMock);
  OCMStub([distributeMock checkLatestRelease:[OCMArg any] releaseHash:kMSTestReleaseHash]).andDo(nil);
  id mobileCeneterMock = OCMClassMock([MSMobileCenter class]);
  OCMStub([mobileCeneterMock isConfigured]).andReturn(YES);
  [self mockMSPackageHash];
  
  // When
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://?", scheme]];
  BOOL result = [MSDistribute openURL:url];
  
  // Then
  assertThatBool(result, isFalse());
  OCMReject([distributeMock checkLatestRelease:[OCMArg any] releaseHash:[OCMArg any]]);
  
  // Disable for now to bypass initializing sender.
  [distributeMock setEnabled:NO];
  [distributeMock startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];

  // Enable again.
  [distributeMock setEnabled:YES];
  
  url = [NSURL URLWithString:@"invalid://?"];

  // When
  result = [MSDistribute openURL:url];

  // Then
  assertThatBool(result, isFalse());
  OCMReject([distributeMock checkLatestRelease:[OCMArg any] releaseHash:[OCMArg any]]);

  // If
  url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://?", scheme]];

  // When
  result = [MSDistribute openURL:url];

  // Then
  assertThatBool(result, isTrue());
  OCMReject([distributeMock checkLatestRelease:[OCMArg any] releaseHash:[OCMArg any]]);

  // If
  NSString *requestId = @"FIRST-REQUEST";
  url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://?request_id=%@", scheme, requestId]];

  // When
  result = [MSDistribute openURL:url];

  // Then
  assertThatBool(result, isTrue());
  OCMReject([distributeMock checkLatestRelease:[OCMArg any] releaseHash:[OCMArg any]]);

  // If
  NSString *token = @"TOKEN";
  url = [NSURL
      URLWithString:[NSString stringWithFormat:@"%@://?request_id=%@&update_token=%@", scheme, requestId, token]];

  // When
  result = [MSDistribute openURL:url];

  // Then
  assertThatBool(result, isTrue());
  OCMReject([distributeMock checkLatestRelease:[OCMArg any] releaseHash:[OCMArg any]]);

  // If
  [MS_USER_DEFAULTS setObject:requestId forKey:kMSUpdateTokenRequestIdKey];
  url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://?request_id=%@&update_token=%@",
                                                        [NSString stringWithFormat:kMSDefaultCustomSchemeFormat,
                                                                                   @"Invalid-app-secret"],
                                                        requestId, token]];

  // When
  result = [MSDistribute openURL:url];

  // Then
  assertThatBool(result, isFalse());
  OCMReject([distributeMock checkLatestRelease:[OCMArg any] releaseHash:[OCMArg any]]);

  // If
  url = [NSURL
      URLWithString:[NSString stringWithFormat:@"%@://?request_id=%@&update_token=%@", scheme, requestId, token]];

  // When
  result = [MSDistribute openURL:url];

  // Then
  assertThatBool(result, isTrue());
  OCMVerify([distributeMock checkLatestRelease:token releaseHash:kMSTestReleaseHash]);

  // If
  [distributeMock setEnabled:NO];

  // When
  [MSDistribute openURL:url];

  // Then
  assertThatBool(result, isTrue());
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

  // When
  [distributeMock applyEnabledState:NO];

  // Then
  XCTAssertNil([self.settingsMock objectForKey:kMSUpdateTokenRequestIdKey]);
}

- (void)testApplyEnabledStateTrue {

  // If
  NSDictionary<NSString *, id> *plist = @{ @"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1" };
  OCMStub([self.bundleMock infoDictionary]).andReturn(plist);
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

  // Then
  XCTAssertNotNil([self.settingsMock objectForKey:kMSUpdateTokenRequestIdKey]);

  // When
  [distributeMock applyEnabledState:NO];

  // Then
  XCTAssertNil([self.settingsMock objectForKey:kMSUpdateTokenRequestIdKey]);
}

- (void)testCheckForUpdatesAllConditionsMet {

  // If
  [MSDistributeTestUtil unMockUpdatesAllowedConditions];
  id mobileCenterMock = OCMClassMock([MSMobileCenter class]);
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock checkLatestRelease:[OCMArg any] releaseHash:[OCMArg any]]).andDo(nil);
  OCMStub([distributeMock requestUpdateToken:[OCMArg any]]).andDo(nil);
  id utilityMock = [self mockMSPackageHash];

  // When
  OCMStub([mobileCenterMock isDebuggerAttached]).andReturn(NO);
  OCMStub([utilityMock currentAppEnvironment]).andReturn(MSEnvironmentOther);

  // Then
  XCTAssertTrue([self.sut checkForUpdatesAllowed]);

  // When
  [distributeMock applyEnabledState:YES];

  // Then
  OCMVerify([distributeMock requestUpdateToken:kMSTestReleaseHash]);
}

- (void)testCheckForUpdatesDebuggerAttached {

  // When
  [MSDistributeTestUtil unMockUpdatesAllowedConditions];
  id mobileCenterMock = OCMClassMock([MSMobileCenter class]);
  id utilityMock = OCMClassMock([MSUtility class]);
  OCMStub([mobileCenterMock isDebuggerAttached]).andReturn(YES);
  OCMStub([utilityMock currentAppEnvironment]).andReturn(MSEnvironmentOther);

  // Then
  XCTAssertFalse([self.sut checkForUpdatesAllowed]);
}

- (void)testCheckForUpdatesInvalidEnvironment {

  // When
  [MSDistributeTestUtil unMockUpdatesAllowedConditions];
  id mobileCenterMock = OCMClassMock([MSMobileCenter class]);
  id utilityMock = OCMClassMock([MSUtility class]);
  OCMStub([mobileCenterMock isDebuggerAttached]).andReturn(NO);
  OCMStub([utilityMock currentAppEnvironment]).andReturn(MSEnvironmentTestFlight);

  // Then
  XCTAssertFalse([self.sut checkForUpdatesAllowed]);
}

- (void)testNotDeleteUpdateToken {

  // If
  [MS_USER_DEFAULTS setObject:@1 forKey:kMSSDKHasLaunchedWithDistribute];
  id keychainMock = OCMClassMock([MSKeychainUtil class]);

  // When
  [MSDistribute new];

  // Then
  OCMReject([keychainMock deleteStringForKey:kMSUpdateTokenKey]);
}

- (void)testDeleteUpdateTokenAfterReinstall {

  // If
  id keychainMock = OCMClassMock([MSKeychainUtil class]);

  // When
  [MSDistribute new];

  // Then
  OCMVerify([keychainMock deleteStringForKey:kMSUpdateTokenKey]);
  OCMVerify([self.settingsMock setObject:@(1) forKey:kMSSDKHasLaunchedWithDistribute]);
}

- (void)testWithoutNetwork {

  // If
  id reachabilityMock = OCMClassMock([MS_Reachability class]);
  OCMStub([reachabilityMock reachabilityForInternetConnection]).andReturn(reachabilityMock);
  OCMStub([reachabilityMock currentReachabilityStatus]).andReturn(NotReachable);
  id distributeMock = OCMPartialMock(self.sut);

  // We should not touch UI in a unit testing environment.
  OCMStub([distributeMock openURLInEmbeddedSafari:[OCMArg any] fromClass:[OCMArg any]]).andDo(nil);

  // When
  [distributeMock requestUpdateToken:kMSTestReleaseHash];

  // Then
  OCMReject([distributeMock buildTokenRequestURLWithAppSecret:[OCMArg any] releaseHash:kMSTestReleaseHash]);
}

- (void)testPackageHash {

  // If
  // cd55e7a9-7ad1-4ca6-b722-3d133f487da9:1.0:1 -> 1ddf47f8dda8928174c419d530adcc13bb63cebfaf823d83ad5269b41e638ef4
  NSDictionary<NSString *, id> *plist = @{ @"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1" };
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
  self.sut.safariHostingViewController = nil;

  // When
  [self.sut dismissEmbeddedSafari];
  dispatch_async(dispatch_get_main_queue(), ^{
    [safariDismissedExpectation fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 OCMReject([viewControllerMock dismissViewControllerAnimated:(BOOL)OCMOCK_ANY
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
  [MS_USER_DEFAULTS setObject:@"FIRST-REQUEST" forKey:kMSUpdateTokenRequestIdKey];
  NSDictionary<NSString *, id> *plist = @{ @"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1" };
  OCMStub([self.bundleMock infoDictionary]).andReturn(plist);
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://?request_id=FIRST-REQUEST&update_token=token",
                                                               [NSString stringWithFormat:kMSDefaultCustomSchemeFormat,
                                                                                          kMSTestAppSecret]]];
  XCTestExpectation *safariDismissedExpectation = [self expectationWithDescription:@"Safari dismissed processed"];
  id viewControllerMock = OCMClassMock([UIViewController class]);
  self.sut.safariHostingViewController = viewControllerMock;

  // When
  [MSDistribute openURL:url];
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
  OCMStub([self.bundleMock objectForInfoDictionaryKey:@"CFBundleURLTypes"]).andReturn(bundleArray);
  id distributeMock = OCMPartialMock(self.sut);

  // When
  NSURL *url = [distributeMock buildTokenRequestURLWithAppSecret:kMSTestAppSecret releaseHash:kMSTestReleaseHash];

  // Then
  assertThat(url, nilValue());
}

- (void)testIsNewerVersionFunction {
  NSDictionary<NSString *, id> *plist = @{ @"CFBundleShortVersionString" : @"10.0", @"CFBundleVersion" : @"10" };
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
  sameRelease.packageHashes = [[NSArray alloc] initWithObjects:MSPackageHash(), nil];

  // When
  result = [[MSDistribute sharedInstance] isNewerVersion:sameRelease];

  // Then
  XCTAssertFalse(result);
}

- (void)testStartUpdateWhenApplicationEnterForeground {

  // If
  id notificationCenterMock = OCMPartialMock([NSNotificationCenter new]);
  OCMStub([notificationCenterMock defaultCenter]).andReturn(notificationCenterMock);
  id distributeMock = OCMPartialMock([MSDistribute new]);
  __block int startUpdateCounter = 0;
  OCMStub([distributeMock startUpdate]).andDo(^(__attribute((unused)) NSInvocation *invocation) {
    startUpdateCounter++;
  });

  // When
  [distributeMock setEnabled:NO];
  [notificationCenterMock postNotificationName:UIApplicationWillEnterForegroundNotification object:nil];

  // Then
  OCMVerify([distributeMock isEnabled]);
  OCMReject([distributeMock startUpdate]);
  XCTAssertEqual(startUpdateCounter, 0);

  // When
  [distributeMock setEnabled:YES];

  // Then
  OCMVerify([distributeMock startUpdate]);
  XCTAssertEqual(startUpdateCounter, 1);

  // When
  [notificationCenterMock postNotificationName:UIApplicationWillEnterForegroundNotification object:nil];

  // Then
  OCMVerify([distributeMock isEnabled]);
  OCMVerify([distributeMock startUpdate]);
  XCTAssertEqual(startUpdateCounter, 2);
}

- (void)testNotifyUpdateAction {

  // If
  id distributeMock = OCMPartialMock(self.sut);
  id utilityMock = OCMClassMock([MSUtility class]);
  double time = 1.1;
  OCMStub(ClassMethod([utilityMock nowInMilliseconds])).andReturn(time);
  [distributeMock setValue:OCMClassMock([MSReleaseDetails class]) forKey:@"releaseDetails"];

  // When
  [distributeMock notifyUpdateAction:MSUpdateActionPostpone];

  // Then
  assertThat([self.settingsMock objectForKey:kMSPostponedTimestampKey], equalToLongLong((long long)time));
}

- (void)testNotifyUpdateActionTwice {

  // If
  id distributeMock = OCMPartialMock(self.sut);
  id utilityMock = OCMClassMock([MSUtility class]);
  double time = 1.1;
  OCMStub(ClassMethod([utilityMock nowInMilliseconds])).andReturn(time);
  [distributeMock setValue:OCMClassMock([MSReleaseDetails class]) forKey:@"releaseDetails"];

  // When
  [distributeMock notifyUpdateAction:MSUpdateActionPostpone];

  // Then
  assertThat([self.settingsMock objectForKey:kMSPostponedTimestampKey], equalToLongLong((long long)time));

  // If
  [MS_USER_DEFAULTS removeObjectForKey:kMSPostponedTimestampKey];

  // When
  [distributeMock notifyUpdateAction:MSUpdateActionPostpone];

  // Then
  XCTAssertNil([self.settingsMock objectForKey:kMSPostponedTimestampKey]);
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
  XCTestExpectation *showConfirmationAlertExpectation =
      [self expectationWithDescription:@"showConfirmationAlert Called."];

  MSReleaseDetails *details = [MSReleaseDetails new];
  details.status = @"available";
  id detailsMock = OCMPartialMock(details);
  OCMStub([detailsMock isValid]).andReturn(YES);
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock isNewerVersion:detailsMock]).andReturn(YES);
  OCMStub([distributeMock showConfirmationAlert:detailsMock]).andDo(nil);

  // When
  [distributeMock handleUpdate:detailsMock];
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
}

- (void)testDefaultUpdateAlertWithDelegate {

  // If
  XCTestExpectation *showConfirmationAlertExpectation =
      [self expectationWithDescription:@"showConfirmationAlert Called."];

  MSReleaseDetails *details = [MSReleaseDetails new];
  details.status = @"available";
  id detailsMock = OCMPartialMock(details);
  OCMStub([detailsMock isValid]).andReturn(YES);
  id delegateMock = OCMProtocolMock(@protocol(MSDistributeDelegate));
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock isNewerVersion:detailsMock]).andReturn(YES);
  OCMStub([distributeMock showConfirmationAlert:detailsMock]).andDo(nil);

  // When
  OCMStub([delegateMock distribute:distributeMock releaseAvailableWithDetails:[OCMArg any]]).andReturn(NO);
  [distributeMock setDelegate:delegateMock];
  [distributeMock handleUpdate:detailsMock];
  dispatch_async(dispatch_get_main_queue(), ^{
    [showConfirmationAlertExpectation fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 OCMVerify([[distributeMock delegate] distribute:distributeMock
                                                     releaseAvailableWithDetails:detailsMock]);
                                 OCMVerify([distributeMock showConfirmationAlert:detailsMock]);
                               }];
}

- (void)testCustomizedUpdateAlert {

  // If
  XCTestExpectation *showConfirmationAlertExpectation =
      [self expectationWithDescription:@"showConfirmationAlert Called."];

  MSReleaseDetails *details = [MSReleaseDetails new];
  details.status = @"available";
  id detailsMock = OCMPartialMock(details);
  OCMStub([detailsMock isValid]).andReturn(YES);
  id delegateMock = OCMProtocolMock(@protocol(MSDistributeDelegate));
  id distributeMock = OCMPartialMock(self.sut);
  OCMStub([distributeMock isNewerVersion:detailsMock]).andReturn(YES);
  OCMStub([distributeMock showConfirmationAlert:detailsMock]).andDo(nil);

  // When
  OCMStub([delegateMock distribute:distributeMock releaseAvailableWithDetails:[OCMArg any]]).andReturn(YES);
  [distributeMock setDelegate:delegateMock];
  [distributeMock handleUpdate:detailsMock];
  dispatch_async(dispatch_get_main_queue(), ^{
    [showConfirmationAlertExpectation fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 OCMVerify([[distributeMock delegate] distribute:distributeMock
                                                     releaseAvailableWithDetails:detailsMock]);
                                 OCMReject([distributeMock showConfirmationAlert:detailsMock]);
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
  OCMStub(ClassMethod([utilityMock sha256:[OCMArg any]])).andReturn(kMSTestReleaseHash);
#pragma GCC diagnostic pop

  NSDictionary<NSString *, id> *plist = @{ @"CFBundleShortVersionString" : @"1.0", @"CFBundleVersion" : @"1" };
  OCMStub([self.bundleMock infoDictionary]).andReturn(plist);
  return utilityMock;
}

@end
