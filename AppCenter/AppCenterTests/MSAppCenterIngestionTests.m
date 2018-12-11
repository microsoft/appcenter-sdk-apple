#import "AppCenter+Internal.h"
#import "MSAppCenterErrors.h"
#import "MSAppCenterIngestion.h"
#import "MSDevice.h"
#import "MSDeviceInternal.h"
#import "MSHttpIngestionPrivate.h"
#import "MSHttpTestUtil.h"
#import "MSIngestionCall.h"
#import "MSIngestionDelegate.h"
#import "MSMockLog.h"
#import "MSTestFrameworks.h"

static NSTimeInterval const kMSTestTimeout = 5.0;
static NSString *const kMSBaseUrl = @"https://test.com";
static NSString *const kMSTestAppSecret = @"TestAppSecret";

@interface MSAppCenterIngestionTests : XCTestCase

@property(nonatomic) MSAppCenterIngestion *sut;
@property(nonatomic) id reachabilityMock;
@property(nonatomic) NetworkStatus currentNetworkStatus;

@end

/*
 * TODO: Separate base MSHttpIngestion tests from this test and instantiate MSAppCenterIngestion with initWithBaseUrl:, not the one with
 * multiple parameters. Look at comments in each method. Add testHeaders to verify headers are populated properly. Look at testHeaders in
 * MSOneCollectorIngestionTests.
 */
@implementation MSAppCenterIngestionTests

- (void)setUp {
  [super setUp];

  NSDictionary *headers = @{ @"Content-Type" : @"application/json", @"App-Secret" : kMSTestAppSecret, @"Install-ID" : MS_UUID_STRING };

  NSDictionary *queryStrings = @{ @"api-version" : @"1.0.0" };

  // Mock reachability.
  self.reachabilityMock = OCMClassMock([MS_Reachability class]);
  self.currentNetworkStatus = ReachableViaWiFi;
  OCMStub([self.reachabilityMock currentReachabilityStatus]).andDo(^(NSInvocation *invocation) {
    NetworkStatus test = self.currentNetworkStatus;
    [invocation setReturnValue:&test];
  });

  // sut: System under test
  self.sut = [[MSAppCenterIngestion alloc] initWithBaseUrl:kMSBaseUrl
                                                   apiPath:@"/test-path"
                                                   headers:headers
                                              queryStrings:queryStrings
                                              reachability:self.reachabilityMock
                                            retryIntervals:@[ @(0.5), @(1), @(1.5) ]];
  [self.sut setAppSecret:kMSTestAppSecret];
}

- (void)tearDown {
  [super tearDown];

  [MSHttpTestUtil removeAllStubs];

  /*
   * Setting the variable to nil. We are experiencing test failure on Xcode 9 beta because the instance that was used for previous test
   * method is not disposed and still listening to network changes in other tests.
   */
  self.sut = nil;
}

