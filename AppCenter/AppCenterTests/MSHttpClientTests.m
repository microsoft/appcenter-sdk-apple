// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "AppCenter+Internal.h"
#import "MSAppCenterErrors.h"
#import "MSDevice.h"
#import "MSDeviceInternal.h"
#import "MSHttpClient.h"
#import "MSHttpIngestionPrivate.h"
#import "MSHttpTestUtil.h"
#import "MSIngestionCall.h"
#import "MSIngestionDelegate.h"
#import "MSMockLog.h"
#import "MSTestFrameworks.h"
#import <OHHTTPStubs/NSURLRequest+HTTPBodyTesting.h>
#import <OHHTTPStubs/OHHTTPStubs.h>

static NSTimeInterval const kMSTestTimeout = 5.0;

@interface MSHttpClientTests : XCTestCase

@property(nonatomic) MSHttpClient *sut;
@property(nonatomic) id reachabilityMock;
@property(nonatomic) NetworkStatus currentNetworkStatus;

@end

@interface MSHttpClient ()

- (instancetype)initWithMaxHttpConnectionsPerHost:(NSNumber *)maxHttpConnectionsPerHost
                                   retryIntervals:(NSArray *)retryIntervals
                                     reachability:(MS_Reachability *)reachability;

@end

@implementation MSHttpClientTests

- (void)setUp {
  [super setUp];

  // Mock reachability.
  self.reachabilityMock = OCMClassMock([MS_Reachability class]);
  self.currentNetworkStatus = ReachableViaWiFi;
  OCMStub([self.reachabilityMock currentReachabilityStatus]).andDo(^(NSInvocation *invocation) {
    NetworkStatus test = self.currentNetworkStatus;
    [invocation setReturnValue:&test];
  });
}

- (void)tearDown {
  [super tearDown];

  [MSHttpTestUtil removeAllStubs];
  [self.reachabilityMock stopMocking];

  /*
   * Setting the variable to nil. We are experiencing test failure on Xcode 9 beta because the instance that was used for previous test
   * method is not disposed and still listening to network changes in other tests.
   */
  self.sut = nil;
}

- (void)testPostSuccessWithoutHeaders {

  // If
  __block NSURLRequest *actualRequest;

  // Stub HTTP response.
  [OHHTTPStubs
      stubRequestsPassingTest:^BOOL(__unused NSURLRequest *request) {
        return YES;
      }
      withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        actualRequest = request;
        NSData *responsePayload = [@"OK" dataUsingEncoding:kCFStringEncodingUTF8];
        return [OHHTTPStubsResponse responseWithData:responsePayload statusCode:MSHTTPCodesNo200OK headers:nil];
      }];
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP Response 200"];
  self.sut = [MSHttpClient new];
  NSURL *url = [NSURL URLWithString:@"https://mock/something?a=b"];
  NSString *method = @"POST";
  NSData *payload = [@"somePayload" dataUsingEncoding:kCFStringEncodingUTF8];

  // When
  [self.sut sendAsync:url
                 method:method
                headers:nil
                   data:payload
      completionHandler:^(NSData *responseBody, NSHTTPURLResponse *response, NSError *error) {
        // Then
        XCTAssertEqual(response.statusCode, MSHTTPCodesNo200OK);
        XCTAssertEqualObjects(responseBody, [@"OK" dataUsingEncoding:kCFStringEncodingUTF8]);
        XCTAssertNil(error);
        [expectation fulfill];
      }];
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
  XCTAssertEqualObjects(actualRequest.URL, url);
  XCTAssertEqualObjects(actualRequest.HTTPMethod, method);
  XCTAssertEqualObjects(actualRequest.OHHTTPStubs_HTTPBody, payload);
}

- (void)testGetWithHeadersResultInFatalNSError {

  // If
  __block NSURLRequest *actualRequest;

  // Stub HTTP response.
  [OHHTTPStubs
      stubRequestsPassingTest:^BOOL(__unused NSURLRequest *request) {
        return YES;
      }
      withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        actualRequest = request;
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorBadURL userInfo:nil];
        return [OHHTTPStubsResponse responseWithError:error];
      }];
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Network error"];
  self.sut = [MSHttpClient new];
  NSURL *url = [NSURL URLWithString:@"https://mock/something?a=b"];
  NSString *method = @"GET";
  NSDictionary *headers = @{@"Authorization" : @"something"};

  // When
  [self.sut sendAsync:url
                 method:method
                headers:headers
                   data:nil
      completionHandler:^(NSData *responseBody, NSHTTPURLResponse *response, NSError *error) {
        // Then
        XCTAssertNil(response);
        XCTAssertNil(responseBody);
        XCTAssertNotNil(error);
        [expectation fulfill];
      }];
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  // Then
  XCTAssertEqualObjects(actualRequest.URL, url);
  XCTAssertEqualObjects(actualRequest.HTTPMethod, method);
  XCTAssertEqualObjects(actualRequest.allHTTPHeaderFields[@"Authorization"], @"something");
}

