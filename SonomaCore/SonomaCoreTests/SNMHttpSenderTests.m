/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMDevice.h"
#import "SNMDevicePrivate.h"
#import "SNMHttpSender.h"
#import "SNMHttpSenderPrivate.h"
#import "SNMLogContainer.h"
#import "SNMMockLog.h"
#import "SNMRetriableCall.h"
#import "SNMRetriableCallPrivate.h"
#import "SNMSenderDelegate.h"
#import "SNM_Reachability.h"
#import "SonomaCore+Internal.h"

#import "OCMock.h"
#import "OHHTTPStubs.h"
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <XCTest/XCTest.h>

static NSTimeInterval const kSNMTestTimeout = 5.0;
static NSString *const kSNMBaseUrl = @"https://test.com";
static NSString *const kSNMAppSecret = @"mockAppSecret";

@interface SNMHttpSenderTests : XCTestCase

@property(nonatomic, strong) SNMHttpSender *sut;
@property(nonatomic, strong) id reachabilityMock;
@property(nonatomic) NetworkStatus currentNetworkStatus;

@end

@implementation SNMHttpSenderTests

- (void)setUp {
  [super setUp];

  NSDictionary *headers = @{
    @"Content-Type" : @"application/json",
    @"App-Secret" : @"myUnitTestAppSecret",
    @"Install-ID" : kSNMUUIDString
  };

  NSDictionary *queryStrings = @{ @"api_version" : @"1.0.0-preview20160914" };

  // Mock reachability.
  self.reachabilityMock = OCMClassMock([SNM_Reachability class]);
  self.currentNetworkStatus = ReachableViaWiFi;
  OCMStub([self.reachabilityMock currentReachabilityStatus]).andDo(^(NSInvocation *invocation) {
    NetworkStatus test = self.currentNetworkStatus;
    [invocation setReturnValue:&test];
  });

  // sut: System under test
  self.sut = [[SNMHttpSender alloc] initWithBaseUrl:kSNMBaseUrl
                                            headers:headers
                                       queryStrings:queryStrings
                                       reachability:self.reachabilityMock];

  // Set short retry intervals
  self.sut.callsRetryIntervals = @[ @(0.5), @(1), @(1.5) ];
}

- (void)tearDown {
  [super tearDown];

  [OHHTTPStubs removeAllStubs];
}

- (void)stubNSURLSession {
  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    return YES;
  }
      withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        NSData *stubData = [@"Sonoma Response" dataUsingEncoding:NSUTF8StringEncoding];
        return [OHHTTPStubsResponse responseWithData:stubData statusCode:SNMHTTPCodesNo200OK headers:nil];
      }]
      .name = @"httpStub_200";

  [OHHTTPStubs onStubActivation:^(NSURLRequest *_Nonnull request, id<OHHTTPStubsDescriptor> _Nonnull stub,
                                  OHHTTPStubsResponse *_Nonnull responseStub) {
    NSLog(@"%@ stubbed by %@.", request.URL, stub.name);
  }];
}

