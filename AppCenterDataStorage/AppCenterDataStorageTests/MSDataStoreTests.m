// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSChannelGroupProtocol.h"
#import "MSCosmosDb.h"
#import "MSCosmosDbIngestion.h"
#import "MSCosmosDbPrivate.h"
#import "MSTestFrameworks.h"
#import "MSTokenResult.h"
#import "MSDataSourceError.h"
#import "MSDataStore.h"
#import "MSDataStoreErrors.h"
#import "MSDataStoreInternal.h"
#import "MSDataStorePrivate.h"
#import "MSDocumentWrapper.h"
#import "MSMockUserDefaults.h"
#import "MSTokenExchange.h"
#import "MSTokensResponse.h"

@interface MSFakeSerializableDocument : NSObject <MSSerializableDocument>
- (instancetype)initFromDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)serializeToDictionary;
@end

@implementation MSFakeSerializableDocument

- (NSDictionary *)serializeToDictionary {
  return [NSDictionary new];
}

- (instancetype)initFromDictionary:(NSDictionary *)__unused dictionary {
  (self = [super init]);
  return self;
}

@end

@interface MSDataStoreTests : XCTestCase

@property(nonatomic) id settingsMock;
@property(nonatomic) id tokenExchangeMock;
@property(nonatomic) id cosmosDbMock;

@end

@implementation MSDataStoreTests

static NSString *const kMSTestAppSecret = @"TestAppSecret";
static NSString *const kMSCosmosDbHttpCodeKey = @"com.Microsoft.AppCenter.HttpCodeKey";
static NSString *const kMSDocumentTimestampKey = @"_ts";
static NSString *const kMSDocumentEtagKey = @"_etag";
static NSString *const kMSDocumentKey = @"document";
static NSString *const kMSTokenTest = @"token";
static NSString *const kMSPartitionTest = @"partition";
static NSString *const kMSDbAccountTest = @"dbAccount";
static NSString *const kMSDbNameTest = @"dbName";
static NSString *const kMSDbCollectionNameTest = @"dbCollectionName";
static NSString *const kMSStatusTest = @"status";
static NSString *const kMSExpiresOnTest = @"20191212";
static NSString *const kMSDocumentIdTest = @"documentId";

- (void)setUp {
  [super setUp];
  self.settingsMock = [MSMockUserDefaults new];
  self.tokenExchangeMock = OCMClassMock([MSTokenExchange class]);
  self.cosmosDbMock = OCMClassMock([MSCosmosDb class]);
}

- (void)tearDown {
  [super tearDown];
  [self.settingsMock stopMocking];
  [self.tokenExchangeMock stopMocking];
  [self.cosmosDbMock stopMocking];
}

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
  MSCosmosDbIngestion *httpClient = OCMPartialMock([MSCosmosDbIngestion new]);
  MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithDictionary:[self prepareMutableDictionary]];
  __block BOOL completionHandlerCalled = NO;
  MSCosmosDbCompletionHandler handler = ^(NSData *_Nullable data, NSError *_Nullable error) {
    completionHandlerCalled = YES;
  };
  NSString *expectedURLString = @"https://dbAccount.documents.azure.com/dbs/dbName/colls/dbCollectionName/docs/documentId";
  __block NSData *actualData;
  OCMStub([httpClient sendAsync:OCMOCK_ANY completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    MSCosmosDbCompletionHandler completionHandler;
    [invocation retainArguments];
    [invocation getArgument:&actualData atIndex:2];
    [invocation getArgument:&completionHandler atIndex:3];
    completionHandler(actualData, nil);
  });
  NSString *expectedUrl = @"123";
  NSMutableDictionary *additionalHeaders = [NSMutableDictionary new];
  additionalHeaders[@"Foo"] = @"Bar";
  NSDictionary *dic = @{@"abv" : @1, @"foo" : @"bar"};
  __block NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:0 error:nil];

  // When
  [MSCosmosDb performCosmosDbAsyncOperationWithHttpClient:httpClient
                                              tokenResult:tokenResult
                                               documentId:kMSDocumentIdTest
                                               httpMethod:kMSHttpMethodGet
                                                     body:data
                                        additionalHeaders:additionalHeaders
                                        completionHandler:handler];

  // Then
  XCTAssertTrue(completionHandlerCalled);
  XCTAssertEqualObjects(data, actualData);
  XCTAssertTrue([expectedURLString isEqualToString:httpClient.sendURL.absoluteString]);
}

