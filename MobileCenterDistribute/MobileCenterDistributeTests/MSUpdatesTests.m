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
#import "MSServiceAbstract.h"
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

@interface MSUpdatesTests : XCTestCase

@property(nonatomic, strong) MSDistribute *sut;
@property(nonatomic, strong) id parserMock;

@end

@implementation MSUpdatesTests

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
  OCMStub([self.parserMock uuid]).andReturn([[NSUUID alloc] initWithUUIDString:@"CD55E7A9-7AD1-4CA6-B722-3D133F487DA9"]);
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
  id updateMock = OCMPartialMock(self.sut);

  // Disable for now to bypass initializing sender.
  [updateMock setEnabled:NO];
  [updateMock startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];

  // Enable again.
  [updateMock setEnabled:YES];

  // When
  NSURL *url = [updateMock buildTokenRequestURLWithAppSecret:kMSTestAppSecret];
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
  assertThat(queryStrings[kMSUpdtsURLQueryPlatformKey], is(kMSUpdtsURLQueryPlatformValue));
  assertThat(queryStrings[kMSUpdtsURLQueryRedirectIdKey],
             is([NSString stringWithFormat:kMSUpdtsDefaultCustomSchemeFormat, kMSTestAppSecret]));
  assertThat(queryStrings[kMSUpdtsURLQueryRequestIdKey], notNilValue());
  assertThat(queryStrings[kMSUpdtsURLQueryReleaseHashKey], notNilValue());
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
  id updatesMock = OCMPartialMock(self.sut);
  OCMStub([updatesMock showConfirmationAlert:[OCMArg any]]).andDo(nil);

  // When
  [updatesMock handleUpdate:details];

  // Then
  OCMReject([updatesMock showConfirmationAlert:[OCMArg any]]);

  // If
  details.id = @1;
  details.downloadUrl = [NSURL URLWithString:@"https://contoso.com/valid/url"];

  // When
  [updatesMock handleUpdate:details];

  // Then
  OCMReject([updatesMock showConfirmationAlert:[OCMArg any]]);

  // If
  details.status = @"available";
  details.minOs = @"1000.0";

  // When
  [updatesMock handleUpdate:details];

  // Then
  OCMReject([updatesMock showConfirmationAlert:[OCMArg any]]);

  // If
  details.minOs = @"1.0";
  OCMStub([updatesMock isNewerVersion:[OCMArg any]]).andReturn(NO).andReturn(YES);

  // When
  [updatesMock handleUpdate:details];

  // Then
  OCMReject([updatesMock showConfirmationAlert:[OCMArg any]]);

  // When
  [updatesMock handleUpdate:details];

  // Then
  OCMVerify([updatesMock showConfirmationAlert:[OCMArg any]]);
}

- (void)testOpenUrl {

  // If
  NSString *scheme = [NSString stringWithFormat:kMSUpdtsDefaultCustomSchemeFormat, kMSTestAppSecret];
  id updateMock = OCMPartialMock(self.sut);
  OCMStub([updateMock checkLatestRelease:[OCMArg any]]).andDo(nil);

  // Disable for now to bypass initializing sender.
  [updateMock setEnabled:NO];
  [updateMock startWithLogManager:OCMProtocolMock(@protocol(MSLogManager)) appSecret:kMSTestAppSecret];

  // Enable again.
  [updateMock setEnabled:YES];
  NSURL *url = [NSURL URLWithString:@"invalid://?"];

  // When
  [updateMock openUrl:url];

  // Then
  OCMReject([updateMock checkLatestRelease:[OCMArg any]]);

  // If
  url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://?", scheme]];

  // When
  [updateMock openUrl:url];

  // Then
  OCMReject([updateMock checkLatestRelease:[OCMArg any]]);

  // If
  url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://?request_id=FIRST-REQUEST", scheme]];

  // When
  [updateMock openUrl:url];

  // Then
  OCMReject([updateMock checkLatestRelease:[OCMArg any]]);

  // If
  url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://?request_id=FIRST-REQUEST&update_token=token", scheme]];

  // When
  [updateMock openUrl:url];

  // Then
  OCMReject([updateMock checkLatestRelease:[OCMArg any]]);

  // If
  [MS_USER_DEFAULTS setObject:@"FIRST-REQUEST" forKey:kMSUpdateTokenRequestIdKey];
  url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://?request_id=FIRST-REQUEST&update_token=token",
                                                        [NSString stringWithFormat:kMSUpdtsDefaultCustomSchemeFormat,
                                                                                   @"Invalid-app-secret"]]];

  // When
  [updateMock openUrl:url];

  // Then
  OCMReject([updateMock checkLatestRelease:[OCMArg any]]);

  // If
  url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://?request_id=FIRST-REQUEST&update_token=token", scheme]];

  // When
  [updateMock openUrl:url];

  // Then
  OCMVerify([updateMock checkLatestRelease:@"token"]);

  // If
  [updateMock setEnabled:NO];

  // When
  [updateMock openUrl:url];

  // Then
  OCMReject([updateMock checkLatestRelease:[OCMArg any]]);
}

- (void)testApplyEnabledStateTrue {

  // If
  id updateMock = OCMPartialMock(self.sut);
  OCMStub([updateMock checkLatestRelease:[OCMArg any]]).andDo(nil);
  OCMStub([updateMock requestUpdateToken]).andDo(nil);

  // When
  [updateMock applyEnabledState:YES];

  // Then
  OCMVerify([updateMock requestUpdateToken]);

  // If
  [MSKeychainUtil storeString:@"UpdateToken" forKey:kMSUpdateTokenKey];

  // When
  [updateMock applyEnabledState:YES];

  // Then
  OCMVerify([updateMock checkLatestRelease:[OCMArg any]]);

  // If
  [MS_USER_DEFAULTS setObject:@"RequestID" forKey:kMSUpdateTokenRequestIdKey];
  [MS_USER_DEFAULTS setObject:@"ReleaseID" forKey:kMSIgnoredReleaseIdKey];

  // Then
  XCTAssertNotNil([MS_USER_DEFAULTS objectForKey:kMSUpdateTokenRequestIdKey]);
  XCTAssertNotNil([MS_USER_DEFAULTS objectForKey:kMSIgnoredReleaseIdKey]);

  // When
  [updateMock applyEnabledState:NO];

  // Then
  XCTAssertNil([MS_USER_DEFAULTS objectForKey:kMSUpdateTokenRequestIdKey]);
  XCTAssertNil([MS_USER_DEFAULTS objectForKey:kMSIgnoredReleaseIdKey]);
}

@end
