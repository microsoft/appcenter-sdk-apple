// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "AppCenter+Internal.h"
#import "MSAppCenterErrors.h"
#import "MSConstants+Internal.h"
#import "MSDeviceInternal.h"
#import "MSHttpClient.h"
#import "MSHttpIngestionPrivate.h"
#import "MSHttpTestUtil.h"
#import "MSLoggerInternal.h"
#import "MSMockCommonSchemaLog.h"
#import "MSModelTestsUtililty.h"
#import "MSOneCollectorIngestion.h"
#import "MSOneCollectorIngestionPrivate.h"
#import "MSTestFrameworks.h"
#import "MSTicketCache.h"
#import "MSUtility+StringFormatting.h"

static NSTimeInterval const kMSTestTimeout = 5.0;
static NSString *const kMSBaseUrl = @"https://test.com";

@interface MSOneCollectorIngestionTests : XCTestCase

@property(nonatomic) MSOneCollectorIngestion *sut;
@property(nonatomic) id reachabilityMock;
@property(nonatomic) NetworkStatus currentNetworkStatus;
@property(nonatomic) MSHttpClient *httpClientMock;
@end

@implementation MSOneCollectorIngestionTests

- (void)setUp {
  [super setUp];

  self.httpClientMock = OCMPartialMock([MSHttpClient new]);
  self.reachabilityMock = OCMClassMock([MS_Reachability class]);
  self.currentNetworkStatus = ReachableViaWiFi;
  OCMStub([self.reachabilityMock currentReachabilityStatus]).andDo(^(NSInvocation *invocation) {
    NetworkStatus test = self.currentNetworkStatus;
    [invocation setReturnValue:&test];
  });

  // sut: System under test
  self.sut = [[MSOneCollectorIngestion alloc] initWithHttpClient:self.httpClientMock baseUrl:kMSBaseUrl];
}

