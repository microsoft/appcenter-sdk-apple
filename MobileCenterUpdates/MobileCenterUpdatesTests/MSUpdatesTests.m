#import "MSUpdates.h"
#import "MSUpdatesPrivate.h"

#import "MSUpdatesInternal.h"
#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

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
  self.sut = [MSUpdates new];
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
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
@end
