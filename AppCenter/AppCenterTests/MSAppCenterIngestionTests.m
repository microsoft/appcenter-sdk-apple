// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "AppCenter+Internal.h"
#import "MSAppCenterErrors.h"
#import "MSAppCenterIngestion.h"
#import "MSDevice.h"
#import "MSDeviceInternal.h"
#import "MSHttpIngestionPrivate.h"
#import "MSHttpTestUtil.h"
#import "MSLoggerInternal.h"
#import "MSMockLog.h"
#import "MSTestFrameworks.h"
#import "MSUtility+StringFormatting.h"
#import "MSHttpClient.h"
#import "MSConstants+Internal.h"
#import "MSIngestionDelegate.h"
#import "MSTestUtil.h"

static NSTimeInterval const kMSTestTimeout = 5.0;
static NSString *const kMSBaseUrl = @"https://test.com";
static NSString *const kMSTestAppSecret = @"TestAppSecret";

@interface MSAppCenterIngestionTests : XCTestCase

@property(nonatomic) MSAppCenterIngestion *sut;
@property(nonatomic) id deviceMock;
@property(nonatomic) id reachabilityMock;
@property(nonatomic) NetworkStatus currentNetworkStatus;
@property(nonatomic) MSHttpClient *httpClientMock;

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
  [super tearDown];
  [self.deviceMock stopMocking];
  [self.reachabilityMock stopMocking];
  [MSHttpTestUtil removeAllStubs];

  /*
   * Setting the variable to nil. We are experiencing test failure on Xcode 9 beta because the instance that was used for previous test
   * method is not disposed and still listening to network changes in other tests.
   */
  [MS_NOTIFICATION_CENTER removeObserver:self.sut name:kMSReachabilityChangedNotification object:nil];
  self.sut = nil;
}

