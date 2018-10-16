#import "AppCenter+Internal.h"
#import "MSAppCenterErrors.h"
#import "MSDevice.h"
#import "MSDeviceInternal.h"
#import "MSHttpIngestionPrivate.h"
#import "MSHttpTestUtil.h"
#import "MSIngestionCall.h"
#import "MSIngestionDelegate.h"
#import "MSMockCommonSchemaLog.h"
#import "MSModelTestsUtililty.h"
#import "MSOneCollectorIngestion.h"
#import "MSOneCollectorIngestionPrivate.h"
#import "MSTestFrameworks.h"
#import "MSTicketCache.h"

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
   * Setting the variable to nil. We are experiencing test failure on Xcode 9 beta because the instance that was used for previous test
   * method is not disposed and still listening to network changes in other tests.
   */
  self.sut = nil;
}

- (void)testHeaders {

  // If
  id ticketCacheMock = OCMPartialMock([MSTicketCache sharedInstance]);
  OCMStub([ticketCacheMock ticketFor:@"ticketKey1"]).andReturn(@"ticketKey1Token");
  OCMStub([ticketCacheMock ticketFor:@"ticketKey2"]).andReturn(@"ticketKey2Token");

  // When
  NSString *containerId = @"1";
  MSLogContainer *container = [self createLogContainerWithId:containerId];
  NSURLRequest *request = [self.sut createRequest:container];
  NSArray *keys = [request.allHTTPHeaderFields allKeys];

  // Then
  XCTAssertTrue([keys containsObject:kMSHeaderContentTypeKey]);
  XCTAssertTrue([[request.allHTTPHeaderFields objectForKey:kMSHeaderContentTypeKey] isEqualToString:kMSOneCollectorContentType]);
  XCTAssertTrue([keys containsObject:kMSOneCollectorClientVersionKey]);
  NSString *expectedClientVersion = [NSString stringWithFormat:kMSOneCollectorClientVersionFormat, [MSUtility sdkVersion]];
  XCTAssertTrue([[request.allHTTPHeaderFields objectForKey:kMSOneCollectorClientVersionKey] isEqualToString:expectedClientVersion]);
  XCTAssertNil([request.allHTTPHeaderFields objectForKey:kMSHeaderAppSecretKey]);
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
  XCTAssertTrue([keys containsObject:kMSOneCollectorTicketsKey]);
  NSString *ticketsHeader = [request.allHTTPHeaderFields objectForKey:kMSOneCollectorTicketsKey];
  XCTAssertTrue([ticketsHeader isEqualToString:@"{\"ticketKey2\":\"ticketKey2Token\",\"ticketKey1\":\"ticketKey1Token\"}"]);
}

- (void)testObfuscateHeaderValue {

  // If
  NSString *testString = @"12345678";

  // When
  NSString *result = [self.sut obfuscateHeaderValue:testString forKey:kMSOneCollectorApiKey];

  // If
  testString = @"ThisWillBeObfuscated, ThisWillBeObfuscated, ThisWillBeObfuscated";

  // When
  result = [self.sut obfuscateHeaderValue:testString forKey:kMSOneCollectorApiKey];

  // Then
  XCTAssertTrue([result isEqualToString:@"************fuscated,*************fuscated,*************fuscated"]);

  // If
  testString = @"something";

  // When
  result = [self.sut obfuscateHeaderValue:testString forKey:kMSOneCollectorTicketsKey];

  // Then
  XCTAssertTrue([result isEqualToString:testString]);

  // If
  testString = @"{\"ticketKey1\":\"p:AuthorizationValue1\",\"ticketKey2\":\"d:AuthorizationValue2\"}";

  // When
  result = [self.sut obfuscateHeaderValue:testString forKey:kMSOneCollectorTicketsKey];

  // Then
  XCTAssertTrue([result isEqualToString:@"{\"ticketKey1\":\"p:***\",\"ticketKey2\":\"d:***\"}"]);
}

- (void)testCreateRequest {

  // If
  NSString *containerId = @"1";
  MSMockCommonSchemaLog *log1 = [[MSMockCommonSchemaLog alloc] init];
  [log1 addTransmissionTargetToken:@"token1"];
  MSMockCommonSchemaLog *log2 = [[MSMockCommonSchemaLog alloc] init];
  [log2 addTransmissionTargetToken:@"token2"];
  MSLogContainer *logContainer = [[MSLogContainer alloc] initWithBatchId:containerId andLogs:(NSArray<id<MSLog>> *)@[ log1, log2 ]];

  // When
  NSURLRequest *request = [self.sut createRequest:logContainer];

  // Then
  XCTAssertNotNil(request);
  NSString *containerString = [NSString stringWithFormat:@"%@%@%@%@", [log1 serializeLogWithPrettyPrinting:NO], kMSOneCollectorLogSeparator,
                                                         [log2 serializeLogWithPrettyPrinting:NO], kMSOneCollectorLogSeparator];
  NSData *httpBodyData = [containerString dataUsingEncoding:NSUTF8StringEncoding];
  XCTAssertEqualObjects(httpBodyData, request.HTTPBody);
}

