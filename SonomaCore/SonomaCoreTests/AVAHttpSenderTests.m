/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAHttpSender.h"
#import "AVALogContainer.h"
#import "AVAMockLog.h"
#import "AVA_Reachability.h"
#import "SonomaCore+Internal.h"

#import "OCMock.h"
#import "OHHTTPStubs.h"
#import <XCTest/XCTest.h>

static NSTimeInterval const kAVATestTimeout = 5.0;
static NSString *const kAVABaseUrl = @"https://test.com";
static NSString *const kAVAAppSecret = @"mockAppSecret";

@interface AVAHttpSenderTests : XCTestCase

@property(nonatomic, strong) AVAHttpSender *sut;

@end

@implementation AVAHttpSenderTests

- (void)setUp {
  [super setUp];

  NSDictionary *headers = @{
    @"Content-Type" : @"application/json",
    @"App-Secret" : @"myUnitTestAppSecret",
    @"Install-ID" : kAVAUUIDString
  };

  NSDictionary *queryStrings = @{ @"api-version" : @"1.0.0-preview20160901" };

  id reachabilityMock = OCMClassMock([AVA_Reachability class]);
  // sut: System under test
  _sut = [[AVAHttpSender alloc] initWithBaseUrl:kAVABaseUrl
                                        headers:headers
                                   queryStrings:queryStrings
                                   reachability:reachabilityMock];
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
        NSData *stubData = [@"Avalanche Response" dataUsingEncoding:NSUTF8StringEncoding];
        return [OHHTTPStubsResponse responseWithData:stubData statusCode:200 headers:nil];
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
        NSData *stubData = [@"Avalanche Response" dataUsingEncoding:NSUTF8StringEncoding];
        return [OHHTTPStubsResponse responseWithData:stubData statusCode:AVAHTTPCodesNo200OK headers:nil];
      }]
      .name = @"httpStub_200";

  NSString *containerId = @"1";
  AVALogContainer *container = [self createLogContainerWithId:containerId];

  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP Response 200"];
  [_sut sendAsync:container
          callbackQueue:dispatch_get_main_queue()
      completionHandler:^(NSString *batchId, NSError *error, NSUInteger statusCode) {

        XCTAssertNil(error);
        XCTAssertEqual(containerId, batchId);
        XCTAssertEqual(statusCode, AVAHTTPCodesNo200OK);

        [expectation fulfill];
      }];

  [self waitForExpectationsWithTimeout:kAVATestTimeout
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testNetworkDown {

  // Stub response
  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    return YES; // All requests
  }
      withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        NSError *notConnectedError =
            [NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil];
        return [OHHTTPStubsResponse responseWithError:notConnectedError];
      }]
      .name = @"httpStub_NetworkDown";

  NSString *containerId = @"1";
  AVALogContainer *container = [self createLogContainerWithId:containerId];

  [_sut sendAsync:container
          callbackQueue:dispatch_get_main_queue()
      completionHandler:^(NSString *batchId, NSError *error, NSUInteger statusCode) {

        // Callback should not get called
        XCTAssertTrue(NO);
      }];

  XCTAssertEqual([self.sut.pendingCalls count], 1);
}

- (void)testInvalidContainer {

  AVAMockLog *log1 = [[AVAMockLog alloc] init];
  log1.sid = kAVAUUIDString;
  log1.toffset = [NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]];

  // Log does not have device info, therefore, it's an invalid log
  AVALogContainer *container = [[AVALogContainer alloc] initWithBatchId:@"1" andLogs:(NSArray<AVALog> *)@[ log1 ]];

  [_sut sendAsync:container
          callbackQueue:dispatch_get_main_queue()
      completionHandler:^(NSString *batchId, NSError *error, NSUInteger statusCode) {

        XCTAssertEqual(error.domain, kAVADefaultApiErrorDomain);
        XCTAssertEqual(error.code, kAVADefaultApiMissingParamErrorCode);
      }];

  XCTAssertEqual([self.sut.pendingCalls count], 0);
}

- (void)testNilContainer {

  AVALogContainer *container = nil;

  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP Network Down"];
  [_sut sendAsync:container
          callbackQueue:dispatch_get_main_queue()
      completionHandler:^(NSString *batchId, NSError *error, NSUInteger statusCode) {

        XCTAssertNotNil(error);
        [expectation fulfill];

      }];

  [self waitForExpectationsWithTimeout:kAVATestTimeout
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

#pragma mark - Test Helpers

- (AVALogContainer *)createLogContainerWithId:(NSString *)batchId {

  AVADevice *device = [[AVADevice alloc] init];
  device.sdkVersion = @"1.0.0";

  AVAMockLog *log1 = [[AVAMockLog alloc] init];
  log1.sid = kAVAUUIDString;
  log1.toffset = [NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]];
  log1.device = device;

  AVAMockLog *log2 = [[AVAMockLog alloc] init];
  log2.sid = kAVAUUIDString;
  log2.toffset = [NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]];
  log2.device = device;

  AVALogContainer *logContainer =
      [[AVALogContainer alloc] initWithBatchId:batchId andLogs:(NSArray<AVALog> *)@[ log1, log2 ]];
  return logContainer;
}

@end
