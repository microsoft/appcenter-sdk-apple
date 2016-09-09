/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMHttpSender.h"
#import "SNMLogContainer.h"
#import "SNMMockLog.h"
#import "SNM_Reachability.h"
#import "SNMlancheHub+Internal.h"

#import "OCMock.h"
#import "OHHTTPStubs.h"
#import <XCTest/XCTest.h>

static NSTimeInterval const kSNMTestTimeout = 5.0;
static NSString *const kSNMBaseUrl = @"https://test.com";
static NSString *const kSNMAppSecret = @"mockAppSecret";

@interface SNMHttpSenderTests : XCTestCase

@property(nonatomic, strong) SNMHttpSender *sut;

@end

@implementation SNMHttpSenderTests

- (void)setUp {
  [super setUp];

  NSDictionary *headers = @{
    @"Content-Type" : @"application/json",
    @"App-Secret" : @"myUnitTestAppSecret",
    @"Install-ID" : kSNMUUIDString
  };

  NSDictionary *queryStrings = @{ @"api-version" : @"1.0.0-preview20160901" };

  id reachabilityMock = OCMClassMock([SNM_Reachability class]);
  // sut: System under test
  _sut = [[SNMHttpSender alloc] initWithBaseUrl:kSNMBaseUrl
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
        NSData *stubData = [@"Sonoma Response" dataUsingEncoding:NSUTF8StringEncoding];
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
        NSData *stubData = [@"Sonoma Response" dataUsingEncoding:NSUTF8StringEncoding];
        return [OHHTTPStubsResponse responseWithData:stubData statusCode:SNMHTTPCodesNo200OK headers:nil];
      }]
      .name = @"httpStub_200";

  NSString *containerId = @"1";
  SNMLogContainer *container = [self createLogContainerWithId:containerId];

  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP Response 200"];
  [_sut sendAsync:container
          callbackQueue:dispatch_get_main_queue()
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
  SNMLogContainer *container = [self createLogContainerWithId:containerId];

  [_sut sendAsync:container
          callbackQueue:dispatch_get_main_queue()
      completionHandler:^(NSString *batchId, NSError *error, NSUInteger statusCode) {

        // Callback should not get called
        XCTAssertTrue(NO);
      }];

  XCTAssertEqual([self.sut.pendingCalls count], 1);
}

- (void)testInvalidContainer {

  SNMMockLog *log1 = [[SNMMockLog alloc] init];
  log1.sid = kSNMUUIDString;
  log1.toffset = [NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]];

  // Log does not have device info, therefore, it's an invalid log
  SNMLogContainer *container = [[SNMLogContainer alloc] initWithBatchId:@"1" andLogs:(NSArray<SNMLog> *)@[ log1 ]];

  [_sut sendAsync:container
          callbackQueue:dispatch_get_main_queue()
      completionHandler:^(NSString *batchId, NSError *error, NSUInteger statusCode) {

        XCTAssertEqual(error.domain, kSNMDefaultApiErrorDomain);
        XCTAssertEqual(error.code, kSNMDefaultApiMissingParamErrorCode);
      }];

  XCTAssertEqual([self.sut.pendingCalls count], 0);
}

- (void)testNilContainer {

  SNMLogContainer *container = nil;

  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP Network Down"];
  [_sut sendAsync:container
          callbackQueue:dispatch_get_main_queue()
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

#pragma mark - Test Helpers

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
