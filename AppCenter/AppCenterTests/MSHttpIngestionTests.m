// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSHttpIngestionPrivate.h"
#import "MSTestFrameworks.h"
#import "MSHttpClient.h"
#import "MSIngestionDelegate.h"

@interface MSHttpIngestionTests : XCTestCase

@property(nonatomic) MSHttpIngestion *sut;
@property(nonatomic) MSHttpClient *httpClientMock;

@end

@implementation MSHttpIngestionTests

- (void)setUp {
  [super setUp];

  NSDictionary *queryStrings = @{@"api-version" : @"1.0.0"};
  self.httpClientMock = OCMPartialMock([MSHttpClient new]);

  // sut: System under test
  self.sut = [[MSHttpIngestion alloc] initWithHttpClient:self.httpClientMock
                                                 baseUrl:@"https://www.contoso.com"
                                                      apiPath:@"/test-path"
                                                      headers:nil
                                                 queryStrings:queryStrings
                                               retryIntervals:@[ @(0.5), @(1), @(1.5) ]];
}

- (void)tearDown {
  [super tearDown];

  self.sut = nil;
}

- (void)testValidETagFromResponse {

  // If
  NSString *expectedETag = @"IAmAnETag";
  NSHTTPURLResponse *response = [NSHTTPURLResponse new];
  id responseMock = OCMPartialMock(response);
  OCMStub([responseMock allHeaderFields]).andReturn(@{@"Etag" : expectedETag});

  // When
  NSString *eTag = [MSHttpIngestion eTagFromResponse:responseMock];

  // Then
  XCTAssertEqualObjects(expectedETag, eTag);
}

- (void)testInvalidETagFromResponse {

  // If
  NSHTTPURLResponse *response = [NSHTTPURLResponse new];
  id responseMock = OCMPartialMock(response);
  OCMStub([responseMock allHeaderFields]).andReturn(@{@"Etag1" : @"IAmAnETag"});

  // When
  NSString *eTag = [MSHttpIngestion eTagFromResponse:responseMock];

  // Then
  XCTAssertNil(eTag);
}

- (void)testNoETagFromResponse {

  // If
  NSHTTPURLResponse *response = [NSHTTPURLResponse new];

  // When
  NSString *eTag = [MSHttpIngestion eTagFromResponse:response];

  // Then
  XCTAssertNil(eTag);
}

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
  XCTAssertTrue(false);
}

/*
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
*/
@end
