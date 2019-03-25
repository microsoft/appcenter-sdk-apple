// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSChannelGroupProtocol.h"
#import "MSCosmosDb.h"
#import "MSCosmosDbIngestion.h"
#import "MSCosmosDbPrivate.h"
#import "MSTestFrameworks.h"
#import "MSTokenResult.h"

@interface MSDataStoreTests : XCTestCase

@property(nonatomic) id settingsMock;

@end

@implementation MSDataStoreTests

static NSString *const kMSTokenTest = @"token";
static NSString *const kMSPartitionTest = @"partition";
static NSString *const kMSDbAccountTest = @"dbAccount";
static NSString *const kMSDbNameTest = @"dbName";
static NSString *const kMSDbCollectionNameTest = @"dbCollectionName";
static NSString *const kMSStatusTest = @"status";
static NSString *const kMSExpiresOnTest = @"20191212";
static NSString *const kMSDocumentIdTest = @"documentId";

- (nullable NSMutableDictionary *)prepareMutableDictionary {
  NSMutableDictionary *_Nullable tokenResultDictionary = [NSMutableDictionary new];
  tokenResultDictionary[@"partition"] = kMSPartitionTest;
  tokenResultDictionary[@"dbAccount"] = kMSDbAccountTest;
  tokenResultDictionary[@"dbName"] = kMSDbNameTest;
  tokenResultDictionary[@"dbCollectionName"] = kMSDbCollectionNameTest;
  tokenResultDictionary[@"token"] = kMSTokenTest;
  tokenResultDictionary[@"status"] = kMSStatusTest;
  tokenResultDictionary[@"expiresOn"] = kMSExpiresOnTest;
  return tokenResultDictionary;
}

- (void)testDefaultHeaderWithPartitionWithDictionaryNotNull {

  // If
  NSMutableDictionary *_Nullable additionalHeaders = [NSMutableDictionary new];
  additionalHeaders[@"Type1"] = @"Value1";
  additionalHeaders[@"Type2"] = @"Value2";
  additionalHeaders[@"Type3"] = @"Value3";

  // When
  NSDictionary *dic = [MSCosmosDb defaultHeaderWithPartition:kMSPartitionTest dbToken:kMSTokenTest additionalHeaders:additionalHeaders];

  // Then
  XCTAssertNotNil(dic);
  XCTAssertTrue(dic[@"Type1"]);
  XCTAssertTrue(dic[@"Type2"]);
  XCTAssertTrue(dic[@"Type3"]);
}

- (void)testDefaultHeaderWithPartitionWithDictionaryNull {

  // When
  NSDictionary *dic = [MSCosmosDb defaultHeaderWithPartition:kMSPartitionTest dbToken:kMSTokenTest additionalHeaders:nil];

  // Then
  XCTAssertNotNil(dic);
  XCTAssertTrue(dic[@"Content-Type"]);
}

- (void)testDocumentUrlWithTokenResultWithStringToken {

  // If
  MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithString:kMSTokenTest];

  // When
  NSString *result = [MSCosmosDb documentUrlWithTokenResult:tokenResult documentId:kMSDocumentIdTest];

  // Then
  XCTAssertNotNil(result);
}

- (void)testDocumentUrlWithTokenResultWithObjectToken {

  // When
  MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithDictionary:[self prepareMutableDictionary]];
  NSString *testResult = [MSCosmosDb documentUrlWithTokenResult:tokenResult documentId:@"documentId"];

  // Then
  XCTAssertNotNil(testResult);
  XCTAssertTrue([testResult containsString:kMSDocumentIdTest]);
  XCTAssertTrue([testResult containsString:kMSDbAccountTest]);
  XCTAssertTrue([testResult containsString:kMSDbNameTest]);
  XCTAssertTrue([testResult containsString:kMSDbCollectionNameTest]);
}

- (void)testDocumentUrlWithTokenResultWithDictionaryToken {

  // If
  MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithDictionary:[self prepareMutableDictionary]];

  // When
  NSString *testResult = [MSCosmosDb documentUrlWithTokenResult:tokenResult documentId:kMSDocumentIdTest];

  // Then
  XCTAssertNotNil(testResult);
  XCTAssertTrue([testResult containsString:kMSDocumentIdTest]);
  XCTAssertTrue([testResult containsString:kMSDbAccountTest]);
  XCTAssertTrue([testResult containsString:kMSDbNameTest]);
  XCTAssertTrue([testResult containsString:kMSDbCollectionNameTest]);
}

- (void)testPerformCosmosDbAsyncOperationWithHttpClientWithAdditionalParams {

  // If
  MSCosmosDbIngestion *httpClient = [[MSCosmosDbIngestion alloc] init];
  MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithDictionary:[self prepareMutableDictionary]];
  NSMutableDictionary *additionalHeaders = [NSMutableDictionary new];
  additionalHeaders[@"Foo"] = @"Bar";
  __block BOOL completionHandlerCalled = NO;
  XCTestExpectation *completeExpectation = [self expectationWithDescription:@"Task finished"];
  MSCosmosDbCompletionHandler handler = ^(NSData *_Nullable data, NSError *_Nullable error) {
    completionHandlerCalled = YES;
    [completeExpectation fulfill];
  };

  // When
  [MSCosmosDb performCosmosDbAsyncOperationWithHttpClient:httpClient
                                              tokenResult:tokenResult
                                               documentId:kMSDocumentIdTest
                                               httpMethod:kMSHttpMethodGet
                                                     body:nil
                                        additionalHeaders:additionalHeaders
                                        completionHandler:handler];
  [self waitForExpectationsWithTimeout:5 handler:nil];

  // Then
  XCTAssertTrue([completeExpectation assertForOverFulfill]);
  XCTAssertTrue(completionHandlerCalled);
}

- (void)testPerformCosmosDbAsyncOperationWithHttpClient {

  // If
  MSCosmosDbIngestion *httpClient = [[MSCosmosDbIngestion alloc] init];
  MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithDictionary:[self prepareMutableDictionary]];
  __block BOOL completionHandlerCalled = NO;
  XCTestExpectation *completeExpectation = [self expectationWithDescription:@"Task finished"];
  MSCosmosDbCompletionHandler handler = ^(NSData *_Nullable data, NSError *_Nullable error) {
    completionHandlerCalled = YES;
    [completeExpectation fulfill];
  };

  // When
  [MSCosmosDb performCosmosDbAsyncOperationWithHttpClient:httpClient
                                              tokenResult:tokenResult
                                               documentId:kMSDocumentIdTest
                                               httpMethod:kMSHttpMethodGet
                                                     body:nil
                                        completionHandler:handler];
  [self waitForExpectationsWithTimeout:5 handler:nil];

  // Then
  XCTAssertTrue([completeExpectation assertForOverFulfill]);
  XCTAssertTrue(completionHandlerCalled);
}
@end