- (void)testPerformCosmosDbAsyncOperationWithHttpClient {

  // If
  MSCosmosDbIngestion *httpClient = OCMPartialMock([MSCosmosDbIngestion new]);
  MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithDictionary:[self prepareMutableDictionary]];
  __block BOOL completionHandlerCalled = NO;
  MSCosmosDbCompletionHandler handler = ^(NSData *_Nullable data, NSError *_Nullable error) {
    completionHandlerCalled = YES;
  };
  NSString *expectedURLString = @"https://dbAccount.documents.azure.com/dbs/dbName/colls/dbCollectionName/docs/documentId";
  __block NSData *actualData;
  OCMStub([httpClient sendAsync:OCMOCK_ANY completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    MSCosmosDbCompletionHandler completionHandler;
    [invocation retainArguments];
    [invocation getArgument:&actualData atIndex:2];
    [invocation getArgument:&completionHandler atIndex:3];
    completionHandler(actualData, nil);
  });
  NSString *expectedUrl = @"123";
  NSDictionary *dic = @{@"abv" : @1, @"foo" : @"bar"};
  __block NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:0 error:nil];

  // When
  [MSCosmosDb performCosmosDbAsyncOperationWithHttpClient:httpClient
                                              tokenResult:tokenResult
                                               documentId:kMSDocumentIdTest
                                               httpMethod:kMSHttpMethodGet
                                                     body:data
                                        completionHandler:handler];

  // Then
  XCTAssertTrue(completionHandlerCalled);
  XCTAssertEqualObjects(data, actualData);
  XCTAssertTrue([expectedURLString isEqualToString:httpClient.sendURL.absoluteString]);
}

- (void)testCreateWithPartitionGoldenPath {

  // If
  NSString *partition = @"partition";
  NSString *documentId = @"documentId";
  id<MSSerializableDocument> mockSerializableDocument = [MSFakeSerializableDocument new];
  __block BOOL completionHandlerCalled = NO;

  // Mock tokens fetching.
  MSTokenResult *testToken = [[MSTokenResult alloc] initWithString:@"testToken"];
  MSTokensResponse *testTokensResponse = [[MSTokensResponse alloc] initWithTokens:@[ testToken ]];
  OCMStub([self.tokenExchangeMock performDbTokenAsyncOperationWithHttpClient:OCMOCK_ANY partition:OCMOCK_ANY completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSGetTokenAsyncCompletionHandler getTokenCallback;
        [invocation getArgument:&getTokenCallback atIndex:4];
        getTokenCallback(testTokensResponse, nil);
      });

  // Mock CosmosDB requests.
  OCMStub([self.cosmosDbMock performCosmosDbAsyncOperationWithHttpClient:OCMOCK_ANY
                                                             tokenResult:OCMOCK_ANY
                                                              documentId:OCMOCK_ANY
                                                              httpMethod:OCMOCK_ANY
                                                                    body:OCMOCK_ANY
                                                       additionalHeaders:OCMOCK_ANY
                                                       completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSCosmosDbCompletionHandler cosmosdbOperationCallback;
        [invocation getArgument:&cosmosdbOperationCallback atIndex:8];
        cosmosdbOperationCallback(nil, nil);
      });

  // When
  [MSDataStore createWithPartition:partition
                        documentId:documentId
                          document:mockSerializableDocument
                 completionHandler:^(__unused MSDocumentWrapper *data) {
                   completionHandlerCalled = YES;
                 }];

  // Then
  XCTAssertTrue(completionHandlerCalled);
}