- (void)testDeleteUnrecoverableErrorWithoutHeadersNotRetried {

  // If
  __block int numRequests = 0;
  __block NSURLRequest *actualRequest;
  [OHHTTPStubs
      stubRequestsPassingTest:^BOOL(__unused NSURLRequest *request) {
        return YES;
      }
      withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        ++numRequests;
        actualRequest = request;
        return [OHHTTPStubsResponse responseWithData:[NSData data] statusCode:MSHTTPCodesNo400BadRequest headers:nil];
      }];
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@""];
  self.sut = [MSHttpClient new];
  NSURL *url = [NSURL URLWithString:@"https://mock/something?a=b"];
  NSString *method = @"DELETE";

  // When
  [self.sut sendAsync:url
                 method:method
                headers:nil
                   data:nil
      completionHandler:^(NSData *responseBody, NSHTTPURLResponse *response, NSError *error) {
        // Then
        XCTAssertEqual(response.statusCode, MSHTTPCodesNo400BadRequest);
        XCTAssertNotNil(responseBody);
        XCTAssertNil(error);
        [expectation fulfill];
      }];

  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
  // Then
  XCTAssertEqualObjects(actualRequest.URL, url);
  XCTAssertEqualObjects(actualRequest.HTTPMethod, method);
  XCTAssertEqual(numRequests, 1);
}

- (void)testRecoverableNSErrorRetriedWhenNetworkReturns {

  // If
  __block BOOL completionHandlerCalled = NO;
  __block BOOL firstTime = YES;
  __block NSURLRequest *actualRequest;
  NSArray *retryIntervals = @[ @1, @2 ];
  [OHHTTPStubs
      stubRequestsPassingTest:^BOOL(__unused NSURLRequest *request) {
        return YES;
      }
      withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        actualRequest = request;
        if (firstTime) {
          firstTime = NO;
          NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotLoadFromNetwork userInfo:nil];
          return [OHHTTPStubsResponse responseWithError:error];
        }
        return [OHHTTPStubsResponse responseWithData:[NSData data] statusCode:MSHTTPCodesNo204NoContent headers:nil];
      }];
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@""];
  self.sut = [[MSHttpClient alloc] initWithMaxHttpConnectionsPerHost:nil retryIntervals:retryIntervals reachability:self.reachabilityMock];
  NSURL *url = [NSURL URLWithString:@"https://mock/something?a=b"];
  NSString *method = @"DELETE";

  // When
  [self.sut sendAsync:url
                 method:method
                headers:nil
                   data:nil
      completionHandler:^(__unused NSData *responseBody, __unused NSHTTPURLResponse *response, __unused NSError *error) {
        completionHandlerCalled = YES;
        [expectation fulfill];
      }];

  // Wait a little to ensure that the completion handler is not invoked yet.
  sleep(1);

  // Then
  XCTAssertFalse(completionHandlerCalled);

  // Restore the network and wait for completion handler to be called.
  [self simulateReachabilityChangedNotification:ReachableViaWiFi];

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testNetworkDownAndThenUpAgain {

  // If
  __block int numRequests = 0;
  __block NSURLRequest *actualRequest;
  __block BOOL completionHandlerCalled = NO;
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@""];
  [OHHTTPStubs
      stubRequestsPassingTest:^BOOL(__unused NSURLRequest *request) {
        return YES;
      }
      withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        ++numRequests;
        actualRequest = request;
        return [OHHTTPStubsResponse responseWithData:[NSData data] statusCode:MSHTTPCodesNo204NoContent headers:nil];
      }];
  self.sut = [[MSHttpClient alloc] initWithMaxHttpConnectionsPerHost:nil retryIntervals:@[ @1 ] reachability:self.reachabilityMock];
  NSURL *url = [NSURL URLWithString:@"https://mock/something?a=b"];
  NSString *method = @"DELETE";

  // When
  [self simulateReachabilityChangedNotification:NotReachable];
  [self.sut sendAsync:url
                 method:method
                headers:nil
                   data:nil
      completionHandler:^(NSData *responseBody, NSHTTPURLResponse *response, NSError *error) {
        // Then
        XCTAssertEqual(response.statusCode, MSHTTPCodesNo204NoContent);
        XCTAssertEqualObjects(responseBody, [NSData data]);
        XCTAssertNil(error);
        completionHandlerCalled = YES;
        [expectation fulfill];
      }];

  // Wait a while to make sure that the requests are not sent while the network is down.
  sleep(1);
  XCTAssertFalse(completionHandlerCalled);
  XCTAssertEqual(numRequests, 0);

  // When
  [self simulateReachabilityChangedNotification:ReachableViaWiFi];
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }

                                 // Then
                                 XCTAssertEqualObjects(actualRequest.URL, url);
                                 XCTAssertEqualObjects(actualRequest.HTTPMethod, method);
                                 XCTAssertEqual(numRequests, 1);
                               }];
}

