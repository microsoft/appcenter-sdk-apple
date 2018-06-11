#import "AppCenter+Internal.h"
#import "MSAppCenterErrors.h"
#import "MSDevice.h"
#import "MSDeviceInternal.h"
#import "MSHttpSenderPrivate.h"
#import "MSHttpTestUtil.h"
#import "MSMockLog.h"
#import "MSOneCollectorIngestion.h"
#import "MSSenderCall.h"
#import "MSSenderDelegate.h"
#import "MSTestFrameworks.h"

static NSTimeInterval const kMSTestTimeout = 5.0;
static NSString *const kMSBaseUrl = @"https://test.com";

@interface MSOneCollectorIngestionTests : XCTestCase

@property(nonatomic) MSOneCollectorIngestion *sut;
@property(nonatomic) id reachabilityMock;
@property(nonatomic) NetworkStatus currentNetworkStatus;

@end

@implementation MSOneCollectorIngestionTests

- (void)setUp {
  [super setUp];

  // Mock reachability.
  self.reachabilityMock = OCMClassMock([MS_Reachability class]);
  self.currentNetworkStatus = ReachableViaWiFi;
  OCMStub([self.reachabilityMock currentReachabilityStatus]).andDo(^(NSInvocation *invocation) {
    NetworkStatus test = self.currentNetworkStatus;
    [invocation setReturnValue:&test];
  });

  // sut: System under test
  self.sut = [[MSOneCollectorIngestion alloc] initWithBaseUrl:kMSBaseUrl];
}

- (void)tearDown {
  [super tearDown];

  [MSHttpTestUtil removeAllStubs];

  /*
   * Setting the variable to nil. We are experiencing test failure on Xcode 9 beta because the instance that was used
   * for previous test method is not disposed and still listening to network changes in other tests.
   */
  self.sut = nil;
}

