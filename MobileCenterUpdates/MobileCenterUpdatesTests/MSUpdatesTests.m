#import "MSUpdates.h"
#import "MSUpdatesPrivate.h"

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

@interface MobileCenterUpdatesTests : XCTestCase

@property(nonatomic, readwrite) MSUpdates *updates;

@end

@implementation MobileCenterUpdatesTests

- (void)setUp {
  self.updates = [MSUpdates new];
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testUpdateURL {

  // If
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock mainBundle]).andReturn([NSBundle bundleForClass:[self class]]);

  // When
  NSURL *url = [self.updates buildTokenRequestURLWithAppSecret:kMSTestAppSecret];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
  NSMutableDictionary<NSString *, NSString *> *queryStrings = [NSMutableDictionary<NSString *, NSString *> new];
  [components.queryItems
      enumerateObjectsUsingBlock:^(__kindof NSURLQueryItem *_Nonnull queryItem, NSUInteger idx, BOOL *_Nonnull stop) {
        if (queryItem.value) {
          [queryStrings setObject:(NSString * _Nonnull)queryItem.value forKey:queryItem.name];
        }
      }];

  // Then
  assertThatLong(queryStrings.count, equalToLong(4));
  assertThatBool([components.path containsString:kMSTestAppSecret], isTrue());
  assertThat(queryStrings[kMSUpdtURLQueryPlatformKey], is(kMSUpdtURLQueryPlatformValue));
  assertThat(queryStrings[kMSUpdtURLQueryRedirectIdKey], is(kMSUpdtDefaultCustomScheme));
  assertThat(queryStrings[kMSUpdtURLQueryRequestIdKey], notNilValue());
  assertThat(queryStrings[kMSUpdtURLQueryReleaseHashKey], notNilValue());
}

- (void)testOpenURLInSafariApp {

  // If
  NSURL *url = [NSURL URLWithString:@"https://contoso.com"];
  id appMock = OCMClassMock([UIApplication class]);
  OCMStub([appMock sharedApplication]).andReturn(appMock);
  OCMStub([appMock canOpenURL:url]).andReturn(YES);
  OCMStub([appMock openURL:url]).andDo(nil);

  // When
  [self.updates openURLInSafariApp:url];

  // Then
  OCMVerify([appMock openURL:url]);
}

- (void)testOpenURLInEmbeddedSafari {

  // If
  NSURL *url = [NSURL URLWithString:@"https://contoso.com"];

  // When
  @try {
    [self.updates openURLInEmbeddedSafari:url fromClass:[SFSafariViewController class]];
  } @catch (NSException *ex) {

    /**
     * TODO: This is not a UI test so we expect it to fail with NSInternalInconsistencyException exception.
     * Hopefully it doesn't prevent the URL to be set. Maybe introduce UI testing for this case in the future.
     */
    if (ex.name != NSInternalInconsistencyException) {
      // Re-throw exception if not expected.
      @throw ex;
    }
  }

  // Then
  assertThat(SFSafariViewController.url, is(url));
}

@end
