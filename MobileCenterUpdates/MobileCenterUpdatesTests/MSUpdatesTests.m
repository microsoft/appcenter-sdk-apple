#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSServiceAbstract.h"
#import "MSServiceInternal.h"
#import "MSUpdates.h"
#import "MSUpdatesInternal.h"
#import "MSUpdatesPrivate.h"
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

@property(nonatomic, strong) MSUpdates *sut;

@end

@implementation MSUpdatesTests

- (void)setUp {
  [super setUp];
  self.sut = [MSUpdates new];
  [MS_USER_DEFAULTS removeObjectForKey:kMSUpdateTokenRequestIdKey];
}

- (void)tearDown {
  [super tearDown];
  [MS_USER_DEFAULTS removeObjectForKey:kMSUpdateTokenRequestIdKey];
}

- (void)testUpdateURL {

  // If
  NSError *error = nil;
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn([NSBundle bundleForClass:[self class]]);

  // When
  NSURL *url = [self.sut buildTokenRequestURLWithAppSecret:kMSTestAppSecret error:&error];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
  NSMutableDictionary<NSString *, NSString *> *queryStrings = [NSMutableDictionary<NSString *, NSString *> new];
  [components.queryItems
      enumerateObjectsUsingBlock:^(__kindof NSURLQueryItem *_Nonnull queryItem, NSUInteger idx, BOOL *_Nonnull stop) {
        if (queryItem.value) {
          [queryStrings setObject:(NSString * _Nonnull)queryItem.value forKey:queryItem.name];
        }
      }];

  // Then
  assertThat(error, nilValue());
  assertThatLong(queryStrings.count, equalToLong(4));
  assertThatBool([components.path containsString:kMSTestAppSecret], isTrue());
  assertThat(queryStrings[kMSUpdtsURLQueryPlatformKey], is(kMSUpdtsURLQueryPlatformValue));
  assertThat(queryStrings[kMSUpdtsURLQueryRedirectIdKey], is(kMSUpdtsDefaultCustomScheme));
  assertThat(queryStrings[kMSUpdtsURLQueryRequestIdKey], notNilValue());
  assertThat(queryStrings[kMSUpdtsURLQueryReleaseHashKey], notNilValue());
}

- (void)testMalformedUpdateURL {

  // If
  NSError *error = nil;
  NSString *badAppSecret = @"weird\\app\\secret";
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn([NSBundle bundleForClass:[self class]]);

  // When
  NSURL *url = [self.sut buildTokenRequestURLWithAppSecret:badAppSecret error:&error];

  assertThat(url, nilValue());
  assertThat(error, notNilValue());
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
  id updateMock = OCMPartialMock(self.sut);
  OCMStub([updateMock checkLatestRelease]).andDo(nil);
  NSURL *url = [NSURL URLWithString:@"invalid://?"];

  // When
  [updateMock openUrl:url];

  // Then
  OCMReject([updateMock checkLatestRelease]);

  // If
  url = [NSURL URLWithString:@"msupdt://?"];

  // When
  [updateMock openUrl:url];

  // Then
  OCMReject([updateMock checkLatestRelease]);

  // If
  url = [NSURL URLWithString:@"msupdt://?request_id=FIRST-REQUEST"];

  // When
  [updateMock openUrl:url];

  // Then
  OCMReject([updateMock checkLatestRelease]);

  // If
  url = [NSURL URLWithString:@"msupdt://?request_id=FIRST-REQUEST&update_token=token"];

  // When
  [updateMock openUrl:url];

  // Then
  OCMReject([updateMock checkLatestRelease]);

  // If
  [MS_USER_DEFAULTS setObject:@"FIRST-REQUEST" forKey:kMSUpdateTokenRequestIdKey];
  url = [NSURL URLWithString:@"msupdt://?request_id=FIRST-REQUEST&update_token=token"];

  // When
  [updateMock openUrl:url];

  // Then
  OCMVerify([updateMock checkLatestRelease]);

  // If
  [updateMock setEnabled:NO];

  // When
  [updateMock openUrl:url];

  // Then
  OCMReject([updateMock checkLatestRelease]);
}

@end