- (void)testSendBatchLogs {

  // Stub http response
  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    return YES;
  }
      withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        NSData *stubData = [@"Sonoma Response" dataUsingEncoding:NSUTF8StringEncoding];
        return [OHHTTPStubsResponse responseWithData:stubData statusCode:SNMHTTPCodesNo200OK headers:nil];
      }]
      .name = @"httpStub_200";

  NSString *containerId = @"1";
  SNMLogContainer *container = [self createLogContainerWithId:containerId];

  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP Response 200"];
  [self.sut sendAsync:container
      completionHandler:^(NSString *batchId, NSError *error, NSUInteger statusCode) {

        XCTAssertNil(error);
        XCTAssertEqual(containerId, batchId);
        XCTAssertEqual(statusCode, SNMHTTPCodesNo200OK);

        [expectation fulfill];
      }];

  [self waitForExpectationsWithTimeout:kSNMTestTimeout
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testNetworkDown {

  /**
   * If
   */
  NSError *expectedError =
      [NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil];
  XCTestExpectation *requestCompletedExcpectation = [self expectationWithDescription:@"Request completed."];
  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    return YES; // All requests
  }
      withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithError:expectedError];
      }]
      .name = @"httpStub_NetworkDown";
  SNMLogContainer *container = [self createLogContainerWithId:@"1"];

  // Set a delegate for suspending event.
  id delegateMock = OCMProtocolMock(@protocol(SNMSenderDelegate));
  OCMStub([delegateMock senderDidSuspend:self.sut]).andDo(^(NSInvocation *invocation) {
    [requestCompletedExcpectation fulfill];
  });
  [self.sut addDelegate:delegateMock];

  /**
   * When
   */
  [self.sut sendAsync:container
      completionHandler:^(NSString *batchId, NSError *error, NSUInteger statusCode) {

        // This should not be happening.
        XCTFail(@"Completion handler should'nt be called on recoverable errors.");
      }];

  /**
   * Then
   */
  [self waitForExpectationsWithTimeout:kSNMTestTimeout
                               handler:^(NSError *error) {

                                 // The call must still be in the pending calls, intended to be retried later.
                                 assertThatUnsignedLong(self.sut.pendingCalls.count, equalToInt(1));

                                 // Sender must be suspended when network is down.
                                 assertThatBool(self.sut.suspended, isTrue());
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testNetworkUpAgain {

  /**
   * If
   */
  XCTestExpectation *requestCompletedExcpectation = [self expectationWithDescription:@"Request completed."];
  __block NSInteger forwardedStatus;
  __block NSError *forwardedError;
  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    return YES; // All requests
  }
      withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        OHHTTPStubsResponse *responseStub = [OHHTTPStubsResponse new];
        responseStub.statusCode = SNMHTTPCodesNo200OK;
        return responseStub;
      }]
      .name = @"httpStub_NetworkUpAgain";
  SNMLogContainer *container = [self createLogContainerWithId:@"1"];

  // Set a delegate for suspending/resuming event.
  id delegateMock = OCMProtocolMock(@protocol(SNMSenderDelegate));
  [self.sut addDelegate:delegateMock];
  OCMStub([delegateMock senderDidSuspend:self.sut]).andDo(^(NSInvocation *invocation) {

    // Send one batch now that the sender is suspended.
    [self.sut sendAsync:container
        completionHandler:^(NSString *batchId, NSError *error, NSUInteger statusCode) {
          forwardedStatus = statusCode;
          forwardedError = error;
          [requestCompletedExcpectation fulfill];
        }];

    /**
     * When
     */

    // Simulate network up again.
    [self simulateReachabilityChangedNotification:ReachableViaWiFi];
  });

  // Simulate network is down.
  [self simulateReachabilityChangedNotification:NotReachable];

  /**
   * Then
   */
  [self waitForExpectationsWithTimeout:kSNMTestTimeout
                               handler:^(NSError *error) {

                                 // The sender got resumed.
                                 OCMVerify([delegateMock senderDidResume:self.sut]);
                                 assertThatBool(self.sut.suspended, isFalse());

                                 // The call as been removed.
                                 assertThatUnsignedLong(self.sut.pendingCalls.count, equalToInt(0));

                                 // Status codes and error must be the same.
                                 assertThatLong(SNMHTTPCodesNo200OK, equalToLong(forwardedStatus));
                                 assertThat(forwardedError, nilValue());
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testRetryExhausted {

  /**
   * If
   */
  __block SNMRetriableCall *retriableCall;
  XCTestExpectation *requestCompletedExcpectation = [self expectationWithDescription:@"Request completed."];
  __block NSInteger forwardedStatus;
  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    return YES;
  }
      withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        OHHTTPStubsResponse *responseStub = [OHHTTPStubsResponse new];
        responseStub.statusCode = SNMHTTPCodesNo500InternalServerError;
        return responseStub;
      }]
      .name = @"httpStub_Retriable";
  NSString *containerId = @"1";
  SNMLogContainer *container = [self createLogContainerWithId:containerId];

  /**
   * When
   */
  [self.sut sendAsync:container
      completionHandler:^(NSString *batchId, NSError *error, NSUInteger statusCode) {
        retriableCall = self.sut.pendingCalls[batchId];
        forwardedStatus = statusCode;
        [requestCompletedExcpectation fulfill];
      }];

  /**
   * Then
   */
  [self waitForExpectationsWithTimeout:kSNMTestTimeout
                               handler:^(NSError *error) {

                                 // Max retry for the call is reached.
                                 assertThatBool([retriableCall hasReachedMaxRetries], isTrue());

                                 // All retry intervals as been exhausted.
                                 assertThatUnsignedLong(retriableCall.retryCount,
                                                        equalToUnsignedLong(retriableCall.retryIntervals.count));

                                 // The call as been removed.
                                 assertThatUnsignedLong([self.sut.pendingCalls count], equalToInt(0));

                                 // Status codes must be the same.
                                 assertThatLong(SNMHTTPCodesNo500InternalServerError, equalToLong(forwardedStatus));
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testInvalidContainer {

  SNMMockLog *log1 = [[SNMMockLog alloc] init];
  log1.sid = kSNMUUIDString;
  log1.toffset = [NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]];

  // Log does not have device info, therefore, it's an invalid log
  SNMLogContainer *container = [[SNMLogContainer alloc] initWithBatchId:@"1" andLogs:(NSArray<SNMLog> *)@[ log1 ]];

  [self.sut sendAsync:container
      completionHandler:^(NSString *batchId, NSError *error, NSUInteger statusCode) {

        XCTAssertEqual(error.domain, kSNMDefaultApiErrorDomain);
        XCTAssertEqual(error.code, kSNMDefaultApiMissingParamErrorCode);
      }];

  XCTAssertEqual([self.sut.pendingCalls count], 0);
}

- (void)testNilContainer {

  SNMLogContainer *container = nil;

  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP Network Down"];
  [self.sut sendAsync:container
      completionHandler:^(NSString *batchId, NSError *error, NSUInteger statusCode) {

        XCTAssertNotNil(error);
        [expectation fulfill];

      }];

  [self waitForExpectationsWithTimeout:kSNMTestTimeout
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testAddDelegate {

  // If.
  id delegateMock = OCMProtocolMock(@protocol(SNMSenderDelegate));

  // When.
  [self.sut addDelegate:delegateMock];

  // Then.
  assertThatBool([self.sut.delegates containsObject:delegateMock], isTrue());
}

- (void)testAddMultipleDelegates {

  // If.
  id delegateMock1 = OCMProtocolMock(@protocol(SNMSenderDelegate));
  id delegateMock2 = OCMProtocolMock(@protocol(SNMSenderDelegate));

  // When.
  [self.sut addDelegate:delegateMock1];
  [self.sut addDelegate:delegateMock2];

  // Then.
  assertThatBool([self.sut.delegates containsObject:delegateMock1], isTrue());
  assertThatBool([self.sut.delegates containsObject:delegateMock2], isTrue());
}

- (void)testAddTwiceSameDelegate {

  // If.
  id delegateMock = OCMProtocolMock(@protocol(SNMSenderDelegate));

  // When.
  [self.sut addDelegate:delegateMock];
  [self.sut addDelegate:delegateMock];

  // Then.
  assertThatBool([self.sut.delegates containsObject:delegateMock], isTrue());
  assertThatUnsignedLong(self.sut.delegates.count, equalToInt(1));
}

- (void)testRemoveDelegate {

  // If.
  id delegateMock = OCMProtocolMock(@protocol(SNMSenderDelegate));
  [self.sut addDelegate:delegateMock];

  // When.
  [self.sut removeDelegate:delegateMock];

  // Then.
  assertThatBool([self.sut.delegates containsObject:delegateMock], isFalse());
}

- (void)testRemoveTwiceSameDelegate {

  // If.
  id delegateMock1 = OCMProtocolMock(@protocol(SNMSenderDelegate));
  id delegateMock2 = OCMProtocolMock(@protocol(SNMSenderDelegate));
  [self.sut addDelegate:delegateMock1];
  [self.sut addDelegate:delegateMock2];

  // When.
  [self.sut removeDelegate:delegateMock1];
  [self.sut removeDelegate:delegateMock1];

  // Then.
  assertThatBool([self.sut.delegates containsObject:delegateMock1], isFalse());
  assertThatBool([self.sut.delegates containsObject:delegateMock2], isTrue());
  assertThatUnsignedLong(self.sut.delegates.count, equalToInt(1));
}

- (void)testNullifiedDelegate {

  // If.
  @autoreleasepool {
    __weak id delegateMock = OCMProtocolMock(@protocol(SNMSenderDelegate));
    [self.sut addDelegate:delegateMock];

    // When.
    delegateMock = nil;
  }

  // Then.
  // There is a bug somehow in NSHashTable where the count on the table itself is not decremented while an object is
  // deallocated and auto removed from the table. The NSHashtable allObjects: is used instead to remediate.
  assertThatUnsignedLong(self.sut.delegates.allObjects.count, equalToInt(0));
}

- (void)testCallDelegatesOnSuspended {

  // If.
  id delegateMock1 = OCMProtocolMock(@protocol(SNMSenderDelegate));
  id delegateMock2 = OCMProtocolMock(@protocol(SNMSenderDelegate));
  [self.sut resume];
  [self.sut addDelegate:delegateMock1];
  [self.sut addDelegate:delegateMock2];

  // When.
  [self.sut suspend];

  // Then.
  OCMVerify([delegateMock1 senderDidSuspend:self.sut]);
  OCMVerify([delegateMock2 senderDidSuspend:self.sut]);
}

- (void)testCallDelegatesOnResumed {

  // If.
  id delegateMock1 = OCMProtocolMock(@protocol(SNMSenderDelegate));
  id delegateMock2 = OCMProtocolMock(@protocol(SNMSenderDelegate));
  [self.sut suspend];
  [self.sut addDelegate:delegateMock1];
  [self.sut addDelegate:delegateMock2];

  // When.
  [self.sut suspend];
  [self.sut resume];

  // Then.
  OCMVerify([delegateMock1 senderDidResume:self.sut]);
  OCMVerify([delegateMock2 senderDidResume:self.sut]);
}

#pragma mark - Test Helpers

- (void)simulateReachabilityChangedNotification:(NetworkStatus)status {
  self.currentNetworkStatus = status;
  [[NSNotificationCenter defaultCenter] postNotificationName:kSNMReachabilityChangedNotification
                                                      object:self.reachabilityMock];
}

- (SNMLogContainer *)createLogContainerWithId:(NSString *)batchId {

  SNMDevice *device = [[SNMDevice alloc] init];
  device.sdkVersion = @"1.0.0";

  SNMMockLog *log1 = [[SNMMockLog alloc] init];
  log1.sid = kSNMUUIDString;
  log1.toffset = [NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]];
  log1.device = device;

  SNMMockLog *log2 = [[SNMMockLog alloc] init];
  log2.sid = kSNMUUIDString;
  log2.toffset = [NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]];
  log2.device = device;

  SNMLogContainer *logContainer =
      [[SNMLogContainer alloc] initWithBatchId:batchId andLogs:(NSArray<SNMLog> *)@[ log1, log2 ]];
  return logContainer;
}

@end