- (void)tearDown {
  [super tearDown];
  [self.reachabilityMock stopMocking];
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
  NSDictionary *headers = [self.sut getHeadersWithData:container eTag:nil];
  NSArray *keys = [headers allKeys];

  // Then
  XCTAssertTrue([keys containsObject:kMSHeaderContentTypeKey]);
  XCTAssertTrue([[headers objectForKey:kMSHeaderContentTypeKey] isEqualToString:kMSOneCollectorContentType]);
  XCTAssertTrue([keys containsObject:kMSOneCollectorClientVersionKey]);
  NSString *expectedClientVersion = [NSString stringWithFormat:kMSOneCollectorClientVersionFormat, [MSUtility sdkVersion]];
  XCTAssertTrue([[headers objectForKey:kMSOneCollectorClientVersionKey] isEqualToString:expectedClientVersion]);
  XCTAssertNil([headers objectForKey:kMSHeaderAppSecretKey]);
  XCTAssertTrue([keys containsObject:kMSOneCollectorApiKey]);
  NSArray *tokens = [[headers objectForKey:kMSOneCollectorApiKey] componentsSeparatedByString:@","];
  XCTAssertTrue([tokens count] == 3);
  for (NSString *token in @[ @"token1", @"token2", @"token3" ]) {
    XCTAssertTrue([tokens containsObject:token]);
  }
  XCTAssertTrue([keys containsObject:kMSOneCollectorUploadTimeKey]);
  NSString *uploadTimeString = [headers objectForKey:kMSOneCollectorUploadTimeKey];
  NSNumberFormatter *formatter = [NSNumberFormatter new];
  [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
  XCTAssertNotNil([formatter numberFromString:uploadTimeString]);
  XCTAssertTrue([keys containsObject:kMSOneCollectorTicketsKey]);
  NSString *ticketsHeader = [headers objectForKey:kMSOneCollectorTicketsKey];
  XCTAssertTrue([ticketsHeader isEqualToString:@"{\"ticketKey2\":\"ticketKey2Token\",\"ticketKey1\":\"ticketKey1Token\"}"]);
}

- (void)testHttpClientDelegateObfuscateHeaderValue {

  // If
  id mockLogger = OCMClassMock([MSLogger class]);
  id ingestionMock = OCMPartialMock(self.sut);
  OCMStub([mockLogger currentLogLevel]).andReturn(MSLogLevelVerbose);
  OCMStub([ingestionMock obfuscateTargetTokens:OCMOCK_ANY]).andDo(nil);
  OCMStub([ingestionMock obfuscateTickets:OCMOCK_ANY]).andDo(nil);
  NSString *tokenValue = @"12345678";
  NSString *ticketValue = @"something";
  NSDictionary<NSString *, NSString *> *headers = @{kMSOneCollectorApiKey : tokenValue, kMSOneCollectorTicketsKey : ticketValue};
  NSURL *url = [NSURL new];

  // When
  [ingestionMock willSendHTTPRequestToURL:url withHeaders:headers];

  // Then
  OCMVerify([ingestionMock obfuscateTargetTokens:tokenValue]);
  OCMVerify([ingestionMock obfuscateTickets:ticketValue]);

  [mockLogger stopMocking];
  [ingestionMock stopMocking];
}

- (void)testObfuscateTargetTokens {

  // If
  NSString *testString = @"12345678";

  // When
  NSString *result = [self.sut obfuscateTargetTokens:testString];

  // Then
  XCTAssertTrue([result isEqualToString:@"********"]);

  // If
  testString = @"ThisWillBeObfuscated, ThisWillBeObfuscated, ThisWillBeObfuscated";

  // When
  result = [self.sut obfuscateTargetTokens:testString];

  // Then
  XCTAssertTrue([result isEqualToString:@"************fuscated,*************fuscated,*************fuscated"]);
}

- (void)testObfuscateTickets {

  // If
  NSString *testString = @"something";

  // When
  NSString *result = [self.sut obfuscateTickets:testString];

  // Then
  XCTAssertTrue([result isEqualToString:testString]);

  // If
  testString = @"{\"ticketKey1\":\"p:AuthorizationValue1\",\"ticketKey2\":\"d:AuthorizationValue2\"}";

  // When
  result = [self.sut obfuscateTickets:testString];

  // Then
  XCTAssertTrue([result isEqualToString:@"{\"ticketKey1\":\"p:***\",\"ticketKey2\":\"d:***\"}"]);
}

- (void)testGetPayload {

  // If
  NSString *containerId = @"1";
  MSMockCommonSchemaLog *log1 = [[MSMockCommonSchemaLog alloc] init];
  [log1 addTransmissionTargetToken:@"token1"];
  MSMockCommonSchemaLog *log2 = [[MSMockCommonSchemaLog alloc] init];
  [log2 addTransmissionTargetToken:@"token2"];
  MSLogContainer *logContainer = [[MSLogContainer alloc] initWithBatchId:containerId andLogs:(NSArray<id<MSLog>> *)@[ log1, log2 ]];

  // When
  NSData *payload = [self.sut getPayloadWithData:logContainer];

  // Then
  XCTAssertNotNil(payload);
  NSString *containerString = [NSString stringWithFormat:@"%@%@%@%@", [log1 serializeLogWithPrettyPrinting:NO], kMSOneCollectorLogSeparator,
                                                         [log2 serializeLogWithPrettyPrinting:NO], kMSOneCollectorLogSeparator];
  NSData *httpBodyData = [containerString dataUsingEncoding:NSUTF8StringEncoding];
  XCTAssertEqualObjects(httpBodyData, payload);
}

- (void)testSendBatchLogs {

  // When

  // Stub http response
  [MSHttpTestUtil stubHttp200Response];
  NSString *containerId = @"1";
  MSLogContainer *container = [self createLogContainerWithId:containerId];
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP Response 200"];
  [self.sut sendAsync:container
      completionHandler:^(NSString *batchId, NSHTTPURLResponse *response, __attribute__((unused)) NSData *data, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqual(containerId, batchId);
        XCTAssertEqual((MSHTTPCodesNo)response.statusCode, MSHTTPCodesNo200OK);
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
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP Response 200"];
  MSAbstractLog *log = [MSAbstractLog new];
  log.sid = MS_UUID_STRING;
  log.timestamp = [NSDate date];

  // Log does not have device info, therefore, it's an invalid log.
  MSLogContainer *container = [[MSLogContainer alloc] initWithBatchId:@"1" andLogs:(NSArray<id<MSLog>> *)@[ log ]];
  OCMReject([self.httpClientMock sendAsync:OCMOCK_ANY
                                    method:OCMOCK_ANY
                                   headers:OCMOCK_ANY
                                      data:OCMOCK_ANY
                            retryIntervals:OCMOCK_ANY
                        compressionEnabled:OCMOCK_ANY
                         completionHandler:OCMOCK_ANY]);

  // When
  [self.sut sendAsync:container
      completionHandler:^(__attribute__((unused)) NSString *batchId, __attribute__((unused)) NSHTTPURLResponse *response,
                          __attribute__((unused)) NSData *data, NSError *error) {
        // Then
        XCTAssertEqual(error.domain, kMSACErrorDomain);
        XCTAssertEqual(error.code, MSACLogInvalidContainerErrorCode);
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

- (void)testNilContainer {

  // If
  MSLogContainer *container = nil;

  // When
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP Network Down"];
  [self.sut sendAsync:container
      completionHandler:^(__attribute__((unused)) NSString *batchId, __attribute__((unused)) NSHTTPURLResponse *response,
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
  XCTAssertTrue([[self.sut.sendURL absoluteString] isEqualToString:(NSString * _Nonnull) expectedURL.absoluteString]);
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

- (void)testHideTokenInResponse {

  // If
  id mockUtility = OCMClassMock([MSUtility class]);
  id mockLogger = OCMClassMock([MSLogger class]);
  OCMStub([mockLogger currentLogLevel]).andReturn(MSLogLevelVerbose);
  OCMStub(ClassMethod([mockUtility obfuscateString:OCMOCK_ANY
                               searchingForPattern:kMSTokenKeyValuePattern
                             toReplaceWithTemplate:kMSTokenKeyValueObfuscatedTemplate]));
  NSData *data = [@"{\"token\":\"secrets\"}" dataUsingEncoding:NSUTF8StringEncoding];
  MSLogContainer *logContainer = [self createLogContainerWithId:@"1"];
  XCTestExpectation *requestCompletedExpectation = [self expectationWithDescription:@"Request completed."];

  // When
  [MSHttpTestUtil stubResponseWithData:data statusCode:MSHTTPCodesNo200OK headers:self.sut.httpHeaders name:NSStringFromSelector(_cmd)];
  [self.sut sendAsync:logContainer
      completionHandler:^(__unused NSString *batchId, __unused NSHTTPURLResponse *response, __unused NSData *responseData,
                          __unused NSError *error) {
        [requestCompletedExpectation fulfill];
      }];

  // Then
  [self waitForExpectationsWithTimeout:kMSTestTimeout
                               handler:^(NSError *error) {
                                 OCMVerify(ClassMethod([mockUtility obfuscateString:OCMOCK_ANY
                                                                searchingForPattern:kMSTokenKeyValuePattern
                                                              toReplaceWithTemplate:kMSTokenKeyValueObfuscatedTemplate]));
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  // Clear
  [mockUtility stopMocking];
  [mockLogger stopMocking];
}

@end