- (void)testSendBatchLogs {

  // Stub http response
  [MSHttpTestUtil stubHttp200Response];
  NSString *containerId = @"1";
  MSLogContainer *container = [self createLogContainerWithId:containerId];
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP Response 200"];
  [self.sut sendAsync:container
      completionHandler:^(NSString *batchId, NSUInteger statusCode, __unused NSData *data, NSError *error) {

        XCTAssertNil(error);
        XCTAssertEqual(containerId, batchId);
        XCTAssertEqual((MSHTTPCodesNo)statusCode, MSHTTPCodesNo200OK);

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
- (void)testUnrecoverableError {

  // If
  [MSHttpTestUtil stubHttp404Response];
  NSString *containerId = @"1";
  MSLogContainer *container = [self createLogContainerWithId:containerId];
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP Response 200"];
  id delegateMock = OCMProtocolMock(@protocol(MSIngestionDelegate));
  [self.sut addDelegate:delegateMock];

  // When
  [self.sut sendAsync:container
      completionHandler:^(NSString *batchId, NSUInteger statusCode, __unused NSData *data, NSError *error) {

        // Then
        XCTAssertEqual(containerId, batchId);
        XCTAssertEqual((MSHTTPCodesNo)statusCode, MSHTTPCodesNo404NotFound);
        XCTAssertEqual(error.domain, kMSACErrorDomain);
        XCTAssertEqual(error.code, kMSACConnectionHttpErrorCode);
        XCTAssertEqual(error.localizedDescription, kMSACConnectionHttpErrorDesc);
        XCTAssertTrue([error.userInfo[(NSString *)kMSACConnectionHttpCodeErrorKey] isEqual:@(MSHTTPCodesNo404NotFound)]);

        /*
         * FIXME: This unit test failes intermittently because of timing issue.
         * Wait a little bit of time here so that [MSIngestionProtocol call:completedWithFatalError:] can be invoked right after this
         * completion handler.
         */
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
          [expectation fulfill];
        });
      }];

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *_Nullable error) {
                                 assertThatBool(self.sut.enabled, isFalse());
                                 OCMVerify([delegateMock ingestionDidReceiveFatalError:self.sut]);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

// TODO: Move this to base MSHttpIngestion test.
- (void)testNetworkDown {

  // If
  [MSHttpTestUtil stubNetworkDownResponse];
  XCTestExpectation *requestCompletedExcpectation = [self expectationWithDescription:@"Request completed."];
  NSString *containerId = @"1";
  MSLogContainer *container = [self createLogContainerWithId:containerId];

  // Mock the call to intercept the retry.
  NSArray *intervals = @[ @(0.5), @(1) ];
  MSIngestionCall *mockedCall = OCMPartialMock([[MSIngestionCall alloc] initWithRetryIntervals:intervals]);
  mockedCall.delegate = self.sut;
  mockedCall.data = container;
  mockedCall.callId = container.batchId;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
  mockedCall.completionHandler = nil;
#pragma clang diagnostic pop

  OCMStub([mockedCall ingestion:self.sut callCompletedWithStatus:0 data:OCMOCK_ANY error:OCMOCK_ANY])
    .andForwardToRealObject()
    .andDo(^(__unused NSInvocation *invocation) {
      [requestCompletedExcpectation fulfill];
    });
  self.sut.pendingCalls[containerId] = mockedCall;

  // When
  [self.sut sendCallAsync:mockedCall];

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {

                                 // The call must still be in the pending calls, intended to be retried later.
                                 assertThatUnsignedLong(self.sut.pendingCalls.count, equalToUnsignedLong(1));
                                 assertThatUnsignedLong(mockedCall.retryCount, equalToUnsignedLong(0));
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

// TODO: Move this to base MSHttpIngestion test.
- (void)testNetworkUpAgain {

  // If
  XCTestExpectation *requestCompletedExcpectation = [self expectationWithDescription:@"Request completed."];
  __block NSUInteger forwardedStatus;
  __block NSError *forwardedError;
  [MSHttpTestUtil stubHttp200Response];
  MSLogContainer *container = [self createLogContainerWithId:@"1"];

  // Set a delegate for pause/resume event.
  id delegateMock = OCMProtocolMock(@protocol(MSIngestionDelegate));
  [self.sut addDelegate:delegateMock];
  OCMStub([delegateMock ingestionDidPause:self.sut]).andDo(^(__unused NSInvocation *invocation) {

    // Send one batch now that the ingestion is paused.
    [self.sut sendAsync:container
        completionHandler:^(__unused NSString *batchId, NSUInteger statusCode, __unused NSData *data, NSError *error) {
          forwardedStatus = statusCode;
          forwardedError = error;
          [requestCompletedExcpectation fulfill];
        }];

    // When
    // Simulate network up again.
    [self simulateReachabilityChangedNotification:ReachableViaWiFi];
  });

  // Simulate network is down.
  [self simulateReachabilityChangedNotification:NotReachable];

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {

                                 // The ingestion got resumed.
                                 OCMVerify([delegateMock ingestionDidResume:self.sut]);
                                 assertThatBool(self.sut.paused, isFalse());

                                 // The call as been removed.
                                 assertThatUnsignedLong(self.sut.pendingCalls.count, equalToInt(0));

                                 // Status codes and error must be the same.
                                 assertThatLong(MSHTTPCodesNo200OK, equalToUnsignedInteger(forwardedStatus));
                                 assertThat(forwardedError, nilValue());
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

// TODO: Move this to base MSHttpIngestion test.
- (void)testPausedWhenAllRetriesUsed {

  // If
  XCTestExpectation *responseReceivedExcpectation = [self expectationWithDescription:@"Used all retries."];
  NSString *containerId = @"1";
  MSLogContainer *container = [self createLogContainerWithId:containerId];

  // Mock the call to intercept the retry.
  NSArray *intervals = @[ @(0.5), @(1) ];
  MSIngestionCall *mockedCall = OCMPartialMock([[MSIngestionCall alloc] initWithRetryIntervals:intervals]);
  mockedCall.delegate = self.sut;
  mockedCall.data = container;
  mockedCall.callId = container.batchId;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
  mockedCall.completionHandler = nil;
#pragma clang diagnostic pop

  OCMStub([mockedCall ingestion:self.sut callCompletedWithStatus:MSHTTPCodesNo500InternalServerError data:OCMOCK_ANY error:OCMOCK_ANY])
      .andForwardToRealObject()
      .andDo(^(__unused NSInvocation *invocation) {

        /*
         * Don't fulfill the expectation immediately as the ingestion won't be paused yet. Instead of using a delay to wait for the retries,
         * we use the retryCount as it retryCount will only be 0 before the first failed sending and after we've exhausted the retry
         * attempts. The first one won't be the case during unit tests as the request will fail immediately, so the expectation will only by
         * fulfilled once retries have been exhausted.
         */
        if (mockedCall.retryCount == 0) {
          [responseReceivedExcpectation fulfill];
        }
      });
  self.sut.pendingCalls[containerId] = mockedCall;

  // Respond with a retryable error.
  [MSHttpTestUtil stubHttp500Response];

  // Send the call.
  [self.sut sendCallAsync:mockedCall];
  [self waitForExpectationsWithTimeout:20
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
  XCTestExpectation *responseReceivedExcpectation = [self expectationWithDescription:@"Request completed."];
  NSString *containerId = @"1";
  MSLogContainer *container = [self createLogContainerWithId:containerId];

  // Mock the call to intercept the retry.
  MSIngestionCall *mockedCall = OCMPartialMock([[MSIngestionCall alloc] initWithRetryIntervals:@[ @(UINT_MAX) ]]);
  mockedCall.delegate = self.sut;
  mockedCall.data = container;
  mockedCall.callId = container.batchId;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
  mockedCall.completionHandler = nil;
#pragma clang diagnostic pop

  OCMStub([mockedCall ingestion:self.sut callCompletedWithStatus:MSHTTPCodesNo500InternalServerError data:OCMOCK_ANY error:OCMOCK_ANY])
      .andForwardToRealObject()
      .andDo(^(__unused NSInvocation *invocation) {
        [responseReceivedExcpectation fulfill];
      });
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
// 'dispatch_block_testcancel' is only available on macOS 10.10 or newer.
#if !TARGET_OS_OSX || __MAC_OS_X_VERSION_MAX_ALLOWED > 1090
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
                                 XCTAssertNotEqual(0, dispatch_testcancel(((MSIngestionCall *)self.sut.pendingCalls[@"1"]).timerSource));
#pragma clang diagnostic pop
#endif

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
      completionHandler:^(__unused NSString *batchId, __unused NSUInteger statusCode,
                          __unused NSData *data, NSError *error) {
        XCTAssertEqual(error.domain, kMSACErrorDomain);
        XCTAssertEqual(error.code, kMSACLogInvalidContainerErrorCode);
      }];

  XCTAssertEqual([self.sut.pendingCalls count], (unsigned long)0);
}

- (void)testNilContainer {

  MSLogContainer *container = nil;

  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP Network Down"];
  [self.sut sendAsync:container
      completionHandler:^(__unused NSString *batchId, __unused NSUInteger statusCode,
                          __unused NSData *data, NSError *error) {
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
  id deviceMock = OCMPartialMock([MSDevice new]);
  OCMStub([deviceMock isValid]).andReturn(YES);
  MSMockLog *log1 = [[MSMockLog alloc] init];
  log1.sid = @"";
  log1.timestamp = [NSDate date];
  MSLogContainer *logContainer = [[MSLogContainer alloc] initWithBatchId:@"whatever" andLogs:(NSArray<id<MSLog>> *)@[ log1 ]];
  NSString *jsonString = [logContainer serializeLog];
  NSData *httpBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];

  // When
  NSURLRequest *request = [self.sut createRequest:logContainer];

  // Then
  XCTAssertEqualObjects(request.HTTPBody, httpBody);

  // If

  // HTTP body is big enough to be compressed.
  log1.sid = [log1.sid stringByPaddingToLength:kMSHTTPMinGZipLength withString:@"." startingAtIndex:0];
  logContainer.logs = @[ log1 ];
  jsonString = [logContainer serializeLog];
  httpBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];

  // When
  request = [self.sut createRequest:logContainer];

  // Then
  XCTAssertTrue(request.HTTPBody.length < httpBody.length);
}

#pragma mark - Test Helpers

// TODO: Move this to base MSHttpIngestion test.
- (void)simulateReachabilityChangedNotification:(NetworkStatus)status {
  self.currentNetworkStatus = status;
  [[NSNotificationCenter defaultCenter] postNotificationName:kMSReachabilityChangedNotification object:self.reachabilityMock];
}

- (MSLogContainer *)createLogContainerWithId:(NSString *)batchId {

  id deviceMock = OCMPartialMock([MSDevice new]);
  OCMStub([deviceMock isValid]).andReturn(YES);

  MSMockLog *log1 = [[MSMockLog alloc] init];
  log1.sid = MS_UUID_STRING;
  log1.timestamp = [NSDate date];
  log1.device = deviceMock;

  MSMockLog *log2 = [[MSMockLog alloc] init];
  log2.sid = MS_UUID_STRING;
  log2.timestamp = [NSDate date];
  log2.device = deviceMock;

  MSLogContainer *logContainer = [[MSLogContainer alloc] initWithBatchId:batchId andLogs:(NSArray<id<MSLog>> *)@[ log1, log2 ]];
  return logContainer;
}

@end
