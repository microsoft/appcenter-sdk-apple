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
  MSLogContainer *container = [self createLogContainerWithId:containerId];
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

// TODO: Move this to base MSHttpIngestion test.
- (void)testAddDelegate {

  // If
  id delegateMock = OCMProtocolMock(@protocol(MSIngestionDelegate));

  // When
  [self.sut addDelegate:delegateMock];

  // Then
  assertThatBool([self.sut.delegates containsObject:delegateMock], isTrue());
}

// TODO: Move this to base MSHttpIngestion test.
- (void)testAddMultipleDelegates {

  // If
  id delegateMock1 = OCMProtocolMock(@protocol(MSIngestionDelegate));
  id delegateMock2 = OCMProtocolMock(@protocol(MSIngestionDelegate));

  // When
  [self.sut addDelegate:delegateMock1];
  [self.sut addDelegate:delegateMock2];

  // Then
  assertThatBool([self.sut.delegates containsObject:delegateMock1], isTrue());
  assertThatBool([self.sut.delegates containsObject:delegateMock2], isTrue());
}

// TODO: Move this to base MSHttpIngestion test.
- (void)testAddTwiceSameDelegate {

  // If
  id delegateMock = OCMProtocolMock(@protocol(MSIngestionDelegate));

  // When
  [self.sut addDelegate:delegateMock];
  [self.sut addDelegate:delegateMock];

  // Then
  assertThatBool([self.sut.delegates containsObject:delegateMock], isTrue());
  assertThatUnsignedLong(self.sut.delegates.count, equalToInt(1));
}

// TODO: Move this to base MSHttpIngestion test.
- (void)testRemoveDelegate {

  // If
  id delegateMock = OCMProtocolMock(@protocol(MSIngestionDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut removeDelegate:delegateMock];

  // Then
  assertThatBool([self.sut.delegates containsObject:delegateMock], isFalse());
}

// TODO: Move this to base MSHttpIngestion test.
- (void)testRemoveTwiceSameDelegate {

  // If
  id delegateMock1 = OCMProtocolMock(@protocol(MSIngestionDelegate));
  id delegateMock2 = OCMProtocolMock(@protocol(MSIngestionDelegate));
  [self.sut addDelegate:delegateMock1];
  [self.sut addDelegate:delegateMock2];

  // When
  [self.sut removeDelegate:delegateMock1];
  [self.sut removeDelegate:delegateMock1];

  // Then
  assertThatBool([self.sut.delegates containsObject:delegateMock1], isFalse());
  assertThatBool([self.sut.delegates containsObject:delegateMock2], isTrue());
  assertThatUnsignedLong(self.sut.delegates.count, equalToInt(1));
}

// TODO: Move this to base MSHttpIngestion test.
- (void)testNullifiedDelegate {

  // If
  @autoreleasepool {
    __weak id delegateMock = OCMProtocolMock(@protocol(MSIngestionDelegate));
    [self.sut addDelegate:delegateMock];

    // When
    delegateMock = nil;
  }

  // Then
  // There is a bug somehow in NSHashTable where the count on the table itself is not decremented while an object is deallocated and auto
  // removed from the table. The NSHashtable allObjects: is used instead to remediate.
  assertThatUnsignedLong(self.sut.delegates.allObjects.count, equalToInt(0));
}

// TODO: Move this to base MSHttpIngestion test.
- (void)testCallDelegatesOnPaused {

  // If
  id delegateMock1 = OCMProtocolMock(@protocol(MSIngestionDelegate));
  id delegateMock2 = OCMProtocolMock(@protocol(MSIngestionDelegate));
  [self.sut resume];
  [self.sut addDelegate:delegateMock1];
  [self.sut addDelegate:delegateMock2];

  // When
  [self.sut pause];

  // Then
  OCMVerify([delegateMock1 ingestionDidPause:self.sut]);
  OCMVerify([delegateMock2 ingestionDidPause:self.sut]);
}

// TODO: Move this to base MSHttpIngestion test.
- (void)testCallDelegatesOnResumed {

  // If
  id delegateMock1 = OCMProtocolMock(@protocol(MSIngestionDelegate));
  id delegateMock2 = OCMProtocolMock(@protocol(MSIngestionDelegate));
  [self.sut pause];
  [self.sut addDelegate:delegateMock1];
  [self.sut addDelegate:delegateMock2];

  // When
  [self.sut pause];
  [self.sut resume];

  // Then
  OCMVerify([delegateMock1 ingestionDidResume:self.sut]);
  OCMVerify([delegateMock2 ingestionDidResume:self.sut]);
}

- (void)testSetBaseURL {

  // If
  NSString *path = @"path";
  NSURL *expectedURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", @"https://www.contoso.com/", path]];
  self.sut.apiPath = path;

  // Query should be the same.
  NSString *query = self.sut.sendURL.query;

  // When
  [self.sut setBaseURL:(NSString * _Nonnull)[expectedURL.URLByDeletingLastPathComponent absoluteString]];

  // Then
  assertThat([self.sut.sendURL absoluteString], is([NSString stringWithFormat:@"%@?%@", expectedURL.absoluteString, query]));
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

- (void)testCompressHTTPBodyWhenNeeded {

  // If
  // HTTP body is too small, we don't compress.
  MSMockLog *log1 = [[MSMockLog alloc] init];
  log1.sid = @"";
  log1.timestamp = [NSDate date];
  MSLogContainer *logContainer = [[MSLogContainer alloc] initWithBatchId:@"whatever" andLogs:(NSArray<id<MSLog>> *)@[ log1 ]];
  NSString *jsonString = [logContainer serializeLog];
  NSData *httpBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];

  // When
  NSURLRequest *request = [self.sut createRequest:logContainer eTag:nil authToken:nil];

  // Then
  XCTAssertEqualObjects(request.HTTPBody, httpBody);

  // If
  // HTTP body is big enough to be compressed.
  log1.sid = [log1.sid stringByPaddingToLength:kMSHTTPMinGZipLength withString:@"." startingAtIndex:0];
  logContainer.logs = @[ log1 ];
  jsonString = [logContainer serializeLog];
  httpBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];

  // When
  request = [self.sut createRequest:logContainer eTag:nil authToken:nil];

  // Then
  XCTAssertTrue(request.HTTPBody.length < httpBody.length);
}

