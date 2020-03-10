// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "AppCenter+Internal.h"
#import "MSAppCenterErrors.h"
#import "MSAppCenterIngestion.h"
#import "MSConstants+Internal.h"
#import "MSDeviceInternal.h"
#import "MSHttpClient.h"
#import "MSHttpIngestionPrivate.h"
#import "MSHttpTestUtil.h"
#import "MSHttpUtil.h"
#import "MSLoggerInternal.h"
#import "MSMockLog.h"
#import "MSTestFrameworks.h"
#import "MSTestUtil.h"

static NSTimeInterval const kMSTestTimeout = 5.0;
static NSString *const kMSBaseUrl = @"https://test.com";
static NSString *const kMSTestAppSecret = @"TestAppSecret";

@interface MSAppCenterIngestionTests : XCTestCase

@property(nonatomic) MSAppCenterIngestion *sut;
@property(nonatomic) id deviceMock;
@property(nonatomic) id reachabilityMock;
@property(nonatomic) NetworkStatus currentNetworkStatus;
@property(nonatomic) id httpClientMock;

@end

/*
 * TODO: Separate base MSHttpIngestion tests from this test and instantiate MSAppCenterIngestion with initWithBaseUrl:, not the one with
 * multiple parameters. Look at comments in each method. Add testHeaders to verify headers are populated properly. Look at testHeaders in
 * MSOneCollectorIngestionTests.
 */
@implementation MSAppCenterIngestionTests

- (void)setUp {
  [super setUp];

  NSDictionary *headers = @{@"Content-Type" : @"application/json", @"App-Secret" : kMSTestAppSecret, @"Install-ID" : MS_UUID_STRING};
  NSDictionary *queryStrings = @{@"api-version" : @"1.0.0"};
  self.httpClientMock = OCMPartialMock([MSHttpClient new]);
  self.deviceMock = OCMPartialMock([MSDevice new]);
  OCMStub([self.deviceMock isValid]).andReturn(YES);

  // Mock reachability.
  self.reachabilityMock = OCMClassMock([MS_Reachability class]);
  self.currentNetworkStatus = ReachableViaWiFi;
  OCMStub([self.reachabilityMock currentReachabilityStatus]).andDo(^(NSInvocation *invocation) {
    NetworkStatus test = self.currentNetworkStatus;
    [invocation setReturnValue:&test];
  });

  // sut: System under test
  self.sut = [[MSAppCenterIngestion alloc] initWithHttpClient:self.httpClientMock
                                                      baseUrl:kMSBaseUrl
                                                      apiPath:@"/test-path"
                                                      headers:headers
                                                 queryStrings:queryStrings
                                               retryIntervals:@[ @(0.5), @(1), @(1.5) ]];
  [self.sut setAppSecret:kMSTestAppSecret];
}

- (void)tearDown {
  [MSHttpTestUtil removeAllStubs];

  /*
   * Setting the variable to nil. We are experiencing test failure on Xcode 9 beta because the instance that was used for previous test
   * method is not disposed and still listening to network changes in other tests.
   */
  [MS_NOTIFICATION_CENTER removeObserver:self.sut name:kMSReachabilityChangedNotification object:nil];
  self.sut = nil;

  // Stop mock.
  [self.deviceMock stopMocking];
  [self.httpClientMock stopMocking];
  [self.reachabilityMock stopMocking];
  [super tearDown];
}

- (void)testSendBatchLogs {

  // Stub http response
  [MSHttpTestUtil stubHttp200Response];
  NSString *containerId = @"1";
  MSLogContainer *container = [MSTestUtil createLogContainerWithId:containerId device:self.deviceMock];
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP Response 200"];
  [self.sut sendAsync:container
      completionHandler:^(NSString *batchId, NSHTTPURLResponse *response, __unused NSData *data, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqual(containerId, batchId);
        XCTAssertEqual((MSHTTPCodesNo)response.statusCode, MSHTTPCodesNo200OK);

        [expectation fulfill];
      }];

  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testInvalidContainer {
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Http call complete."];
  MSAbstractLog *log = [MSAbstractLog new];
  log.sid = MS_UUID_STRING;
  log.timestamp = [NSDate date];

  // Log does not have device info, therefore, it's an invalid log
  MSLogContainer *container = [[MSLogContainer alloc] initWithBatchId:@"1" andLogs:(NSArray<id<MSLog>> *)@[ log ]];

  // Then
  OCMReject([self.httpClientMock sendAsync:OCMOCK_ANY
                                    method:OCMOCK_ANY
                                   headers:OCMOCK_ANY
                                      data:OCMOCK_ANY
                            retryIntervals:OCMOCK_ANY
                        compressionEnabled:OCMOCK_ANY
                         completionHandler:OCMOCK_ANY]);

  // When
  [self.sut sendAsync:container
      completionHandler:^(__unused NSString *batchId, __unused NSHTTPURLResponse *response, __unused NSData *data, NSError *error) {
        XCTAssertEqual(error.domain, kMSACErrorDomain);
        XCTAssertEqual(error.code, MSACLogInvalidContainerErrorCode);
        [expectation fulfill];
      }];
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testNilContainer {

  MSLogContainer *container = nil;

  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP Network Down"];
  [self.sut sendAsync:container
      completionHandler:^(__unused NSString *batchId, __unused NSHTTPURLResponse *response, __unused NSData *data, NSError *error) {
        XCTAssertNotNil(error);
        [expectation fulfill];
      }];

  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testHttpClientDelegateObfuscateHeaderValue {

  // If
  id mockLogger = OCMClassMock([MSLogger class]);
  id mockHttpUtil = OCMClassMock([MSHttpUtil class]);
  OCMStub([mockLogger currentLogLevel]).andReturn(MSLogLevelVerbose);
  OCMStub(ClassMethod([mockHttpUtil hideSecret:OCMOCK_ANY])).andDo(nil);
  NSDictionary<NSString *, NSString *> *headers = @{kMSHeaderAppSecretKey : kMSTestAppSecret};
  NSURL *url = [NSURL new];

  // When
  [self.sut willSendHTTPRequestToURL:url withHeaders:headers];

  // Then
  OCMVerify([mockHttpUtil hideSecret:kMSTestAppSecret]);

  [mockLogger stopMocking];
  [mockHttpUtil stopMocking];
}

- (void)testSetBaseURL {

  // If
  NSString *path = @"path";
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", @"https://www.contoso.com/", path]];
  self.sut.apiPath = path;

  // Query should be the same.
  NSString *query = self.sut.sendURL.query;

  // When
  [self.sut setBaseURL:(NSString * _Nonnull)[url.URLByDeletingLastPathComponent absoluteString]];

  // Then
  XCTAssertNotNil(query);
  NSString *expectedURLString = [NSString stringWithFormat:@"%@?%@", url.absoluteString, query];
  XCTAssertTrue([[self.sut.sendURL absoluteString] isEqualToString:expectedURLString]);
}

- (void)testSetInvalidBaseURL {

  // If
  NSURL *expected = self.sut.sendURL;
  NSString *invalidURL = @"\notGood";

  // When
  [self.sut setBaseURL:invalidURL];

  // Then
  assertThat(self.sut.sendURL, is(expected));
}

- (void)testObfuscateResponsePayload {

  // If
  NSString *payload = @"I am the payload for testing";

  // When
  NSString *actual = [self.sut obfuscateResponsePayload:payload];

  // Then
  XCTAssertEqual(actual, payload);
}

@end
