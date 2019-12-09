// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDistribute.h"
#import "MSDistributeIngestion.h"
#import "MSDistributePrivate.h"
#import "MSHttpClient.h"
#import "MSHttpIngestionPrivate.h"
#import "MSLoggerInternal.h"
#import "MSTestFrameworks.h"

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

@end
