// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDistribute.h"
#import "MSDistributeIngestion.h"
#import "MSDistributePrivate.h"
#import "MSHttpClient.h"
#import "MSHttpIngestionPrivate.h"
#import "MSLoggerInternal.h"
#import "MSTestFrameworks.h"
#import "MSUtility+StringFormatting.h"
#import "MSConstants+Internal.h"
#import "MSTestUtil.h"
#import "MSMockLog.h"
#import "MSHttpTestUtil.h"

@interface MSDistributeIngestionTests : XCTestCase

@end

@implementation MSDistributeIngestionTests

#pragma mark - Tests

- (void)testGetHeadersAndNilPayload {

  // If
  NSString *baseUrl = @"https://contoso.com";
  NSString *apiPath = @"/test";
  NSDictionary *header = [NSDictionary new];
  id httpClientMock = OCMPartialMock([MSHttpClient new]);
  id httpClientClassMock = OCMClassMock([MSHttpClient class]);
  OCMStub([httpClientClassMock alloc]).andReturn(httpClientMock);
  MSDistributeIngestion *ingestion = [[MSDistributeIngestion alloc] initWithHttpClient:httpClientMock
                                                                               baseUrl:baseUrl
                                                                               apiPath:apiPath
                                                                               headers:header
                                                                          queryStrings:nil
                                                                        retryIntervals:@[]];

  // When
  NSDictionary *headers = [ingestion getHeadersWithData:nil eTag:nil authToken:nil];
  NSData *payload = [ingestion getPayloadWithData:nil];
  [ingestion sendAsync:[NSData new]
      completionHandler:^(NSString *_Nonnull callId, NSHTTPURLResponse *_Nullable response __unused, NSData *_Nullable data __unused,
                          NSError *_Nullable error __unused) {
        (void)callId;
      }];

  // Then
  assertThat(headers, equalTo(header));
  NSString *matchingString = [NSString stringWithFormat:@"%@%@", baseUrl, apiPath];
  OCMVerify([httpClientMock sendAsync:[NSURL URLWithString:matchingString]
                               method:@"GET"
                              headers:OCMOCK_ANY
                                 data:OCMOCK_ANY
                       retryIntervals:OCMOCK_ANY
                   compressionEnabled:OCMOCK_ANY
                    completionHandler:OCMOCK_ANY]);
  XCTAssertNil(payload);

  // Cleanup
  [httpClientMock stopMocking];
  [httpClientClassMock stopMocking];
}

- (void)testGetHeadersWithUpdateTokenAndNilPayload {

  // If
  NSString *baseUrl = @"https://contoso.com";
  NSString *appSecret = @"secret";
  NSString *updateToken = @"updateToken";
  NSString *distributionGroupId = @"groupId";
  NSString *secretApiPath = [NSString stringWithFormat:@"/sdk/apps/%@/releases/latest", appSecret];
  [MSLogger setCurrentLogLevel:MSLogLevelVerbose];
  id distributeMock = OCMPartialMock([MSDistribute sharedInstance]);
  OCMStub([distributeMock appSecret]).andReturn(@"secret");
  id httpClientMock = OCMPartialMock([MSHttpClient new]);
  id httpClientClassMock = OCMClassMock([MSHttpClient class]);
  OCMStub([httpClientClassMock alloc]).andReturn(httpClientMock);
  MSDistributeIngestion *ingestion = [[MSDistributeIngestion alloc] initWithHttpClient:httpClientMock
                                                                               baseUrl:baseUrl
                                                                             appSecret:appSecret
                                                                           updateToken:updateToken
                                                                   distributionGroupId:distributionGroupId
                                                                          queryStrings:@{}];

  // When
  NSDictionary *headers = [ingestion getHeadersWithData:[NSData new] eTag:nil authToken:nil];
  NSData *payload = [ingestion getPayloadWithData:[NSData new]];
  [ingestion sendAsync:[NSData new]
      completionHandler:^(NSString *_Nonnull callId, NSHTTPURLResponse *_Nullable response __unused, NSData *_Nullable data __unused,
                          NSError *_Nullable error __unused) {
        (void)callId;
      }];

  // Then
  assertThat(headers, equalTo(@{kMSHeaderUpdateApiToken : updateToken}));
  NSString *matchingString = [NSString stringWithFormat:@"%@%@", baseUrl, secretApiPath];
  OCMVerify([httpClientMock sendAsync:[NSURL URLWithString:matchingString]
                               method:@"GET"
                              headers:OCMOCK_ANY
                                 data:OCMOCK_ANY
                       retryIntervals:OCMOCK_ANY
                   compressionEnabled:OCMOCK_ANY
                    completionHandler:OCMOCK_ANY]);
  XCTAssertNil(payload);

  // Cleanup
  [httpClientMock stopMocking];
  [distributeMock stopMocking];
  [httpClientClassMock stopMocking];
}

- (void)testHideTokenInResponse {
  
  // If
  NSString *baseUrl = @"https://contoso.com";
  NSString *appSecret = @"secret";
  NSString *updateToken = @"updateToken";
  NSString *distributionGroupId = @"groupId";
  id httpClientMock = OCMPartialMock([MSHttpClient new]);
  id httpClientClassMock = OCMClassMock([MSHttpClient class]);
  OCMStub([httpClientClassMock alloc]).andReturn(httpClientMock);
  MSDistributeIngestion *ingestion = [[MSDistributeIngestion alloc] initWithHttpClient:httpClientMock
                                                                               baseUrl:baseUrl
                                                                             appSecret:appSecret
                                                                           updateToken:updateToken
                                                                   distributionGroupId:distributionGroupId
                                                                          queryStrings:@{}];
  id mockUtility = OCMClassMock([MSUtility class]);
  id mockLogger = OCMClassMock([MSLogger class]);
  id mockDevice = OCMPartialMock([MSDevice new]);
  OCMStub([mockDevice isValid]).andReturn(YES);
  OCMStub([mockLogger currentLogLevel]).andReturn(MSLogLevelVerbose);
  OCMStub(ClassMethod([mockUtility obfuscateString:OCMOCK_ANY
                               searchingForPattern:kMSRedirectUriPattern
                             toReplaceWithTemplate:kMSRedirectUriObfuscatedTemplate]));
  NSData *data = [@"{\"redirect_uri\":\"secrets\"}" dataUsingEncoding:NSUTF8StringEncoding];
  MSLogContainer *container = [MSTestUtil createLogContainerWithId:@"1" device:mockDevice];
  XCTestExpectation *requestCompletedExpectation = [self expectationWithDescription:@"Request completed."];
  
  // When
  [MSHttpTestUtil stubResponseWithData:data statusCode:MSHTTPCodesNo200OK headers:ingestion.httpHeaders name:NSStringFromSelector(_cmd)];
  [ingestion sendAsync:container
            authToken:nil
    completionHandler:^(__unused NSString *batchId, __unused NSHTTPURLResponse *response, __unused NSData *responseData,
                        __unused NSError *error) {
      [requestCompletedExpectation fulfill];
    }];
  
  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 OCMVerify(ClassMethod([mockUtility obfuscateString:OCMOCK_ANY
                                                                searchingForPattern:kMSRedirectUriPattern
                                                              toReplaceWithTemplate:kMSRedirectUriObfuscatedTemplate]));
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
  
  // Clear
  [mockUtility stopMocking];
  [mockLogger stopMocking];
}

@end
