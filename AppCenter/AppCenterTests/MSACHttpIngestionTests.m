// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACAppCenterErrors.h"
#import "MSACAppCenterInternal.h"
#import "MSACDevice.h"
#import "MSACHttpClient.h"
#import "MSACHttpIngestionPrivate.h"
#import "MSACHttpTestUtil.h"
#import "MSACMockUserDefaults.h"
#import "MSACTestFrameworks.h"
#import "MSACTestUtil.h"

static NSTimeInterval const kMSACTestTimeout = 5.0;

@interface MSACHttpIngestionTests : XCTestCase

@property(nonatomic) MSACHttpIngestion *sut;
@property(nonatomic) MSACHttpClient *httpClientMock;
@property(nonatomic) MSACMockUserDefaults *settingsMock;

@end

@implementation MSACHttpIngestionTests

- (void)setUp {
  [super setUp];
  NSDictionary *queryStrings = @{@"api-version" : @"1.0.0"};
  self.httpClientMock = OCMPartialMock([MSACHttpClient new]);
  self.settingsMock = [MSACMockUserDefaults new];

  // sut: System under test
  self.sut = [[MSACHttpIngestion alloc] initWithHttpClient:self.httpClientMock
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
  NSString *eTag = [MSACHttpIngestion eTagFromResponse:responseMock];

  // Then
  XCTAssertEqualObjects(expectedETag, eTag);
}

- (void)testInvalidETagFromResponse {

  // If
  NSHTTPURLResponse *response = [NSHTTPURLResponse new];
  id responseMock = OCMPartialMock(response);
  OCMStub([responseMock allHeaderFields]).andReturn(@{@"Etag1" : @"IAmAnETag"});

  // When
  NSString *eTag = [MSACHttpIngestion eTagFromResponse:responseMock];

  // Then
  XCTAssertNil(eTag);
}

- (void)testNoETagFromResponse {

  // If
  NSHTTPURLResponse *response = [NSHTTPURLResponse new];

  // When
  NSString *eTag = [MSACHttpIngestion eTagFromResponse:response];

  // Then
  XCTAssertNil(eTag);
}

- (void)testIsEnabled {

  // If
  BOOL networkRequestsAllowed = YES;

  // When
  [self.settingsMock setObject:@(networkRequestsAllowed) forKey:kMSACAppCenterNetworkRequestsAllowedKey];

  // Then
  XCTAssertTrue([self.sut isEnabled]);

  // If
  networkRequestsAllowed = NO;

  // When
  [self.settingsMock setObject:@(networkRequestsAllowed) forKey:kMSACAppCenterNetworkRequestsAllowedKey];

  // Then
  XCTAssertFalse([self.sut isEnabled]);
}

- (void)testSendAsync {

  // If
  [MSACHttpTestUtil stubHttp200Response];
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP Response 200"];

  // When
  [self.sut sendAsync:nil
                   eTag:nil
      completionHandler:^(__unused NSString *batchId, NSHTTPURLResponse *response, __unused NSData *data, NSError *error) {
        // Then
        XCTAssertNil(error);
        XCTAssertEqual((MSACHTTPCodesNo)response.statusCode, MSACHTTPCodesNo200OK);
        [expectation fulfill];
      }];
  [self waitForExpectationsWithTimeout:kMSACTestTimeout
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testSendAsyncWhenNetworkRequestsForbidden {

  // If
  [self.settingsMock setObject:@(NO) forKey:kMSACAppCenterNetworkRequestsAllowedKey];
  [MSACHttpTestUtil stubHttp200Response];
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP Response 200"];

  // When
  [self.sut sendAsync:nil
                   eTag:nil
      completionHandler:^(__unused NSString *batchId, NSHTTPURLResponse *response, __unused NSData *data, NSError *error) {
        // Then
        XCTAssertNotNil(error);
        XCTAssertNil(response);
        XCTAssertEqual(error.code, MSACACDisabledErrorCode);
        [expectation fulfill];
      }];
  [self waitForExpectationsWithTimeout:kMSACTestTimeout
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

@end
