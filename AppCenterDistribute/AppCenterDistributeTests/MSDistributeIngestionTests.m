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
  MSDistributeIngestion *ingestion = [[MSDistributeIngestion alloc] initWithHttpClient:[MSHttpClient new]
                                                                               baseUrl:baseUrl
                                                                               apiPath:apiPath
                                                                               headers:header
                                                                          queryStrings:nil
                                                                        retryIntervals:@[]];

  // When
  NSDictionary *headers = [ingestion getHeadersWithData:nil eTag:nil authToken:nil];
  NSData *payload = [ingestion getPayloadWithData:nil];

  // Then
  assertThat(headers, equalTo(header));
  XCTAssertNil(payload);
}

- (void)testGetHeadersWithUpdateTokenAndNilPayload {

  // If
  NSString *baseUrl = @"https://contoso.com";
  NSString *appSecret = @"secret";
  NSString *updateToken = @"updateToken";
  NSString *distributionGroupId = @"groupId";
  [MSLogger setCurrentLogLevel:MSLogLevelVerbose];
  id distributeMock = OCMPartialMock([MSDistribute sharedInstance]);
  OCMStub([distributeMock appSecret]).andReturn(@"secret");
  MSDistributeIngestion *ingestion = [[MSDistributeIngestion alloc] initWithHttpClient:[MSHttpClient new]
                                                                               baseUrl:baseUrl
                                                                             appSecret:appSecret
                                                                           updateToken:updateToken
                                                                   distributionGroupId:distributionGroupId
                                                                          queryStrings:@{}];

  // When
  NSDictionary *headers = [ingestion getHeadersWithData:[NSData new] eTag:nil authToken:nil];
  NSData *payload = [ingestion getPayloadWithData:[NSData new]];

  // Then
  assertThat(headers, equalTo(@{kMSHeaderUpdateApiToken : updateToken}));
  XCTAssertNil(payload);
}

@end
