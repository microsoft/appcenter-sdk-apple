// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "AppCenter+Internal.h"
#import "MSAppCenterErrors.h"
#import "MSHttpClient.h"
#import "MSDevice.h"
#import "MSDeviceInternal.h"
#import "MSHttpIngestionPrivate.h"
#import "MSHttpTestUtil.h"
#import "MSIngestionCall.h"
#import "MSIngestionDelegate.h"
#import "MSMockLog.h"
#import "MSTestFrameworks.h"
#import <OHHTTPStubs/OHHTTPStubs.h>

static NSTimeInterval const kMSTestTimeout = 5.0;

@interface MSHttpClientTests : XCTestCase

@property(nonatomic) MSHttpClient *sut;
@property(nonatomic) id reachabilityMock;
@property(nonatomic) NetworkStatus currentNetworkStatus;

@end

@interface MSHttpClient ()

- (instancetype)initWithRetryIntervals:(NSArray *)retryIntervals;

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
   stubRequestsPassingTest:^BOOL(__attribute__((unused)) NSURLRequest *request) {
     actualRequest = request;
     return YES;
   }
   withStubResponse:^OHHTTPStubsResponse *(__attribute__((unused)) NSURLRequest *request) {
     NSData *responsePayload = [@"OK" dataUsingEncoding:kCFStringEncodingUTF8];
     return [OHHTTPStubsResponse responseWithData:responsePayload statusCode:MSHTTPCodesNo200OK headers:nil];
   }];
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP Response 200"];
  self.sut = [MSHttpClient new];
  NSURL *url = [NSURL URLWithString:@"https://mock/something?a=b"];
  NSString *method = @"POST";
  NSDictionary *headers = nil;
  NSData *payload = [@"somePayload" dataUsingEncoding:kCFStringEncodingUTF8];

  // When
  [self.sut sendAsync:url
               method:method
              headers:headers
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

  // Then
  XCTAssertEqualObjects(actualRequest.URL, url);
  XCTAssertEqualObjects(actualRequest.HTTPMethod, method);
  XCTAssertEqualObjects(actualRequest.allHTTPHeaderFields, headers);
  XCTAssertEqualObjects(actualRequest.HTTPBody, payload);
}

- (void)testGetWithHeadersWhileNetworkIsNotConnected {

  // If
  __block NSURLRequest *actualRequest;

  // Stub HTTP response.
  [OHHTTPStubs
   stubRequestsPassingTest:^BOOL(__attribute__((unused)) NSURLRequest *request) {
     actualRequest = request;
     return YES;
   }
   withStubResponse:^OHHTTPStubsResponse *(__attribute__((unused)) NSURLRequest *request) {
     NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil];
     return [OHHTTPStubsResponse responseWithError:error];
   }];
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Network error"];
  self.sut = [MSHttpClient new];
  NSURL *url = [NSURL URLWithString:@"https://mock/something?a=b"];
  NSString *method = @"GET";
  NSDictionary *headers = @{ @"Authorization" : @"something", @"Content-Length": @"0" };
  NSData *payload = nil;

  // When
  [self.sut sendAsync:url
               method:method
              headers:headers
                 data:payload
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
  XCTAssertEqualObjects(actualRequest.allHTTPHeaderFields, headers);
  XCTAssertEqualObjects(actualRequest.HTTPBody, payload);
}

- (void)testDeleteUnrecoverableErrorWithoutHeadersNotRetried {

  // If
  // Stub HTTP response.
  __block int numRequests = 0;
  __block NSURLRequest *actualRequest;
  [OHHTTPStubs
   stubRequestsPassingTest:^BOOL(__attribute__((unused)) NSURLRequest *request) {
     ++numRequests;
     actualRequest = request;
     return YES;
   }
   withStubResponse:^OHHTTPStubsResponse *(__attribute__((unused)) NSURLRequest *request) {
     return [OHHTTPStubsResponse responseWithData:[NSData data] statusCode:MSHTTPCodesNo400BadRequest headers:nil];
   }];
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@""];
  self.sut = [MSHttpClient new];
  NSURL *url = [NSURL URLWithString:@"https://mock/something?a=b"];
  NSString *method = @"DELETE";
  NSDictionary *headers = nil;
  NSData *payload = nil;

  // When
  [self.sut sendAsync:url
               method:method
              headers:headers
                 data:payload
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
  XCTAssertEqualObjects(actualRequest.allHTTPHeaderFields, headers);
  XCTAssertEqualObjects(actualRequest.HTTPBody, payload);
  XCTAssertEqual(numRequests, 1);
}

- (void)testDeleteRecoverableErrorWithoutHeadersRetried {

  // If
  // Stub HTTP response.
  __block int numRequests = 0;
  __block NSURLRequest *actualRequest;
  NSArray *retryIntervals = @[@0.1, @0.2];
  [OHHTTPStubs
   stubRequestsPassingTest:^BOOL(__attribute__((unused)) NSURLRequest *request) {
     ++numRequests;
     actualRequest = request;
     return YES;
   }
   withStubResponse:^OHHTTPStubsResponse *(__attribute__((unused)) NSURLRequest *request) {
     return [OHHTTPStubsResponse responseWithData:[NSData data] statusCode:MSHTTPCodesNo500InternalServerError headers:nil];
   }];
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@""];
  self.sut = [[MSHttpClient alloc] initWithRetryIntervals:retryIntervals];
  NSURL *url = [NSURL URLWithString:@"https://mock/something?a=b"];
  NSString *method = @"DELETE";
  NSDictionary *headers = nil;
  NSData *payload = nil;

  // When
  [self.sut sendAsync:url
               method:method
              headers:headers
                 data:payload
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
  XCTAssertEqualObjects(actualRequest.allHTTPHeaderFields, headers);
  XCTAssertEqualObjects(actualRequest.HTTPBody, payload);
  XCTAssertEqual(numRequests, 1 + [retryIntervals count]);
}

@end