- (void)testCreateWithPartitionWhenTokenExchangeFails {

  // If
  NSString *partition = @"partition";
  NSString *documentId = @"documentId";
  id<MSSerializableDocument> mockSerializableDocument = [MSFakeSerializableDocument new];
  __block BOOL completionHandlerCalled = NO;
  NSDictionary *errorUserInfo = @{kMSCosmosDbHttpCodeKey : @(kMSACDocumentInternalServerErrorErrorCode)};
  NSError *expectedTokenExchangeError = [NSError errorWithDomain:kMSACErrorDomain code:0 userInfo:errorUserInfo];
  __block MSDataSourceError *actualError;

  // Mock tokens fetching.
  OCMStub([self.tokenExchangeMock performDbTokenAsyncOperationWithHttpClient:OCMOCK_ANY partition:OCMOCK_ANY completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSGetTokenAsyncCompletionHandler getTokenCallback;
        [invocation getArgument:&getTokenCallback atIndex:4];
        getTokenCallback(nil, expectedTokenExchangeError);
      });

  // When
  [MSDataStore createWithPartition:partition
                        documentId:documentId
                          document:mockSerializableDocument
                 completionHandler:^(MSDocumentWrapper *data) {
                   completionHandlerCalled = YES;
                   actualError = data.error;
                 }];

  // Then
  XCTAssertTrue(completionHandlerCalled);
  XCTAssertEqualObjects(actualError.error, expectedTokenExchangeError);
}

- (void)testCreateWithPartitionWhenCreationFails {

  // If
  NSString *partition = @"partition";
  NSString *documentId = @"documentId";
  id<MSSerializableDocument> mockSerializableDocument = [MSFakeSerializableDocument new];
  __block BOOL completionHandlerCalled = NO;
  NSDictionary *errorUserInfo = @{kMSCosmosDbHttpCodeKey : @(kMSACDocumentInternalServerErrorErrorCode)};
  NSError *expectedCosmosDbError = [NSError errorWithDomain:kMSACErrorDomain code:0 userInfo:errorUserInfo];
  __block MSDataSourceError *actualError;

  // Mock tokens fetching.
  MSTokenResult *testToken = [[MSTokenResult alloc] initWithString:@"testToken"];
  MSTokensResponse *testTokensResponse = [[MSTokensResponse alloc] initWithTokens:@[ testToken ]];
  OCMStub([self.tokenExchangeMock performDbTokenAsyncOperationWithHttpClient:OCMOCK_ANY partition:OCMOCK_ANY completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSGetTokenAsyncCompletionHandler getTokenCallback;
        [invocation getArgument:&getTokenCallback atIndex:4];
        getTokenCallback(testTokensResponse, nil);
      });

  // Mock CosmosDB requests.
  OCMStub([self.cosmosDbMock performCosmosDbAsyncOperationWithHttpClient:OCMOCK_ANY
                                                             tokenResult:OCMOCK_ANY
                                                              documentId:OCMOCK_ANY
                                                              httpMethod:OCMOCK_ANY
                                                                    body:OCMOCK_ANY
                                                       additionalHeaders:OCMOCK_ANY
                                            completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSCosmosDbCompletionHandler cosmosdbOperationCallback;
        [invocation getArgument:&cosmosdbOperationCallback atIndex:8];
        cosmosdbOperationCallback(nil, expectedCosmosDbError);
      });

  // When
  [MSDataStore createWithPartition:partition
                        documentId:documentId
                          document:mockSerializableDocument
                 completionHandler:^(MSDocumentWrapper *data) {
                   completionHandlerCalled = YES;
                   actualError = data.error;
                 }];

  // Then
  XCTAssertTrue(completionHandlerCalled);
  XCTAssertEqualObjects(actualError.error, expectedCosmosDbError);
}