- (void)testDeleteRecoverableErrorWithoutHeadersRetried {

  // If
  __block int numRequests = 0;
  __block NSURLRequest *actualRequest;
  NSArray *retryIntervals = @[ @1, @2 ];
  [OHHTTPStubs
      stubRequestsPassingTest:^BOOL(__unused NSURLRequest *request) {
        return YES;
      }
      withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        actualRequest = request;
        ++numRequests;
        return [OHHTTPStubsResponse responseWithData:[NSData data] statusCode:MSHTTPCodesNo500InternalServerError headers:nil];
      }];
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@""];
  self.sut = [[MSHttpClient alloc] initWithMaxHttpConnectionsPerHost:nil retryIntervals:retryIntervals reachability:self.reachabilityMock];
  NSURL *url = [NSURL URLWithString:@"https://mock/something?a=b"];
  NSString *method = @"DELETE";

  // When
  [self.sut sendAsync:url
                 method:method
                headers:nil
                   data:nil
      completionHandler:^(NSData *responseBody, NSHTTPURLResponse *response, NSError *error) {
        // Then
        XCTAssertEqual(response.statusCode, MSHTTPCodesNo500InternalServerError);
        XCTAssertNotNil(responseBody);
        XCTAssertNil(error);
        [expectation fulfill];
      }];

  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  // Then
  XCTAssertEqualObjects(actualRequest.URL, url);
  XCTAssertEqualObjects(actualRequest.HTTPMethod, method);
  XCTAssertEqual(numRequests, 1 + [retryIntervals count]);
}

- (void)testPauseThenResumeDoesNotResendCalls {

  // Scenario is pausing the client while there is a call that is being sent but hasn't completed yet, and then calling resume.

  // If
  __block int numRequests = 0;
  dispatch_semaphore_t responseSemaphore = dispatch_semaphore_create(0);
  dispatch_semaphore_t pauseSemaphore = dispatch_semaphore_create(0);
  [OHHTTPStubs
      stubRequestsPassingTest:^BOOL(__unused NSURLRequest *request) {
        return YES;
      }
      withStubResponse:^OHHTTPStubsResponse *(__unused NSURLRequest *request) {
        ++numRequests;

        // Use this semaphore to prevent the pause from occurring before the call is enqueued.
        dispatch_semaphore_signal(responseSemaphore);

        // Don't let the request finish before pausing.
        dispatch_semaphore_wait(pauseSemaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMSTestTimeout * NSEC_PER_SEC)));
        return [OHHTTPStubsResponse responseWithData:[NSData data] statusCode:MSHTTPCodesNo204NoContent headers:nil];
      }];
  self.sut = [[MSHttpClient alloc] initWithMaxHttpConnectionsPerHost:nil retryIntervals:@[] reachability:self.reachabilityMock];
  NSURL *url = [NSURL URLWithString:@"https://mock/something?a=b"];
  NSString *method = @"DELETE";

  // When
  [self.sut sendAsync:url
                 method:method
                headers:nil
                   data:nil
      completionHandler:^(__unused NSData *responseBody, __unused NSHTTPURLResponse *response, __unused NSError *error){
      }];

  // Don't pause until the call has been enqueued.
  dispatch_semaphore_wait(responseSemaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMSTestTimeout * NSEC_PER_SEC)));
  [self simulateReachabilityChangedNotification:NotReachable];
  dispatch_semaphore_signal(pauseSemaphore);
  [self simulateReachabilityChangedNotification:ReachableViaWiFi];

  // Wait a while to make sure that the request is not sent after resuming.
  sleep(1);

  // Then
  XCTAssertEqual(numRequests, 1);
}