- (void)testSendsAuthHeaderWhenAuthTokenIsNotNil {

  // If
  NSString *token = @"auth token";
  MSLogContainer *logContainer = [[MSLogContainer alloc] initWithBatchId:@"whatever" andLogs:(NSArray<id<MSLog>> *)@ [[MSMockLog new]]];

  // When
  NSURLRequest *request = [self.sut createRequest:logContainer eTag:nil authToken:token];

  // Then
  NSString *expectedHeader = [NSString stringWithFormat:kMSBearerTokenHeaderFormat, token];
  NSString *actualHeader = request.allHTTPHeaderFields[kMSAuthorizationHeaderKey];
  XCTAssertEqualObjects(expectedHeader, actualHeader);
}

- (void)testDoesNotSendAuthHeaderWithNilAuthToken {

  // If
  MSLogContainer *logContainer = [[MSLogContainer alloc] initWithBatchId:@"whatever" andLogs:(NSArray<id<MSLog>> *)@ [[MSMockLog new]]];

  // When
  NSURLRequest *request = [self.sut createRequest:logContainer eTag:nil authToken:nil];

  // Then
  XCTAssertNil([request.allHTTPHeaderFields valueForKey:kMSAuthorizationHeaderKey]);
}

- (void)testDoesNotSendAuthHeaderWithEmptyAuthToken {

  // If
  MSLogContainer *logContainer = [[MSLogContainer alloc] initWithBatchId:@"whatever" andLogs:(NSArray<id<MSLog>> *)@ [[MSMockLog new]]];

  // When
  NSURLRequest *request = [self.sut createRequest:logContainer eTag:nil authToken:nil];

  // Then
  XCTAssertNil([request.allHTTPHeaderFields valueForKey:kMSAuthorizationHeaderKey]);
}

- (void)testObfuscateHeaderValue {

  // If
  NSString *testString = @"Bearer testtesttest";

  // When
  NSString *result = [self.sut obfuscateHeaderValue:testString forKey:kMSAuthorizationHeaderKey];

  // Then
  XCTAssertTrue([result isEqualToString:@"Bearer ***"]);
}

#pragma mark - Test Helpers

// TODO: Move this to base MSHttpIngestion test.
- (void)simulateReachabilityChangedNotification:(NetworkStatus)status {
  self.currentNetworkStatus = status;
  [[NSNotificationCenter defaultCenter] postNotificationName:kMSReachabilityChangedNotification object:self.reachabilityMock];
}

- (MSLogContainer *)createLogContainerWithId:(NSString *)batchId {
  MSMockLog *log1 = [[MSMockLog alloc] init];
  log1.sid = MS_UUID_STRING;
  log1.timestamp = [NSDate date];
  log1.device = self.deviceMock;

  MSMockLog *log2 = [[MSMockLog alloc] init];
  log2.sid = MS_UUID_STRING;
  log2.timestamp = [NSDate date];
  log2.device = self.deviceMock;

  MSLogContainer *logContainer = [[MSLogContainer alloc] initWithBatchId:batchId andLogs:(NSArray<id<MSLog>> *)@[ log1, log2 ]];
  return logContainer;
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
  MSLogContainer *container = [self createLogContainerWithId:@"1"];
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

@end
