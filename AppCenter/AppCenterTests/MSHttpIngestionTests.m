// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSHttpIngestion.h"
#import "MSTestFrameworks.h"

@interface MSHttpIngestionTests : XCTestCase

@end

@implementation MSHttpIngestionTests

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