- (void)testCreateWithPartitionWhenDeserializationFails {

  // If
  NSString *partition = @"partition";
  NSString *documentId = @"documentId";
  id<MSSerializableDocument> mockSerializableDocument = [MSFakeSerializableDocument new];
  __block BOOL completionHandlerCalled = NO;
  __block MSDataSourceError *actualError;

  // Mock tokens fetching.
  MSTokenResult *testToken = [[MSTokenResult alloc] initWithString:@"testToken"];
  MSTokensResponse *testTokensResponse = [[MSTokensResponse alloc] initWithTokens:@[ testToken ]];
  OCMStub([self.tokenExchangeMock performDbTokenAsyncOperationWithHttpClient:OCMOCK_ANY partition:OCMOCK_ANY completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSGetTokenAsyncCompletionHandler getTokenCallback;
        [invocation getArgument:&getTokenCallback atIndex:4];
        getTokenCallback(testTokensResponse, nil);
      });

  // Mock CosmosDB requests.
  NSData *brokenCosmosDbResponse = [@"<h1>502 Bad Gateway</h1>" dataUsingEncoding:NSUTF8StringEncoding];
  OCMStub([self.cosmosDbMock performCosmosDbAsyncOperationWithHttpClient:OCMOCK_ANY
                                                             tokenResult:OCMOCK_ANY
                                                              documentId:OCMOCK_ANY
                                                              httpMethod:OCMOCK_ANY
                                                                    body:OCMOCK_ANY
                                                       additionalHeaders:OCMOCK_ANY
                                            completionHandlerWithHeaders:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSCosmosDbCompletionHandlerWithHeaders cosmosdbOperationCallback;
        [invocation getArgument:&cosmosdbOperationCallback atIndex:8];
        cosmosdbOperationCallback(brokenCosmosDbResponse, nil, nil);
      });

  // When
  [MSDataStore createWithPartition:partition
                        documentId:documentId
                          document:mockSerializableDocument
                 completionHandler:^(MSDocumentWrapper *data) {
                   completionHandlerCalled = YES;
                   actualError = data.error;
                 }];

  // Then
  XCTAssertTrue(completionHandlerCalled);
  XCTAssertEqual(actualError.error.domain, NSCocoaErrorDomain);
  XCTAssertEqual(actualError.error.code, 3840);
}

/*
- (void)testDeleteDocumentWithPartitionWithoutWriteOptions {

    // If
    NSString *partition = @"partition";
    NSString *documentId = @"documentId";
    __block BOOL completionHandlerCalled = NO;
    XCTestExpectation *completeExpectation = [self expectationWithDescription:@"Task finished"];
    MSDataSourceErrorCompletionHandler completionHandler = ^(MSDataSourceError __unused *error) {
        completionHandlerCalled = YES;
        [completionHandler fulfill];
    };

    // When
    [MSDataStore deleteDocumentWithPartition:partition documentId:documentId completionHandler:completionHandler];
    [self waitForExpectationsWithTimeout:5 handler:nil];

    // Then
    XCTAssertTrue([completeExpectation assertForOverFulfill]);
    XCTAssertTrue(completionHandlerCalled);
}

- (void)testDeleteDocumentWithPartitionWithWriteOptions {

    // If
    NSString *partition = @"partition";
    NSString *documentId = @"documentId";
    MSWriteOptions *options = [MSWriteOptions new];
    __block BOOL completionHandlerCalled = NO;
    XCTestExpectation *completeExpectation = [self expectationWithDescription:@"Task finished"];
    MSDataSourceErrorCompletionHandler completionHandler = ^(MSDataSourceError *error) {
        completionHandlerCalled = YES;
        [completionHandler fulfill];
    };

    // When
    [MSDataStore deleteDocumentWithPartition:partition documentId:documentId writeOptions:options completionHandler:completionHandler];
    [self waitForExpectationsWithTimeout:5 handler:nil];

    // Then
    XCTAssertTrue([completeExpectation assertForOverFulfill]);
    XCTAssertTrue(completionHandlerCalled);
}
 */

@end