- (void)testHeaders {
  
  // Stub http response
  [MSHttpTestUtil stubHttp200Response];
  NSString *containerId = @"1";
  MSLogContainer *container = [self createLogContainerWithId:containerId];

  NSURLRequest *request = [self.sut createRequest:container];

  NSArray *keys = [request.allHTTPHeaderFields allKeys];
  XCTAssertTrue([keys containsObject:kMSHeaderContentTypeKey]);
  XCTAssertTrue(
      [[request.allHTTPHeaderFields objectForKey:kMSHeaderContentTypeKey] isEqualToString:kMSOneCollectorContentType]);

  XCTAssertTrue([keys containsObject:kMSOneCollectorClientVersionKey]);
  NSString *formatString = kMSOneCollectorClientVersionFormat;
  NSString *expectedClientVersion = [NSString stringWithFormat:formatString, [MSUtility sdkVersion]];
  XCTAssertTrue([[request.allHTTPHeaderFields objectForKey:kMSOneCollectorClientVersionKey] isEqualToString:expectedClientVersion]);

  XCTAssertTrue([keys containsObject:kMSOneCollectorApiKey]);
  NSArray *tokens = [[request.allHTTPHeaderFields objectForKey:kMSOneCollectorApiKey] componentsSeparatedByString:@","];
  XCTAssertTrue([tokens count] == 3);
  for (NSString *token in @[ @"token1", @"token2", @"token3" ]) {
    XCTAssertTrue([tokens containsObject:token]);
  }

  XCTAssertTrue([keys containsObject:kMSOneCollectorUploadTimeKey]);
  NSString *uploadTimeString = [request.allHTTPHeaderFields objectForKey:kMSOneCollectorUploadTimeKey];
  NSNumberFormatter *formatter = [NSNumberFormatter new];
  [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
  XCTAssertNotNil([formatter numberFromString:uploadTimeString]);
}

- (void)testCreateRequest {
  
  // Stub http response
  NSString *containerId = @"1";
  MSMockLog *log1 = [[MSMockLog alloc] init];
  [log1 addTransmissionTargetToken:@"token1"];
  MSMockLog *log2 = [[MSMockLog alloc] init];
  [log2 addTransmissionTargetToken:@"token2"];
  MSLogContainer *logContainer =
  [[MSLogContainer alloc] initWithBatchId:containerId andLogs:(NSArray<id<MSLog>> *)@[ log1, log2 ]];
  
  // When
  NSURLRequest *request = [self.sut createRequest:logContainer];
  
  // Then
  XCTAssertNotNil(request);
  NSString *containerString = [NSString stringWithFormat:@"%@%@%@%@",[log1 serializeLogWithPrettyPrinting:NO], kMSOneCollectorLogSeparator, [log2 serializeLogWithPrettyPrinting:NO], kMSOneCollectorLogSeparator];
  NSData *httpBodyData = [containerString dataUsingEncoding:NSUTF8StringEncoding];
  XCTAssertEqualObjects(httpBodyData, request.HTTPBody);
}

- (void)testSendBatchLogs {

  // Stub http response
  [MSHttpTestUtil stubHttp200Response];
  NSString *containerId = @"1";
  MSLogContainer *container = [self createLogContainerWithId:containerId];

  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP Response 200"];
  [self.sut sendAsync:container
      completionHandler:^(NSString *batchId, NSUInteger statusCode, __attribute__((unused)) NSData *data,
                          NSError *error) {

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

- (void)testInvalidContainer {

  MSAbstractLog *log = [MSAbstractLog new];
  log.sid = MS_UUID_STRING;
  log.timestamp = [NSDate date];

  // Log does not have device info, therefore, it's an invalid log
  MSLogContainer *container = [[MSLogContainer alloc] initWithBatchId:@"1" andLogs:(NSArray<id<MSLog>> *)@[ log ]];

  [self.sut sendAsync:container
      completionHandler:^(__attribute__((unused)) NSString *batchId, __attribute__((unused)) NSUInteger statusCode,
                          __attribute__((unused)) NSData *data, NSError *error) {

        XCTAssertEqual(error.domain, kMSACErrorDomain);
        XCTAssertEqual(error.code, kMSACLogInvalidContainerErrorCode);
      }];

  XCTAssertEqual([self.sut.pendingCalls count], (unsigned long)0);
}

- (void)testNilContainer {

  MSLogContainer *container = nil;

  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP Network Down"];
  [self.sut sendAsync:container
      completionHandler:^(__attribute__((unused)) NSString *batchId, __attribute__((unused)) NSUInteger statusCode,
                          __attribute__((unused)) NSData *data, NSError *error) {

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
  XCTAssertNil(query);
  XCTAssertTrue([[self.sut.sendURL absoluteString] isEqualToString:(NSString * _Nonnull)expectedURL.absoluteString]);
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

#pragma mark - Test Helpers

- (MSLogContainer *)createLogContainerWithId:(NSString *)batchId {

  // TODO: Build event logs with target tokens.
  id deviceMock = OCMPartialMock([MSDevice new]);
  OCMStub([deviceMock isValid]).andReturn(YES);

  MSMockLog *log1 = [[MSMockLog alloc] init];
  log1.sid = MS_UUID_STRING;
  log1.timestamp = [NSDate date];
  log1.device = deviceMock;
  [log1 addTransmissionTargetToken:@"token1"];
  [log1 addTransmissionTargetToken:@"token2"];

  MSMockLog *log2 = [[MSMockLog alloc] init];
  log2.sid = MS_UUID_STRING;
  log2.timestamp = [NSDate date];
  log2.device = deviceMock;
  [log2 addTransmissionTargetToken:@"token2"];
  [log2 addTransmissionTargetToken:@"token3"];
  
  MSLogContainer *logContainer =
      [[MSLogContainer alloc] initWithBatchId:batchId andLogs:(NSArray<id<MSLog>> *)@[ log1, log2 ]];
  return logContainer;
}

@end