- (void)testDisablingCancelsCalls {

  // If
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@""];
  dispatch_semaphore_t responseSemaphore = dispatch_semaphore_create(0);
  dispatch_semaphore_t testCompletedSemaphore = dispatch_semaphore_create(0);
  [OHHTTPStubs
      stubRequestsPassingTest:^BOOL(__unused NSURLRequest *request) {
        return YES;
      }
      withStubResponse:^OHHTTPStubsResponse *(__unused NSURLRequest *request) {
        dispatch_semaphore_signal(responseSemaphore);

        // Sleep to ensure that the call is really canceled instead of waiting for the response.
        dispatch_semaphore_wait(testCompletedSemaphore, DISPATCH_TIME_FOREVER);
        return [OHHTTPStubsResponse responseWithData:[NSData data] statusCode:MSHTTPCodesNo204NoContent headers:nil];
      }];
  self.sut = [[MSHttpClient alloc] initWithMaxHttpConnectionsPerHost:nil retryIntervals:@[ @1 ] reachability:self.reachabilityMock];
  NSURL *url = [NSURL URLWithString:@"https://mock/something?a=b"];
  NSString *method = @"DELETE";

  // When
  [self.sut sendAsync:url
                 method:method
                headers:nil
                   data:nil
      completionHandler:^(NSData *responseBody, NSHTTPURLResponse *response, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(response);
        XCTAssertNil(responseBody);
        [expectation fulfill];
      }];

  // Don't disable until the call has been enqueued.
  dispatch_semaphore_wait(responseSemaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMSTestTimeout * NSEC_PER_SEC)));
  [self.sut setEnabled:NO];

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  // Clean up.
  dispatch_semaphore_signal(testCompletedSemaphore);
}

- (void)testDisableThenEnable {

  // If
  __block NSURLRequest *actualRequest;

  // Stub HTTP response.
  [OHHTTPStubs
      stubRequestsPassingTest:^BOOL(__unused NSURLRequest *request) {
        return YES;
      }
      withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        actualRequest = request;
        NSData *responsePayload = [@"OK" dataUsingEncoding:kCFStringEncodingUTF8];
        return [OHHTTPStubsResponse responseWithData:responsePayload statusCode:MSHTTPCodesNo200OK headers:nil];
      }];
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP Response 200"];
  self.sut = [MSHttpClient new];
  NSURL *url = [NSURL URLWithString:@"https://mock/something?a=b"];
  NSString *method = @"POST";
  NSData *payload = [@"somePayload" dataUsingEncoding:kCFStringEncodingUTF8];

  // When
  [self.sut setEnabled:NO];
  [self.sut setEnabled:YES];
  [self.sut sendAsync:url
                 method:method
                headers:nil
                   data:payload
      completionHandler:^(NSData *responseBody, NSHTTPURLResponse *response, NSError *error) {
        // Then
        XCTAssertEqual(response.statusCode, MSHTTPCodesNo200OK);
        XCTAssertEqualObjects(responseBody, [@"OK" dataUsingEncoding:kCFStringEncodingUTF8]);
        XCTAssertNil(error);
        [expectation fulfill];
      }];
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
  XCTAssertEqualObjects(actualRequest.URL, url);
  XCTAssertEqualObjects(actualRequest.HTTPMethod, method);
  XCTAssertEqualObjects(actualRequest.OHHTTPStubs_HTTPBody, payload);
}

- (void)testRetryHeaderInResponse {

  // If
  __block int numRequests = 0;
  __block NSURLRequest *actualRequest;
  NSArray *retryIntervals = @[ @1000000000, @100000000 ];
  [OHHTTPStubs
      stubRequestsPassingTest:^BOOL(__unused NSURLRequest *request) {
        return YES;
      }
      withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        actualRequest = request;
        ++numRequests;
        if (numRequests < 3) {
          return [OHHTTPStubsResponse responseWithData:[NSData data]
                                            statusCode:MSHTTPCodesNo429TooManyRequests
                                               headers:@{@"x-ms-retry-after-ms" : @"100"}];
        }
        return [OHHTTPStubsResponse responseWithData:[NSData data] statusCode:MSHTTPCodesNo204NoContent headers:nil];
      }];
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@""];
  self.sut = [[MSHttpClient alloc] initWithMaxHttpConnectionsPerHost:nil retryIntervals:retryIntervals reachability:self.reachabilityMock];
  NSURL *url = [NSURL URLWithString:@"https://mock/something?a=b"];
  NSString *method = @"DELETE";

  // When
  [self.sut sendAsync:url
                 method:method
                headers:nil
                   data:nil
      completionHandler:^(NSData *responseBody, NSHTTPURLResponse *response, NSError *error) {
        // Then
        XCTAssertEqual(response.statusCode, MSHTTPCodesNo204NoContent);
        XCTAssertNotNil(responseBody);
        XCTAssertNil(error);
        [expectation fulfill];
      }];

  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  // Then
  XCTAssertEqualObjects(actualRequest.URL, url);
  XCTAssertEqualObjects(actualRequest.HTTPMethod, method);
  XCTAssertEqual(numRequests, 1 + [retryIntervals count]);
}

- (void)simulateReachabilityChangedNotification:(NetworkStatus)status {
  self.currentNetworkStatus = status;
  [[NSNotificationCenter defaultCenter] postNotificationName:kMSReachabilityChangedNotification object:self.reachabilityMock];
}

@end