- (void)testSendBatchLogs {

  // When

  // Stub http response
  [MSHttpTestUtil stubHttp200Response];
  NSString *containerId = @"1";
  MSLogContainer *container = [self createLogContainerWithId:containerId];
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP Response 200"];
  [self.sut sendAsync:container
      completionHandler:^(NSString *batchId, NSUInteger statusCode, __attribute__((unused)) NSData *data, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqual(containerId, batchId);
        XCTAssertEqual((MSHTTPCodesNo)statusCode, MSHTTPCodesNo200OK);
        [expectation fulfill];
      }];

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testInvalidContainer {

  // If
  MSAbstractLog *log = [MSAbstractLog new];
  log.sid = MS_UUID_STRING;
  log.timestamp = [NSDate date];

  // Log does not have device info, therefore, it's an invalid log.
  MSLogContainer *container = [[MSLogContainer alloc] initWithBatchId:@"1" andLogs:(NSArray<id<MSLog>> *)@[ log ]];

  // When
  [self.sut sendAsync:container
      completionHandler:^(__attribute__((unused)) NSString *batchId, __attribute__((unused)) NSUInteger statusCode,
                          __attribute__((unused)) NSData *data, NSError *error) {

        // Then
        XCTAssertEqual(error.domain, kMSACErrorDomain);
        XCTAssertEqual(error.code, kMSACLogInvalidContainerErrorCode);
      }];

  // Then
  XCTAssertEqual([self.sut.pendingCalls count], (unsigned long)0);
}

- (void)testNilContainer {

  // If
  MSLogContainer *container = nil;

  // When
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP Network Down"];
  [self.sut sendAsync:container
      completionHandler:^(__attribute__((unused)) NSString *batchId, __attribute__((unused)) NSUInteger statusCode,
                          __attribute__((unused)) NSData *data, NSError *error) {

        // Then
        XCTAssertNotNil(error);
        [expectation fulfill];
      }];

  // Then
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

- (void)testDoNotCompressHTTPBody {

  // If

  // HTTP body is too small, we don't compress.
  id deviceMock = OCMPartialMock([MSDevice new]);
  OCMStub([deviceMock isValid]).andReturn(YES);
  MSMockCommonSchemaLog *log1 = [[MSMockCommonSchemaLog alloc] init];
  log1.sid = @"";
  log1.timestamp = [NSDate date];
  MSLogContainer *logContainer = [[MSLogContainer alloc] initWithBatchId:@"whatever" andLogs:(NSArray<id<MSLog>> *)@[ log1 ]];
  NSMutableString *jsonString = [NSMutableString new];
  for (id<MSLog> log in logContainer.logs) {
    MSAbstractLog *abstractLog = (MSAbstractLog *)log;
    [jsonString appendString:[abstractLog serializeLogWithPrettyPrinting:NO]];
    [jsonString appendString:kMSOneCollectorLogSeparator];
  }
  NSData *httpBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];

  // When
  NSURLRequest *request = [self.sut createRequest:logContainer];

  // Then
  XCTAssertNil(request.allHTTPHeaderFields[kMSHeaderContentEncodingKey]);
  XCTAssertEqualObjects(request.HTTPBody, httpBody);
}

- (void)testCompressHTTPBody {
  // If

  // HTTP body is big enough to be compressed.
  id deviceMock = OCMPartialMock([MSDevice new]);
  OCMStub([deviceMock isValid]).andReturn(YES);
  MSMockCommonSchemaLog *log1 = [[MSMockCommonSchemaLog alloc] init];
  log1.sid = @"";
  log1.timestamp = [NSDate date];
  log1.ext = [MSModelTestsUtililty extensionsWithDummyValues:[MSModelTestsUtililty extensionDummies]];
  NSMutableString *jsonString = [NSMutableString new];
  log1.sid = [log1.sid stringByPaddingToLength:kMSHTTPMinGZipLength withString:@"." startingAtIndex:0];
  log1.name = [log1.sid stringByPaddingToLength:kMSHTTPMinGZipLength withString:@"abcd" startingAtIndex:0];
  MSLogContainer *logContainer = [[MSLogContainer alloc] initWithBatchId:@"whatever" andLogs:(NSArray<id<MSLog>> *)@[ log1 ]];
  for (id<MSLog> log in logContainer.logs) {
    MSCommonSchemaLog *abstractLog = (MSCommonSchemaLog *)log;
    [jsonString appendString:[abstractLog serializeLogWithPrettyPrinting:NO]];
    [jsonString appendString:kMSOneCollectorLogSeparator];
  }
  NSData *httpBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];

  // When
  NSURLRequest *request = [self.sut createRequest:logContainer];

  // Then
  XCTAssertEqual(request.allHTTPHeaderFields[kMSHeaderContentEncodingKey], kMSHeaderContentEncoding);
  XCTAssertTrue(request.HTTPBody.length < httpBody.length);
}

#pragma mark - Test Helpers

- (MSLogContainer *)createLogContainerWithId:(NSString *)batchId {
  id deviceMock = OCMPartialMock([MSDevice new]);
  OCMStub([deviceMock isValid]).andReturn(YES);
  MSMockCommonSchemaLog *log1 = [[MSMockCommonSchemaLog alloc] init];
  log1.name = @"log1";
  log1.ver = @"3.0";
  log1.sid = MS_UUID_STRING;
  log1.timestamp = [NSDate date];
  log1.device = deviceMock;
  [log1 addTransmissionTargetToken:@"token1"];
  [log1 addTransmissionTargetToken:@"token2"];
  log1.ext = [MSModelTestsUtililty extensionsWithDummyValues:[MSModelTestsUtililty extensionDummies]];
  MSMockCommonSchemaLog *log2 = [[MSMockCommonSchemaLog alloc] init];
  log2.name = @"log2";
  log2.ver = @"3.0";
  log2.sid = MS_UUID_STRING;
  log2.timestamp = [NSDate date];
  log2.device = deviceMock;
  [log2 addTransmissionTargetToken:@"token2"];
  [log2 addTransmissionTargetToken:@"token3"];
  log2.ext = [MSModelTestsUtililty extensionsWithDummyValues:[MSModelTestsUtililty extensionDummies]];
  MSLogContainer *logContainer = [[MSLogContainer alloc] initWithBatchId:batchId andLogs:(NSArray<id<MSLog>> *)@[ log1, log2 ]];
  return logContainer;
}

@end
