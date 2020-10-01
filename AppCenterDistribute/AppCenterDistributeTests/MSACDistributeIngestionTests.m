// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACConstants+Internal.h"
#import "MSACDistribute.h"
#import "MSACDistributeIngestion.h"
#import "MSACDistributePrivate.h"
#import "MSACHttpClient.h"
#import "MSACHttpIngestionPrivate.h"
#import "MSACHttpTestUtil.h"
#import "MSACLoggerInternal.h"
#import "MSACMockLog.h"
#import "MSACTestFrameworks.h"
#import "MSACTestUtil.h"
#import "MSACUtility+StringFormatting.h"

@interface MSACDistributeIngestionTests : XCTestCase

@property id httpClientMock;
@property id httpClientClassMock;
@property NSString *baseUrl;
@property NSString *actualPublicUrl;
@property NSString *actualPrivateUrl;
@property NSString *updateToken;
@property NSString *distributionGroupId;
@property MSACDistributeIngestion *sut;

@end

static NSString *const kMSACTestAppSecret = @"TestAppSecret";

@implementation MSACDistributeIngestionTests

- (void)setUp {
  self.baseUrl = @"https://contoso.com";
  self.updateToken = @"updateToken";
  self.distributionGroupId = @"groupId";
  self.actualPublicUrl = [NSString stringWithFormat:@"%@/public/sdk/apps/%@/releases/latest", self.baseUrl, kMSACTestAppSecret];
  self.actualPrivateUrl = [NSString stringWithFormat:@"%@/sdk/apps/%@/releases/private/latest", self.baseUrl, kMSACTestAppSecret];
  self.httpClientMock = OCMPartialMock([MSACHttpClient new]);
  self.httpClientClassMock = OCMClassMock([MSACHttpClient class]);
  OCMStub([self.httpClientClassMock alloc]).andReturn(self.httpClientMock);
  self.sut = [[MSACDistributeIngestion alloc] initWithHttpClient:self.httpClientMock baseUrl:self.baseUrl appSecret:kMSACTestAppSecret];
}

- (void)tearDown {
  [self.httpClientMock stopMocking];
  [self.httpClientClassMock stopMocking];
}
#pragma mark - Tests

- (void)testGetHeadersAndNilPayload {

  // When
  [self.sut checkForPublicUpdateWithQueryStrings:@{}
                               completionHandler:^(NSString *_Nonnull callId, NSHTTPURLResponse *_Nullable response __unused,
                                                   NSData *_Nullable data __unused, NSError *_Nullable error __unused) {
                                 (void)callId;
                               }];

  // Then
  OCMVerify([self.httpClientMock sendAsync:[NSURL URLWithString:self.actualPublicUrl]
                                    method:@"GET"
                                   headers:@{}
                                      data:nil
                            retryIntervals:OCMOCK_ANY
                        compressionEnabled:OCMOCK_ANY
                         completionHandler:OCMOCK_ANY]);
}

- (void)testGetHeadersWithUpdateTokenAndNilPayload {

  // If
  NSString *updateToken = @"updateToken";
  [MSACLogger setCurrentLogLevel:MSACLogLevelVerbose];
  id distributeMock = OCMPartialMock([MSACDistribute sharedInstance]);
  OCMStub([distributeMock appSecret]).andReturn(@"secret");

  // When
  [self.sut checkForPrivateUpdateWithUpdateToken:updateToken
                                    queryStrings:@{}
                               completionHandler:^(NSString *_Nonnull callId, NSHTTPURLResponse *_Nullable response __unused,
                                                   NSData *_Nullable data __unused, NSError *_Nullable error __unused) {
                                 (void)callId;
                               }];

  // Then
  OCMVerify([self.httpClientMock sendAsync:[NSURL URLWithString:self.actualPrivateUrl]
                                    method:@"GET"
                                   headers:@{kMSACHeaderUpdateApiToken : updateToken}
                                      data:nil
                            retryIntervals:OCMOCK_ANY
                        compressionEnabled:OCMOCK_ANY
                         completionHandler:OCMOCK_ANY]);

  // Cleanup
  [distributeMock stopMocking];
}

- (void)testHideTokenInResponse {

  // If
  id mockUtility = OCMClassMock([MSACUtility class]);
  id mockLogger = OCMClassMock([MSACLogger class]);
  id mockDevice = OCMPartialMock([MSACDevice new]);
  OCMStub([mockDevice isValid]).andReturn(YES);
  OCMStub([mockLogger currentLogLevel]).andReturn(MSACLogLevelVerbose);
  OCMStub(ClassMethod([mockUtility obfuscateString:OCMOCK_ANY
                               searchingForPattern:kMSACRedirectUriPattern
                             toReplaceWithTemplate:kMSACRedirectUriObfuscatedTemplate]));
  NSData *data = [@"{\"redirect_uri\":\"secrets\"}" dataUsingEncoding:NSUTF8StringEncoding];
  MSACLogContainer *container = [MSACTestUtil createLogContainerWithId:@"1" device:mockDevice];
  XCTestExpectation *requestCompletedExpectation = [self expectationWithDescription:@"Request completed."];

  // When
  [MSACHttpTestUtil stubResponseWithData:data statusCode:MSACHTTPCodesNo200OK headers:self.sut.httpHeaders name:NSStringFromSelector(_cmd)];
  [self.sut sendAsync:container
      completionHandler:^(__unused NSString *batchId, __unused NSHTTPURLResponse *response, __unused NSData *responseData,
                          __unused NSError *error) {
        [requestCompletedExpectation fulfill];
      }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 OCMVerify(ClassMethod([mockUtility obfuscateString:OCMOCK_ANY
                                                                searchingForPattern:kMSACRedirectUriPattern
                                                              toReplaceWithTemplate:kMSACRedirectUriObfuscatedTemplate]));
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];

  // Clear
  [mockUtility stopMocking];
  [mockLogger stopMocking];
}

- (void)testHttpClientDelegateObfuscateURLAndHeaderValue {

  // If
  id mockLogger = OCMClassMock([MSACLogger class]);
  id mockHttpUtil = OCMClassMock([MSACHttpUtil class]);
  OCMStub([mockLogger currentLogLevel]).andReturn(MSACLogLevelVerbose);
  __block NSString *appSecret = @"TestAppSecret";
  __block int count = 0;
  NSDictionary<NSString *, NSString *> *headers = @{kMSACHeaderUpdateApiToken : appSecret};
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", kMSACDefaultApiUrl, kMSACTestAppSecret]];

  // When
  [self.sut willSendHTTPRequestToURL:url withHeaders:headers];

  // Then
  OCMVerify([mockHttpUtil hideSecretInString:OCMOCK_ANY secret:appSecret]);

  [mockLogger stopMocking];
  [mockHttpUtil stopMocking];
}

- (void)testObfuscateResponsePayload {

  // If
  NSString *payload = @"{\"redirect_uri\" : \"some secrets here\"}";
  NSString *expectedPayload = [payload stringByReplacingOccurrencesOfString:@"some secrets here" withString:@"***"];

  // When
  NSString *actualPayload = [self.sut obfuscateResponsePayload:payload];

  // Then
  XCTAssertTrue([actualPayload isEqualToString:expectedPayload]);
}

@end