- (void)testSendBatchLogs {

  // Stub http response
  [MSHttpTestUtil stubHttp200Response];
  NSString *containerId = @"1";
  MSLogContainer *container = [MSTestUtil createLogContainerWithId:containerId device:self.deviceMock];
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP Response 200"];
  [self.sut sendAsync:container
              authToken:nil
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


//TODO Should HTTP ingestion have its own pause state? What happens when all retries are used for a request? should that pause the http client used everywhere? Or should the channel for that module observe that all retries are used and then pause it manually? or should ingestion pause itself when that happens for one of its calls but not expose the pause state at that level?



// TODO: Move this to base MSHttpIngestion test.
- (void)testPausedWhenAllRetriesUsed {

  // If
  XCTestExpectation *responseReceivedExpectation = [self expectationWithDescription:@"Used all retries."];
  responseReceivedExpectation.expectedFulfillmentCount = 3;
  NSString *containerId = @"1";
  MSLogContainer *container = [self createLogContainerWithId:containerId];

  // Mock the call to intercept the retry.
  NSArray *intervals = @[ @(0.5), @(1) ];
  MSIngestionCall *mockedCall = [[MSIngestionCallExpectation alloc] initWithRetryIntervals:intervals
                                                                            andExpectation:responseReceivedExpectation];
  mockedCall.delegate = self.sut;
  mockedCall.data = container;
  mockedCall.callId = container.batchId;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
  mockedCall.completionHandler = nil;
#pragma clang diagnostic pop

  self.sut.pendingCalls[containerId] = mockedCall;

  // Respond with a retryable error.
  [MSHttpTestUtil stubHttp500Response];

  // Send the call.
  [self.sut sendCallAsync:mockedCall];
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 XCTAssertTrue(self.sut.paused);
                                 XCTAssertTrue([self.sut.pendingCalls count] == 0);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

// TODO: Move this to base MSHttpIngestion test.
- (void)testRetryStoppedWhilePaused {

  // If
  XCTestExpectation *responseReceivedExpectation = [self expectationWithDescription:@"Request completed."];
  NSString *containerId = @"1";
  MSLogContainer *container = [self createLogContainerWithId:containerId];

  // Mock the call to intercept the retry.
  NSArray *intervals = @[ @(UINT_MAX) ];
  MSIngestionCall *mockedCall = [[MSIngestionCallExpectation alloc] initWithRetryIntervals:intervals
                                                                            andExpectation:responseReceivedExpectation];
  mockedCall.delegate = self.sut;
  mockedCall.data = container;
  mockedCall.callId = container.batchId;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
  mockedCall.completionHandler = nil;
#pragma clang diagnostic pop

  self.sut.pendingCalls[containerId] = mockedCall;

  // Respond with a retryable error.
  [MSHttpTestUtil stubHttp500Response];

  // Send the call.
  [self.sut sendCallAsync:mockedCall];
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 // When
                                 // Pause now that the call is retrying.
                                 [self.sut pause];

                                 // Then
                                 // Retry must be stopped.
                                 if (@available(macOS 10.10, tvOS 9.0, watchOS 2.0, *)) {
                                   XCTAssertNotEqual(0, dispatch_testcancel(((MSIngestionCall *)self.sut.pendingCalls[@"1"]).timerSource));
                                 }

                                 // No call submitted to the session.
                                 assertThatBool(self.sut.pendingCalls[@"1"].submitted, isFalse());
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testInvalidContainer {

  MSAbstractLog *log = [MSAbstractLog new];
  log.sid = MS_UUID_STRING;
  log.timestamp = [NSDate date];

  // Log does not have device info, therefore, it's an invalid log
  MSLogContainer *container = [[MSLogContainer alloc] initWithBatchId:@"1" andLogs:(NSArray<id<MSLog>> *)@[ log ]];

  // Then
  OCMReject([self.httpClientMock sendAsync:OCMOCK_ANY method:OCMOCK_ANY headers:OCMOCK_ANY data:OCMOCK_ANY retryIntervals:OCMOCK_ANY compressionEnabled:OCMOCK_ANY completionHandler:OCMOCK_ANY]);

  // When
  [self.sut sendAsync:container
              authToken:nil
      completionHandler:^(__unused NSString *batchId, __unused NSHTTPURLResponse *response, __unused NSData *data, NSError *error) {
        XCTAssertEqual(error.domain, kMSACErrorDomain);
        XCTAssertEqual(error.code, MSACLogInvalidContainerErrorCode);
      }];

  XCTAssertEqual([self.sut.pendingCalls count], (unsigned long)0);
}

- (void)testNilContainer {

  MSLogContainer *container = nil;

  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP Network Down"];
  [self.sut sendAsync:container
              authToken:nil
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

- (void)testSendsAuthHeaderWhenAuthTokenIsNotNil {

  // If
  NSString *token = @"auth token";
  MSLogContainer *logContainer = OCMPartialMock([MSLogContainer new]);
  OCMStub([logContainer isValid]).andReturn(YES);

  // When
  [self.sut sendAsync:logContainer authToken:token completionHandler:^(NSString * _Nonnull callId __unused, NSHTTPURLResponse * _Nullable response __unused, NSData * _Nullable data __unused, NSError * _Nullable error __unused) {
  }];

  // Then
  OCMVerify(([self.httpClientMock sendAsync:OCMOCK_ANY method:OCMOCK_ANY headers:[OCMArg checkWithBlock:^BOOL(id obj) {
    NSDictionary *headers = (NSDictionary *)obj;
    NSString *actualHeader = headers[@"Authorization"];
    NSString *expectedHeader = [NSString stringWithFormat:@"Bearer %@", token];
    return [expectedHeader isEqualToString:actualHeader];
  }] data:OCMOCK_ANY retryIntervals:OCMOCK_ANY compressionEnabled:OCMOCK_ANY completionHandler:OCMOCK_ANY]));
}

- (void)testDoesNotSendAuthHeaderWithNilAuthToken {

  // If
  MSLogContainer *logContainer = [[MSLogContainer alloc] initWithBatchId:@"whatever" andLogs:(NSArray<id<MSLog>> *)@ [[MSMockLog new]]];

  // When
  [self.sut sendAsync:logContainer completionHandler:^(NSString * _Nonnull callId __unused, NSHTTPURLResponse * _Nullable response __unused, NSData * _Nullable data __unused, NSError * _Nullable error __unused) {
  }];

  // Then
  OCMVerify(([self.httpClientMock sendAsync:OCMOCK_ANY method:OCMOCK_ANY headers:[OCMArg checkWithBlock:^BOOL(id obj) {
    NSDictionary *headers = (NSDictionary *)obj;
    return headers[@"Authorization"] == nil;
  }] data:OCMOCK_ANY retryIntervals:OCMOCK_ANY compressionEnabled:OCMOCK_ANY completionHandler:OCMOCK_ANY]));
}

- (void)testObfuscateHeaderValue {

  // If
  NSString *testString = @"Bearer testtesttest";

  // When
  NSString *result = [self.sut obfuscateHeaderValue:testString forKey:kMSAuthorizationHeaderKey];

  // Then
  XCTAssertTrue([result isEqualToString:@"Bearer ***"]);
}

- (void)testHideSecretInResponse {

  // If
  id mockUtility = OCMClassMock([MSUtility class]);
  id mockLogger = OCMClassMock([MSLogger class]);
  OCMStub([mockLogger currentLogLevel]).andReturn(MSLogLevelVerbose);
  OCMStub(ClassMethod([mockUtility obfuscateString:OCMOCK_ANY
                               searchingForPattern:kMSRedirectUriPattern
                             toReplaceWithTemplate:kMSRedirectUriObfuscatedTemplate]));
  NSData *data = [[NSString stringWithFormat:@"{\"redirect_uri\":\"%@\",\"token\":\"%@\"}", kMSTestAppSecret, kMSTestAppSecret]
      dataUsingEncoding:NSUTF8StringEncoding];
  MSLogContainer *container = [MSTestUtil createLogContainerWithId:@"1" device:self.deviceMock];
  XCTestExpectation *requestCompletedExpectation = [self expectationWithDescription:@"Request completed."];

  // When
  [MSHttpTestUtil stubResponseWithData:data statusCode:MSHTTPCodesNo200OK headers:self.sut.httpHeaders name:NSStringFromSelector(_cmd)];
  [self.sut sendAsync:container
              authToken:nil
      completionHandler:^(__unused NSString *batchId, __unused NSHTTPURLResponse *response, __unused NSData *responseData,
                          __unused NSError *error) {
        [requestCompletedExpectation fulfill];
      }];

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 OCMVerify(ClassMethod([mockUtility obfuscateString:OCMOCK_ANY
                                                                searchingForPattern:kMSRedirectUriPattern
                                                              toReplaceWithTemplate:kMSRedirectUriObfuscatedTemplate]));
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  // Clear
  [mockUtility stopMocking];
  [mockLogger stopMocking];
}

#pragma mark - Test Helpers

// TODO: Move this to base MSHttpIngestion test.
- (void)simulateReachabilityChangedNotification:(NetworkStatus)status {
  self.currentNetworkStatus = status;
  [[NSNotificationCenter defaultCenter] postNotificationName:kMSReachabilityChangedNotification object:self.reachabilityMock];
}

@end
