// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAppCenter.h"
#import "MSChannelGroupProtocol.h"
#import "MSConstants+Internal.h"
#import "MSCosmosDb.h"
#import "MSCosmosDbPrivate.h"
#import "MSDataSourceError.h"
#import "MSDataStoreErrors.h"
#import "MSDataStoreInternal.h"
#import "MSDataStorePrivate.h"
#import "MSDictionaryDocument.h"
#import "MSDispatchTestUtil.h"
#import "MSDocumentStore.h"
#import "MSDocumentUtils.h"
#import "MSDocumentWrapperInternal.h"
#import "MSHttpClient.h"
#import "MSHttpTestUtil.h"
#import "MSMockUserDefaults.h"
#import "MSPaginatedDocuments.h"
#import "MSServiceAbstract.h"
#import "MSServiceAbstractProtected.h"
#import "MSTestFrameworks.h"
#import "MSTokenExchange.h"
#import "MSTokenResult.h"
#import "MSTokensResponse.h"
#import "MS_Reachability.h"
#import "NSObject+MSTestFixture.h"

@interface MSDataStoreTests : XCTestCase

@property(nonatomic, strong) MSDataStore *sut;
@property(nonatomic) id settingsMock;
@property(nonatomic) id tokenExchangeMock;
@property(nonatomic) id cosmosDbMock;
@end

@implementation MSDataStoreTests

static NSString *const kMSTestAppSecret = @"TestAppSecret";
static NSString *const kMSTokenTest = @"token";
static NSString *const kMSPartitionTest = @"user";
static NSString *const kMSDbAccountTest = @"dbAccount";
static NSString *const kMSAccountId = @"ceb61029-d032-4e7a-be03-2614cfe2a564";
static NSString *const kMSDbNameTest = @"dbName";
static NSString *const kMSDbCollectionNameTest = @"dbCollectionName";
static NSString *const kMSStatusTest = @"status";
static NSString *const kMSExpiresOnTest = @"2999-09-19T11:11:11.111Z";
static NSString *const kMSDocumentIdTest = @"documentId";

- (void)setUp {
  [super setUp];
  self.settingsMock = [MSMockUserDefaults new];
  self.sut = [MSDataStore sharedInstance];
  self.tokenExchangeMock = OCMClassMock([MSTokenExchange class]);
  self.cosmosDbMock = OCMClassMock([MSCosmosDb class]);
  [MSAppCenter configureWithAppSecret:kMSTestAppSecret];
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                        appSecret:kMSTestAppSecret
          transmissionTargetToken:nil
                  fromApplication:YES];
}

- (void)tearDown {
  [super tearDown];
  [MSDispatchTestUtil awaitAndSuspendDispatchQueue:self.sut.dispatchQueue];
  [MSDataStore resetSharedInstance];
  [self.settingsMock stopMocking];
  [self.tokenExchangeMock stopMocking];
  [self.cosmosDbMock stopMocking];
}

- (nullable NSMutableDictionary *)prepareMutableDictionary {
  NSMutableDictionary *_Nullable tokenResultDictionary = [NSMutableDictionary new];
  tokenResultDictionary[@"partition"] = [MSDataStoreTests fullTestPartitionName];
  tokenResultDictionary[@"dbAccount"] = kMSDbAccountTest;
  tokenResultDictionary[@"dbName"] = kMSDbNameTest;
  tokenResultDictionary[@"dbCollectionName"] = kMSDbCollectionNameTest;
  tokenResultDictionary[@"token"] = kMSTokenTest;
  tokenResultDictionary[@"status"] = kMSStatusTest;
  tokenResultDictionary[@"expiresOn"] = kMSExpiresOnTest;
  return tokenResultDictionary;
}

- (void)testApplyEnabledStateWorks {

  // If
  self.sut.httpClient = OCMProtocolMock(@protocol(MSHttpClientProtocol));
  __block int enabledCount = 0;
  OCMStub([self.sut.httpClient setEnabled:YES]).andDo(^(__unused NSInvocation *invocation) {
    enabledCount++;
  });
  __block int disabledCount = 0;
  OCMStub([self.sut.httpClient setEnabled:NO]).andDo(^(__unused NSInvocation *invocation) {
    disabledCount++;
  });

  // When
  [self.sut setEnabled:YES];

  // Then
  XCTAssertTrue([self.sut isEnabled]);

  // It's already enabled at start so the enabled logic is not triggered again.
  XCTAssertEqual(enabledCount, 0);

  // When
  [self.sut setEnabled:NO];

  // Then
  XCTAssertFalse([self.sut isEnabled]);
  XCTAssertEqual(disabledCount, 1);

  // When
  [self.sut setEnabled:NO];

  // Then
  XCTAssertFalse([self.sut isEnabled]);

  // It's already disabled, so the disabled logic is not triggered again.
  XCTAssertEqual(disabledCount, 1);

  // When
  [self.sut setEnabled:YES];

  // Then
  XCTAssertTrue([self.sut isEnabled]);
  XCTAssertEqual(enabledCount, 1);
}

- (void)testReadWhenDataModuleDisabled {

  // If
  self.sut.httpClient = OCMProtocolMock(@protocol(MSHttpClientProtocol));
  OCMReject([self.sut.httpClient sendAsync:OCMOCK_ANY method:OCMOCK_ANY headers:OCMOCK_ANY data:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
  __block MSDocumentWrapper *actualDocumentWrapper;
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called."];

  // When
  [self.sut setEnabled:NO];
  [MSDataStore readWithPartition:kMSPartitionTest
                      documentId:kMSDocumentIdTest
                    documentType:[MSDictionaryDocument class]
               completionHandler:^(MSDocumentWrapper *data) {
                 actualDocumentWrapper = data;
                 [expectation fulfill];
               }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
  XCTAssertNotNil(actualDocumentWrapper);
  XCTAssertNotNil(actualDocumentWrapper.error);
  XCTAssertEqual(actualDocumentWrapper.error.error.domain, kMSACErrorDomain);
  XCTAssertEqual(actualDocumentWrapper.error.error.code, MSACDisabledErrorCode);
  XCTAssertEqualObjects(actualDocumentWrapper.documentId, kMSDocumentIdTest);
}

- (void)testReadWithInvalidDocumentType {

  // If
  self.sut.httpClient = OCMProtocolMock(@protocol(MSHttpClientProtocol));
  OCMReject([self.sut.httpClient sendAsync:OCMOCK_ANY method:OCMOCK_ANY headers:OCMOCK_ANY data:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
  __block MSDocumentWrapper *actualDocumentWrapper;
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called."];

  // When
  [MSDataStore readWithPartition:kMSPartitionTest
                      documentId:kMSDocumentIdTest
                    documentType:[NSString class]
               completionHandler:^(MSDocumentWrapper *data) {
                 actualDocumentWrapper = data;
                 [expectation fulfill];
               }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
  XCTAssertNotNil(actualDocumentWrapper);
  XCTAssertNotNil(actualDocumentWrapper.error);
  XCTAssertEqual(actualDocumentWrapper.error.error.domain, kMSACDataStoreErrorDomain);
  XCTAssertEqual(actualDocumentWrapper.error.error.code, MSACDataStoreInvalidClassCode);
  XCTAssertEqualObjects(actualDocumentWrapper.documentId, kMSDocumentIdTest);
}

- (void)testCreateWhenDataModuleDisabled {

  // If
  self.sut.httpClient = OCMProtocolMock(@protocol(MSHttpClientProtocol));
  OCMReject([self.sut.httpClient sendAsync:OCMOCK_ANY method:OCMOCK_ANY headers:OCMOCK_ANY data:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
  __block MSDocumentWrapper *actualDocumentWrapper;
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called."];

  // When
  [self.sut setEnabled:NO];
  [MSDataStore createWithPartition:kMSPartitionTest
                        documentId:kMSDocumentIdTest
                          document:[[MSDictionaryDocument alloc] initFromDictionary:@{}]
                 completionHandler:^(MSDocumentWrapper *data) {
                   actualDocumentWrapper = data;
                   [expectation fulfill];
                 }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
  XCTAssertNotNil(actualDocumentWrapper);
  XCTAssertNotNil(actualDocumentWrapper.error);
  XCTAssertEqual(actualDocumentWrapper.error.error.domain, kMSACErrorDomain);
  XCTAssertEqual(actualDocumentWrapper.error.error.code, MSACDisabledErrorCode);
  XCTAssertEqualObjects(actualDocumentWrapper.documentId, kMSDocumentIdTest);
}

- (void)testReplaceWithPartitionGoldenPath {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Replace with partition completed"];
  id<MSSerializableDocument> mockSerializableDocument = [[MSDictionaryDocument alloc] initFromDictionary:@{}];
  __block BOOL completionHandlerCalled = NO;
  __block MSDocumentWrapper *actualDocumentWrapper;
  MSTokenResult *testToken = [self mockTokenFetchingWithError:nil];

  // Mock CosmosDB requests.
  NSData *testCosmosDbResponse = [self jsonFixture:@"validTestDocument"];
  OCMStub([self.cosmosDbMock performCosmosDbAsyncOperationWithHttpClient:OCMOCK_ANY
                                                             tokenResult:testToken
                                                              documentId:kMSDocumentIdTest
                                                              httpMethod:kMSHttpMethodPost
                                                                document:mockSerializableDocument
                                                       additionalHeaders:OCMOCK_ANY
                                                       additionalUrlPath:OCMOCK_ANY
                                                       completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSHttpRequestCompletionHandler cosmosdbOperationCallback;
        [invocation getArgument:&cosmosdbOperationCallback atIndex:9];
        cosmosdbOperationCallback(testCosmosDbResponse, [self generateResponseWithStatusCode:MSHTTPCodesNo200OK], nil);
      });

  // When
  [MSDataStore createWithPartition:kMSPartitionTest
                        documentId:kMSDocumentIdTest
                          document:mockSerializableDocument
                 completionHandler:^(MSDocumentWrapper *data) {
                   completionHandlerCalled = YES;
                   actualDocumentWrapper = data;
                   [expectation fulfill];
                 }];
  id<MSSerializableDocument> replaceMockSerializableDocument = [[MSDictionaryDocument alloc] initFromDictionary:@{}];
  [MSDataStore replaceWithPartition:kMSPartitionTest
                         documentId:kMSDocumentIdTest
                           document:replaceMockSerializableDocument
                  completionHandler:^(MSDocumentWrapper *data) {
                    completionHandlerCalled = YES;
                    actualDocumentWrapper = data;
                    [expectation fulfill];
                  }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertTrue(completionHandlerCalled);
                                 XCTAssertNotNil(actualDocumentWrapper.deserializedValue);
                                 XCTAssertTrue([[actualDocumentWrapper documentId] isEqualToString:@"standalonedocument1"]);
                                 XCTAssertTrue([[actualDocumentWrapper partition] isEqualToString:@"readonly"]);
                               }];
}

- (void)testReplaceWhenDataModuleDisabled {

  // If
  self.sut.httpClient = OCMProtocolMock(@protocol(MSHttpClientProtocol));
  OCMReject([self.sut.httpClient sendAsync:OCMOCK_ANY method:OCMOCK_ANY headers:OCMOCK_ANY data:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
  __block MSDocumentWrapper *actualDocumentWrapper;
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called."];

  // When
  [self.sut setEnabled:NO];
  [MSDataStore replaceWithPartition:kMSPartitionTest
                         documentId:kMSDocumentIdTest
                           document:[[MSDictionaryDocument alloc] initFromDictionary:@{}]
                  completionHandler:^(MSDocumentWrapper *data) {
                    actualDocumentWrapper = data;
                    [expectation fulfill];
                  }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
  XCTAssertNotNil(actualDocumentWrapper);
  XCTAssertNotNil(actualDocumentWrapper.error);
  XCTAssertEqual(actualDocumentWrapper.error.error.domain, kMSACErrorDomain);
  XCTAssertEqual(actualDocumentWrapper.error.error.code, MSACDisabledErrorCode);
  XCTAssertEqualObjects(actualDocumentWrapper.documentId, kMSDocumentIdTest);
}

- (void)testDeleteWhenDataModuleDisabled {

  // If
  self.sut.httpClient = OCMProtocolMock(@protocol(MSHttpClientProtocol));
  OCMReject([self.sut.httpClient sendAsync:OCMOCK_ANY method:OCMOCK_ANY headers:OCMOCK_ANY data:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
  __block MSDataSourceError *actualDataSourceError;
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called."];

  // When
  [self.sut setEnabled:NO];
  [MSDataStore deleteWithPartition:kMSPartitionTest
                        documentId:kMSDocumentIdTest
                 completionHandler:^(MSDocumentWrapper *wrapper) {
                   actualDataSourceError = wrapper.error;
                   [expectation fulfill];
                 }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
  XCTAssertNotNil(actualDataSourceError);
  XCTAssertNotNil(actualDataSourceError.error);
  XCTAssertEqual(actualDataSourceError.error.domain, kMSACErrorDomain);
  XCTAssertEqual(actualDataSourceError.error.code, MSACDisabledErrorCode);
  XCTAssertEqual(actualDataSourceError.errorCode, MSHTTPCodesNo0XXInvalidUnknown);
}

- (void)testListWhenDataModuleDisabled {

  // If
  self.sut.httpClient = OCMProtocolMock(@protocol(MSHttpClientProtocol));
  OCMReject([self.sut.httpClient sendAsync:OCMOCK_ANY method:OCMOCK_ANY headers:OCMOCK_ANY data:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
  __block MSPaginatedDocuments *actualPaginatedDocuments;
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called."];

  // When
  [self.sut setEnabled:NO];
  [MSDataStore listWithPartition:kMSPartitionTest
                    documentType:[MSDictionaryDocument class]
               completionHandler:^(MSPaginatedDocuments *documents) {
                 actualPaginatedDocuments = documents;
                 [expectation fulfill];
               }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
  XCTAssertNotNil(actualPaginatedDocuments);
  XCTAssertNotNil(actualPaginatedDocuments.currentPage.error);
  XCTAssertNotNil(actualPaginatedDocuments.currentPage.error.error);
  XCTAssertEqual(actualPaginatedDocuments.currentPage.error.error.domain, kMSACErrorDomain);
  XCTAssertEqual(actualPaginatedDocuments.currentPage.error.error.code, MSACDisabledErrorCode);
  XCTAssertEqual(actualPaginatedDocuments.currentPage.error.errorCode, MSHTTPCodesNo0XXInvalidUnknown);
}

- (void)testListWithInvalidDocumentType {

  // If
  self.sut.httpClient = OCMProtocolMock(@protocol(MSHttpClientProtocol));
  OCMReject([self.sut.httpClient sendAsync:OCMOCK_ANY method:OCMOCK_ANY headers:OCMOCK_ANY data:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
  __block MSPaginatedDocuments *actualPaginatedDocuments;
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called."];

  // When
  [MSDataStore listWithPartition:kMSPartitionTest
                    documentType:[NSString class]
               completionHandler:^(MSPaginatedDocuments *documents) {
                 actualPaginatedDocuments = documents;
                 [expectation fulfill];
               }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
  XCTAssertNotNil(actualPaginatedDocuments);
  XCTAssertNotNil(actualPaginatedDocuments.currentPage.error);
  XCTAssertNotNil(actualPaginatedDocuments.currentPage.error.error);
  XCTAssertEqual(actualPaginatedDocuments.currentPage.error.error.domain, kMSACDataStoreErrorDomain);
  XCTAssertEqual(actualPaginatedDocuments.currentPage.error.error.code, MSACDataStoreInvalidClassCode);
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

- (void)testGetCosmosDbErrorWithNilEverything {

  // If
  NSError *error;

  // When
  error = [MSCosmosDb cosmosDbErrorWithResponse:nil underlyingError:nil];

  // Then
  XCTAssertEqualObjects(error.domain, kMSACDataStoreErrorDomain);
  XCTAssertEqual(error.code, MSACDataStoreErrorHTTPError);
  XCTAssertNil(error.userInfo[NSUnderlyingErrorKey]);
  XCTAssertEqualObjects(error.userInfo[kMSCosmosDbHttpCodeKey], @(MSHTTPCodesNo0XXInvalidUnknown));
}

- (void)testGetCosmosDbErrorWithNilResponseAndError {

  // If
  NSError *incomingError = [[NSError alloc] initWithDomain:@"domain" code:0 userInfo:@{}];
  NSError *error;

  // When
  error = [MSCosmosDb cosmosDbErrorWithResponse:nil underlyingError:incomingError];

  // Then
  XCTAssertEqualObjects(error.domain, kMSACDataStoreErrorDomain);
  XCTAssertEqual(error.code, MSACDataStoreErrorHTTPError);
  XCTAssertEqualObjects(error.userInfo[NSUnderlyingErrorKey], incomingError);
  XCTAssertEqualObjects(error.userInfo[kMSCosmosDbHttpCodeKey], @(MSHTTPCodesNo0XXInvalidUnknown));
}

- (void)testGetCosmosDbErrorWithNilResponseAndErrorContainingHTTPCode {

  // If
  NSError *incomingError = [[NSError alloc] initWithDomain:@"domain" code:0 userInfo:@{kMSCosmosDbHttpCodeKey : @(123)}];
  NSError *error;

  // When
  error = [MSCosmosDb cosmosDbErrorWithResponse:nil underlyingError:incomingError];

  // Then
  XCTAssertEqualObjects(error.domain, kMSACDataStoreErrorDomain);
  XCTAssertEqual(error.code, MSACDataStoreErrorHTTPError);
  XCTAssertEqualObjects(error.userInfo[NSUnderlyingErrorKey], incomingError);
  XCTAssertEqualObjects(error.userInfo[kMSCosmosDbHttpCodeKey], @(123));
}

- (void)testGetCosmosDbErrorWithResponseAndNilError {

  // If
  NSError *error;

  // When
  error = [MSCosmosDb cosmosDbErrorWithResponse:[MSHttpTestUtil createMockResponseForStatusCode:400 headers:nil] underlyingError:nil];

  // Then
  XCTAssertEqualObjects(error.domain, kMSACDataStoreErrorDomain);
  XCTAssertEqual(error.code, MSACDataStoreErrorHTTPError);
  XCTAssertNil(error.userInfo[NSUnderlyingErrorKey]);
  XCTAssertEqualObjects(error.userInfo[kMSCosmosDbHttpCodeKey], @(400));
}

- (void)testGetCosmosDbErrorWithResponseAndErrorNotValidScenario {

  // If
  NSError *incomingError = [[NSError alloc] initWithDomain:@"domain" code:0 userInfo:@{kMSCosmosDbHttpCodeKey : @(123)}];
  NSError *error;

  // When
  error = [MSCosmosDb cosmosDbErrorWithResponse:[MSHttpTestUtil createMockResponseForStatusCode:400 headers:nil]
                                underlyingError:incomingError];

  // Then
  XCTAssertEqualObjects(error.domain, kMSACDataStoreErrorDomain);
  XCTAssertEqual(error.code, MSACDataStoreErrorHTTPError);
  XCTAssertEqualObjects(error.userInfo[NSUnderlyingErrorKey], incomingError);
  XCTAssertEqualObjects(error.userInfo[kMSCosmosDbHttpCodeKey], @(400));
}

- (void)testDocumentUrlWithUnecnodedDocumentId {

  // If
  MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithDictionary:[self prepareMutableDictionary]];

  // When
  NSString *testDocumentUnencoded = @"Test Document";
  NSString *testDocumentEncoded = @"Test%20Document";
  NSString *testResult = [MSCosmosDb documentUrlWithTokenResult:tokenResult documentId:testDocumentUnencoded];

  // Then
  XCTAssertNotNil(testResult);
  XCTAssertFalse([testResult containsString:testDocumentUnencoded]);
  XCTAssertTrue([testResult containsString:testDocumentEncoded]);
}

- (void)testPerformCosmosDbAsyncOperationWithHttpClientWithAdditionalParams {

  // If
  MSHttpClient *httpClient = OCMClassMock([MSHttpClient class]);
  MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithDictionary:[self prepareMutableDictionary]];
  __block BOOL completionHandlerCalled = NO;
  MSHttpRequestCompletionHandler handler =
      ^(NSData *_Nullable __unused responseBody, NSHTTPURLResponse *_Nullable __unused response, NSError *_Nullable __unused error) {
        completionHandlerCalled = YES;
      };
  NSString *expectedURLString = @"https://dbAccount.documents.azure.com/dbs/dbName/colls/dbCollectionName/docs/documentId";
  __block NSURL *actualURL;
  __block NSData *actualData;
  OCMStub([httpClient sendAsync:OCMOCK_ANY method:OCMOCK_ANY headers:OCMOCK_ANY data:OCMOCK_ANY completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSHttpRequestCompletionHandler completionHandler;
        [invocation retainArguments];
        [invocation getArgument:&actualURL atIndex:2];
        [invocation getArgument:&actualData atIndex:5];
        [invocation getArgument:&completionHandler atIndex:6];
        completionHandler(actualData, nil, nil);
      });
  NSMutableDictionary *additionalHeaders = [NSMutableDictionary new];
  additionalHeaders[@"Foo"] = @"Bar";
  NSDictionary *dic = @{@"abv" : @1, @"foo" : @"bar"};

  MSDictionaryDocument *mockDoc = [[MSDictionaryDocument alloc] initFromDictionary:dic];
  __block NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:0 error:nil];

  // When

  [MSCosmosDb performCosmosDbAsyncOperationWithHttpClient:httpClient
                                              tokenResult:tokenResult
                                               documentId:kMSDocumentIdTest
                                               httpMethod:kMSHttpMethodGet
                                                 document:mockDoc
                                        additionalHeaders:additionalHeaders
                                        additionalUrlPath:kMSDocumentIdTest
                                        completionHandler:handler];
  NSError *error;
  NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:(NSData *)actualData options:0 error:&error];
  NSDictionary *document = dictionary[@"document"];
  NSData *actualDocumentAsData = [NSJSONSerialization dataWithJSONObject:document options:0 error:nil];

  // Then
  XCTAssertTrue(completionHandlerCalled);
  XCTAssertEqualObjects(data, actualDocumentAsData);
  XCTAssertEqualObjects(expectedURLString, [actualURL absoluteString]);
}

- (void)testPerformCosmosDbAsyncOperationWithHttpClient {

  // If
  MSHttpClient *httpClient = OCMClassMock([MSHttpClient class]);
  MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithDictionary:[self prepareMutableDictionary]];
  __block BOOL completionHandlerCalled = NO;
  MSHttpRequestCompletionHandler handler =
      ^(NSData *_Nullable __unused responseBody, NSHTTPURLResponse *_Nullable __unused response, NSError *_Nullable __unused error) {
        completionHandlerCalled = YES;
      };
  NSString *expectedURLString = @"https://dbAccount.documents.azure.com/dbs/dbName/colls/dbCollectionName/docs/documentId";
  __block NSURL *actualURL;
  __block NSData *actualData;
  OCMStub([httpClient sendAsync:OCMOCK_ANY method:OCMOCK_ANY headers:OCMOCK_ANY data:OCMOCK_ANY completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSHttpRequestCompletionHandler completionHandler;
        [invocation retainArguments];
        [invocation getArgument:&actualURL atIndex:2];
        [invocation getArgument:&actualData atIndex:5];
        [invocation getArgument:&completionHandler atIndex:6];
        completionHandler(actualData, nil, nil);
      });
  NSDictionary *dic = @{@"abv" : @1, @"foo" : @"bar"};
  MSDictionaryDocument *mockDoc = [[MSDictionaryDocument alloc] initFromDictionary:dic];
  __block NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:0 error:nil];

  // When
  [MSCosmosDb performCosmosDbAsyncOperationWithHttpClient:httpClient
                                              tokenResult:tokenResult
                                               documentId:kMSDocumentIdTest
                                               httpMethod:kMSHttpMethodGet
                                                 document:mockDoc
                                        additionalHeaders:nil
                                        additionalUrlPath:kMSDocumentIdTest
                                        completionHandler:handler];

  NSError *error;
  NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:(NSData *)actualData options:0 error:&error];
  NSDictionary *document = dictionary[@"document"];
  NSData *actualDocumentAsData = [NSJSONSerialization dataWithJSONObject:document options:0 error:nil];

  // Then
  XCTAssertTrue(completionHandlerCalled);
  XCTAssertEqualObjects(data, actualDocumentAsData);
  XCTAssertEqualObjects(expectedURLString, [actualURL absoluteString]);
}

- (void)testPerformCosmosDbAsyncOperationWithNilDocument {

  // If
  MSHttpClient *httpClient = OCMClassMock([MSHttpClient class]);
  MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithDictionary:[self prepareMutableDictionary]];
  __block BOOL completionHandlerCalled = NO;
  __block NSData *actualDataHttpData;
  MSHttpRequestCompletionHandler handler =
      ^(NSData *_Nullable responseBody, NSHTTPURLResponse *_Nullable __unused response, NSError *_Nullable __unused error) {
        completionHandlerCalled = YES;
        actualDataHttpData = responseBody;
      };

  NSString *expectedURLString = @"https://dbAccount.documents.azure.com/dbs/dbName/colls/dbCollectionName/docs/documentId";
  __block NSURL *actualURL;
  __block NSData *actualData;
  OCMStub([httpClient sendAsync:OCMOCK_ANY method:OCMOCK_ANY headers:OCMOCK_ANY data:OCMOCK_ANY completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSHttpRequestCompletionHandler completionHandler;
        [invocation retainArguments];
        [invocation getArgument:&actualURL atIndex:2];
        [invocation getArgument:&actualData atIndex:5];
        [invocation getArgument:&completionHandler atIndex:6];
        completionHandler(actualData, nil, nil);
      });
  MSDictionaryDocument *mockDoc = nil;

  // When
  [MSCosmosDb performCosmosDbAsyncOperationWithHttpClient:httpClient
                                              tokenResult:tokenResult
                                               documentId:kMSDocumentIdTest
                                               httpMethod:kMSHttpMethodGet
                                                 document:mockDoc
                                        additionalHeaders:nil
                                        additionalUrlPath:kMSDocumentIdTest
                                        completionHandler:handler];
  // Then
  XCTAssertTrue(completionHandlerCalled);
  XCTAssertEqualObjects(nil, actualDataHttpData);
  XCTAssertEqualObjects(expectedURLString, [actualURL absoluteString]);
}

- (void)testPerformCosmosDbAsyncOperationWithValidDocument {

  // If
  MSHttpClient *httpClient = OCMClassMock([MSHttpClient class]);
  MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithDictionary:[self prepareMutableDictionary]];
  __block BOOL completionHandlerCalled = NO;
  __block NSData *actualDataHttpData;
  MSHttpRequestCompletionHandler handler =
      ^(NSData *_Nullable responseBody, NSHTTPURLResponse *_Nullable __unused response, NSError *_Nullable __unused error) {
        completionHandlerCalled = YES;
        actualDataHttpData = responseBody;
      };
  NSString *expectedURLString = @"https://dbAccount.documents.azure.com/dbs/dbName/colls/dbCollectionName/docs/documentId";
  __block NSURL *actualURL;
  __block NSData *actualData;
  OCMStub([httpClient sendAsync:OCMOCK_ANY method:OCMOCK_ANY headers:OCMOCK_ANY data:OCMOCK_ANY completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSHttpRequestCompletionHandler completionHandler;
        [invocation retainArguments];
        [invocation getArgument:&actualURL atIndex:2];
        [invocation getArgument:&actualData atIndex:5];
        [invocation getArgument:&completionHandler atIndex:6];
        completionHandler(actualData, nil, nil);
      });
  NSDictionary *dic = @{@"foo" : @"bar"};
  __block NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:0 error:nil];
  MSDictionaryDocument *mockDoc = [[MSDictionaryDocument alloc] initFromDictionary:dic];

  // When
  [MSCosmosDb performCosmosDbAsyncOperationWithHttpClient:httpClient
                                              tokenResult:tokenResult
                                               documentId:kMSDocumentIdTest
                                               httpMethod:kMSHttpMethodGet
                                                 document:mockDoc
                                        additionalHeaders:nil
                                        additionalUrlPath:kMSDocumentIdTest
                                        completionHandler:handler];
  NSError *error;
  NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:(NSData *)actualDataHttpData options:0 error:&error];
  NSDictionary *document = dictionary[@"document"];
  NSData *actualDocumentAsData = [NSJSONSerialization dataWithJSONObject:document options:0 error:nil];

  // Then
  XCTAssertTrue(completionHandlerCalled);
  XCTAssertNotNil(actualDataHttpData);
  XCTAssertEqualObjects(actualDocumentAsData, data);
  XCTAssertEqualObjects(expectedURLString, [actualURL absoluteString]);
}

- (void)testPerformCosmosDbAsyncOperationWithUnserializableDocument {

  // If
  MSHttpClient *httpClient = OCMClassMock([MSHttpClient class]);
  MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithDictionary:[self prepareMutableDictionary]];
  __block BOOL completionHandlerCalled = NO;
  __block NSData *actualResponseBody;
  __block NSHTTPURLResponse *actualResponse;
  __block NSError *actualError;
  NSErrorDomain expectedErrorDomain = kMSACDataStoreErrorDomain;
  NSInteger expectedErrorCode = MSACDataStoreErrorJSONSerializationFailed;

  NSMutableDictionary *dic = [NSMutableDictionary new];
  dic[@"shouldFail"] = [NSSet set];
  MSDictionaryDocument *mockDoc = [[MSDictionaryDocument alloc] initFromDictionary:dic];

  // When
  [MSCosmosDb performCosmosDbAsyncOperationWithHttpClient:httpClient
                                              tokenResult:tokenResult
                                               documentId:kMSDocumentIdTest
                                               httpMethod:kMSHttpMethodGet
                                                 document:mockDoc
                                        additionalHeaders:nil
                                        additionalUrlPath:kMSDocumentIdTest
                                        completionHandler:^(NSData *_Nullable responseBody, NSHTTPURLResponse *_Nullable __unused response,
                                                            NSError *_Nullable __unused error) {
                                          completionHandlerCalled = YES;
                                          actualResponseBody = responseBody;
                                          actualResponse = response;
                                          actualError = error;
                                        }];

  // Then
  XCTAssertTrue(completionHandlerCalled);
  XCTAssertNil(actualResponseBody);
  XCTAssertNil(actualResponse);
  XCTAssertNotNil(actualError);
  XCTAssertEqual(actualError.domain, expectedErrorDomain);
  XCTAssertEqual(actualError.code, expectedErrorCode);
}

- (void)testPerformCosmosDbAsyncOperationWithNilDocumentId {

  // If
  MSHttpClient *httpClient = OCMClassMock([MSHttpClient class]);
  MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithDictionary:[self prepareMutableDictionary]];
  __block BOOL completionHandlerCalled = NO;
  __block NSData *actualDataHttpData;
  __block NSError *blockError;
  MSHttpRequestCompletionHandler handler =
      ^(NSData *_Nullable responseBody, NSHTTPURLResponse *_Nullable __unused response, NSError *_Nullable error) {
        completionHandlerCalled = YES;
        actualDataHttpData = responseBody;
        blockError = error;
      };
  __block NSURL *actualURL;
  __block NSData *actualData;
  OCMStub([httpClient sendAsync:OCMOCK_ANY method:OCMOCK_ANY headers:OCMOCK_ANY data:OCMOCK_ANY completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSHttpRequestCompletionHandler completionHandler;
        [invocation retainArguments];
        [invocation getArgument:&actualURL atIndex:2];
        [invocation getArgument:&actualData atIndex:5];
        [invocation getArgument:&completionHandler atIndex:6];
        completionHandler(actualData, nil, nil);
      });
  NSDictionary *dic = @{@"foo" : @"bar"};
  MSDictionaryDocument *mockDoc = [[MSDictionaryDocument alloc] initFromDictionary:dic];

  // When
  [MSCosmosDb performCosmosDbAsyncOperationWithHttpClient:httpClient
                                              tokenResult:tokenResult
                                               documentId:nil
                                               httpMethod:kMSHttpMethodGet
                                                 document:mockDoc
                                        additionalHeaders:nil
                                        additionalUrlPath:kMSDocumentIdTest
                                        completionHandler:handler];

  // Then
  XCTAssertTrue(completionHandlerCalled);
  XCTAssertNil(actualDataHttpData);
  XCTAssertEqual(blockError.code, MSACDataStoreDocumentIdError);
}

- (void)testCreateWithPartitionGoldenPath {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Create with partition completed"];
  id<MSSerializableDocument> mockSerializableDocument = [[MSDictionaryDocument alloc] initFromDictionary:@{}];
  __block BOOL completionHandlerCalled = NO;
  __block MSDocumentWrapper *actualDocumentWrapper;
  MSTokenResult *testToken = [self mockTokenFetchingWithError:nil];

  // Mock CosmosDB requests.
  NSData *testCosmosDbResponse = [self jsonFixture:@"validTestDocument"];
  OCMStub([self.cosmosDbMock performCosmosDbAsyncOperationWithHttpClient:OCMOCK_ANY
                                                             tokenResult:testToken
                                                              documentId:kMSDocumentIdTest
                                                              httpMethod:kMSHttpMethodPost
                                                                document:mockSerializableDocument
                                                       additionalHeaders:OCMOCK_ANY
                                                       additionalUrlPath:OCMOCK_ANY
                                                       completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSHttpRequestCompletionHandler cosmosdbOperationCallback;
        [invocation getArgument:&cosmosdbOperationCallback atIndex:9];
        cosmosdbOperationCallback(testCosmosDbResponse, [self generateResponseWithStatusCode:MSHTTPCodesNo200OK], nil);
      });

  // When
  [MSDataStore createWithPartition:kMSPartitionTest
                        documentId:kMSDocumentIdTest
                          document:mockSerializableDocument
                 completionHandler:^(MSDocumentWrapper *data) {
                   completionHandlerCalled = YES;
                   actualDocumentWrapper = data;
                   [expectation fulfill];
                 }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertTrue(completionHandlerCalled);
                                 XCTAssertNotNil(actualDocumentWrapper.deserializedValue);
                                 XCTAssertTrue([[actualDocumentWrapper documentId] isEqualToString:@"standalonedocument1"]);
                                 XCTAssertTrue([[actualDocumentWrapper partition] isEqualToString:@"readonly"]);
                               }];
}

- (void)testCreateWithPartitionWhenTokenExchangeFails {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Create with partition completed"];
  id<MSSerializableDocument> mockSerializableDocument = [[MSDictionaryDocument alloc] initFromDictionary:@{}];
  __block BOOL completionHandlerCalled = NO;
  NSError *expectedTokenExchangeError = [NSError errorWithDomain:kMSACErrorDomain code:0 userInfo:@{kMSCosmosDbHttpCodeKey : @(0)}];
  __block MSDataSourceError *actualError;
  [self mockTokenFetchingWithError:expectedTokenExchangeError];

  // When
  [MSDataStore createWithPartition:kMSPartitionTest
                        documentId:kMSDocumentIdTest
                          document:mockSerializableDocument
                 completionHandler:^(MSDocumentWrapper *data) {
                   completionHandlerCalled = YES;
                   actualError = data.error;
                   [expectation fulfill];
                 }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertTrue(completionHandlerCalled);
                                 XCTAssertEqualObjects(actualError.error.domain, kMSACDataStoreErrorDomain);
                                 XCTAssertEqual(actualError.error.code, MSACDataStoreLocalStoreError);
                               }];
}

- (void)testCreateWithPartitionWhenCreationFails {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Create with partition completed"];
  id<MSSerializableDocument> mockSerializableDocument = [[MSDictionaryDocument alloc] initFromDictionary:@{}];
  __block BOOL completionHandlerCalled = NO;
  NSInteger expectedResponseCode = MSHTTPCodesNo500InternalServerError;
  NSError *expectedCosmosDbError = [NSError errorWithDomain:kMSACErrorDomain
                                                       code:0
                                                   userInfo:@{kMSCosmosDbHttpCodeKey : @(expectedResponseCode)}];
  __block MSDataSourceError *actualError;
  MSTokenResult *testToken = [self mockTokenFetchingWithError:nil];

  // Mock CosmosDB requests.
  OCMStub([self.cosmosDbMock performCosmosDbAsyncOperationWithHttpClient:OCMOCK_ANY
                                                             tokenResult:testToken
                                                              documentId:kMSDocumentIdTest
                                                              httpMethod:kMSHttpMethodPost
                                                                document:mockSerializableDocument
                                                       additionalHeaders:OCMOCK_ANY
                                                       additionalUrlPath:OCMOCK_ANY
                                                       completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSHttpRequestCompletionHandler cosmosdbOperationCallback;
        [invocation getArgument:&cosmosdbOperationCallback atIndex:9];
        cosmosdbOperationCallback(nil, nil, expectedCosmosDbError);
      });

  // When
  [MSDataStore createWithPartition:kMSPartitionTest
                        documentId:kMSDocumentIdTest
                          document:mockSerializableDocument
                 completionHandler:^(MSDocumentWrapper *data) {
                   completionHandlerCalled = YES;
                   actualError = data.error;
                   [expectation fulfill];
                 }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertTrue(completionHandlerCalled);
                                 XCTAssertEqualObjects(actualError.error.domain, kMSACDataStoreErrorDomain);
                                 XCTAssertEqual(actualError.error.code, MSACDataStoreErrorHTTPError);
                                 XCTAssertEqualObjects(actualError.error.userInfo[NSUnderlyingErrorKey], expectedCosmosDbError);
                                 XCTAssertEqualObjects(actualError.error.userInfo[kMSCosmosDbHttpCodeKey],
                                                       @(MSHTTPCodesNo500InternalServerError));
                                 XCTAssertEqual(actualError.errorCode, expectedResponseCode);
                               }];
}

- (void)testCreateWithPartitionWhenSerializationFails {

  // If
  NSMutableDictionary *dictionary = [NSMutableDictionary new];
  dictionary[@"shouldFail"] = [NSSet set];
  id<MSSerializableDocument> mockSerializableDocument = [[MSDictionaryDocument alloc] initFromDictionary:dictionary];
  __block BOOL completionHandlerCalled = NO;
  NSErrorDomain expectedErrorDomain = kMSACDataStoreErrorDomain;
  NSInteger expectedErrorCode = MSACDataStoreErrorJSONSerializationFailed;
  __block MSDataSourceError *actualError;

  XCTestExpectation *expectation = [self expectationWithDescription:@"Create with partition completes with error."];
  MSTokenResult *testToken = [self mockTokenFetchingWithError:nil];

  // Mock CosmosDB requests.
  OCMStub([self.cosmosDbMock performCosmosDbAsyncOperationWithHttpClient:OCMOCK_ANY
                                                             tokenResult:testToken
                                                              documentId:kMSDocumentIdTest
                                                              httpMethod:kMSHttpMethodPost
                                                                document:mockSerializableDocument
                                                       additionalHeaders:OCMOCK_ANY
                                                       additionalUrlPath:OCMOCK_ANY
                                                       completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSHttpRequestCompletionHandler cosmosdbOperationCallback;
        [invocation getArgument:&cosmosdbOperationCallback atIndex:9];
        cosmosdbOperationCallback(nil, [self generateResponseWithStatusCode:MSHTTPCodesNo200OK], nil);
      });

  // When
  [MSDataStore createWithPartition:kMSPartitionTest
                        documentId:kMSDocumentIdTest
                          document:mockSerializableDocument
                 completionHandler:^(MSDocumentWrapper *data) {
                   completionHandlerCalled = YES;
                   actualError = data.error;
                   [expectation fulfill];
                 }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertTrue(completionHandlerCalled);
                                 XCTAssertNotNil(actualError);
                                 XCTAssertNotNil(actualError.error);
                                 XCTAssertEqual(actualError.error.domain, expectedErrorDomain);
                                 XCTAssertEqual(actualError.error.code, expectedErrorCode);
                               }];
}

- (void)testCreateWithPartitionWhenDeserializationFails {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Create with partition completed"];
  id<MSSerializableDocument> mockSerializableDocument = [[MSDictionaryDocument alloc] initFromDictionary:@{}];
  __block BOOL completionHandlerCalled = NO;
  NSErrorDomain expectedErrorDomain = NSCocoaErrorDomain;
  NSInteger expectedErrorCode = 3840;
  __block MSDataSourceError *actualError;
  MSTokenResult *testToken = [self mockTokenFetchingWithError:nil];

  // Mock CosmosDB requests.
  NSData *brokenCosmosDbResponse = [@"<h1>502 Bad Gateway</h1><p>nginx</p>" dataUsingEncoding:NSUTF8StringEncoding];
  OCMStub([self.cosmosDbMock performCosmosDbAsyncOperationWithHttpClient:OCMOCK_ANY
                                                             tokenResult:testToken
                                                              documentId:kMSDocumentIdTest
                                                              httpMethod:kMSHttpMethodPost
                                                                document:mockSerializableDocument
                                                       additionalHeaders:OCMOCK_ANY
                                                       additionalUrlPath:OCMOCK_ANY
                                                       completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSHttpRequestCompletionHandler cosmosdbOperationCallback;
        [invocation getArgument:&cosmosdbOperationCallback atIndex:9];
        cosmosdbOperationCallback(brokenCosmosDbResponse, [self generateResponseWithStatusCode:MSHTTPCodesNo200OK], nil);
      });

  // When
  [MSDataStore createWithPartition:kMSPartitionTest
                        documentId:kMSDocumentIdTest
                          document:mockSerializableDocument
                 completionHandler:^(MSDocumentWrapper *data) {
                   completionHandlerCalled = YES;
                   actualError = data.error;
                   [expectation fulfill];
                 }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertTrue(completionHandlerCalled);
                                 XCTAssertEqual(actualError.error.domain, expectedErrorDomain);
                                 XCTAssertEqual(actualError.error.code, expectedErrorCode);
                               }];
}

- (void)testDeleteDocumentWithPartitionGoldenPath {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Delete with partition completed"];
  __block BOOL completionHandlerCalled = NO;
  NSInteger expectedResponseCode = MSHTTPCodesNo200OK;
  __block NSInteger actualResponseCode;
  MSTokenResult *testToken = [self mockTokenFetchingWithError:nil];
  OCMStub([self.cosmosDbMock performCosmosDbAsyncOperationWithHttpClient:OCMOCK_ANY
                                                             tokenResult:testToken
                                                              documentId:kMSDocumentIdTest
                                                              httpMethod:kMSHttpMethodDelete
                                                                document:OCMOCK_ANY
                                                       additionalHeaders:OCMOCK_ANY
                                                       additionalUrlPath:OCMOCK_ANY
                                                       completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSHttpRequestCompletionHandler cosmosdbOperationCallback;
        [invocation getArgument:&cosmosdbOperationCallback atIndex:9];
        cosmosdbOperationCallback(nil, [self generateResponseWithStatusCode:MSHTTPCodesNo200OK], nil);
      });

  // When
  [MSDataStore deleteWithPartition:kMSPartitionTest
                        documentId:kMSDocumentIdTest
                 completionHandler:^(MSDocumentWrapper *wrapper) {
                   completionHandlerCalled = YES;
                   actualResponseCode = wrapper.error.errorCode;
                   [expectation fulfill];
                 }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertTrue(completionHandlerCalled);
                                 XCTAssertEqual(actualResponseCode, expectedResponseCode);
                               }];
}

- (void)testDeleteDocumentWithPartitionWhenTokenExchangeFails {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Delete with partition completed"];
  __block BOOL completionHandlerCalled = NO;
  NSError *expectedTokenExchangeError = [NSError errorWithDomain:kMSACErrorDomain code:0 userInfo:@{kMSCosmosDbHttpCodeKey : @0}];
  __block MSDataSourceError *actualError;
  [self mockTokenFetchingWithError:expectedTokenExchangeError];

  // When
  [MSDataStore deleteWithPartition:kMSPartitionTest
                        documentId:kMSDocumentIdTest
                 completionHandler:^(MSDocumentWrapper *wrapper) {
                   completionHandlerCalled = YES;
                   actualError = wrapper.error;
                   [expectation fulfill];
                 }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertTrue(completionHandlerCalled);
                                 XCTAssertEqualObjects(actualError.error.domain, kMSACDataStoreErrorDomain);
                                 XCTAssertEqual(actualError.error.code, MSACDataStoreLocalStoreError);
                               }];
}

- (void)testDeleteDocumentWithPartitionWhenDeletionFails {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Delete with partition completed"];
  __block BOOL completionHandlerCalled = NO;
  NSInteger expectedResponseCode = MSHTTPCodesNo500InternalServerError;
  NSError *expectedCosmosDbError = [NSError errorWithDomain:kMSACErrorDomain
                                                       code:0
                                                   userInfo:@{kMSCosmosDbHttpCodeKey : @(expectedResponseCode)}];
  __block MSDataSourceError *actualError;
  MSTokenResult *testToken = [self mockTokenFetchingWithError:nil];

  // Mock CosmosDB requests.
  OCMStub([self.cosmosDbMock performCosmosDbAsyncOperationWithHttpClient:OCMOCK_ANY
                                                             tokenResult:testToken
                                                              documentId:kMSDocumentIdTest
                                                              httpMethod:kMSHttpMethodDelete
                                                                document:OCMOCK_ANY
                                                       additionalHeaders:OCMOCK_ANY
                                                       additionalUrlPath:OCMOCK_ANY
                                                       completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSHttpRequestCompletionHandler cosmosdbOperationCallback;
        [invocation getArgument:&cosmosdbOperationCallback atIndex:9];
        cosmosdbOperationCallback(nil, nil, expectedCosmosDbError);
      });

  // When
  [MSDataStore deleteWithPartition:kMSPartitionTest
                        documentId:kMSDocumentIdTest
                 completionHandler:^(MSDocumentWrapper *wrapper) {
                   completionHandlerCalled = YES;
                   actualError = wrapper.error;
                   [expectation fulfill];
                 }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertTrue(completionHandlerCalled);
                                 XCTAssertEqualObjects(actualError.error.domain, kMSACDataStoreErrorDomain);
                                 XCTAssertEqual(actualError.error.code, MSACDataStoreErrorHTTPError);
                                 XCTAssertEqualObjects(actualError.error.userInfo[NSUnderlyingErrorKey], expectedCosmosDbError);
                                 XCTAssertEqualObjects(actualError.error.userInfo[kMSCosmosDbHttpCodeKey],
                                                       @(MSHTTPCodesNo500InternalServerError));
                                 XCTAssertEqual(actualError.errorCode, expectedResponseCode);
                               }];
}

- (void)testSetTokenExchangeUrl {

  // If we change the default token URL.
  NSString *expectedUrl = @"https://another.domain.com";
  [MSDataStore setTokenExchangeUrl:expectedUrl];
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Make any API call"];
  __block NSURL *actualUrl;
  OCMStub([self.tokenExchangeMock performDbTokenAsyncOperationWithHttpClient:OCMOCK_ANY
                                                            tokenExchangeUrl:OCMOCK_ANY
                                                                   appSecret:OCMOCK_ANY
                                                                   partition:OCMOCK_ANY
                                                         includeExpiredToken:YES
                                                                reachability:OCMOCK_ANY
                                                           completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&actualUrl atIndex:3];
        [expectation fulfill];
      });

  // When doing any API call, it will request a token.
  [MSDataStore deleteWithPartition:kMSPartitionTest
                        documentId:kMSDocumentIdTest
                 completionHandler:^(__unused MSDocumentWrapper *wrapper){
                 }];

  // Then that call uses the base URL we specified.
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 } else {
                                   XCTAssertEqualObjects([actualUrl scheme], @"https");
                                   XCTAssertEqualObjects([actualUrl host], @"another.domain.com");
                                 }
                               }];
}

- (void)testListSingleDocument {

  // If
  id httpClient = OCMClassMock([MSHttpClient class]);
  OCMStub([httpClient new]).andReturn(httpClient);
  self.sut.httpClient = httpClient;
  id msTokenEchange = OCMClassMock([MSTokenExchange class]);
  OCMStub([msTokenEchange retrieveCachedTokenForPartition:[OCMArg any] includeExpiredToken:NO])
      .andReturn([[MSTokenResult alloc] initWithDictionary:[self prepareMutableDictionary]]);
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"List single document"];

  OCMStub([httpClient sendAsync:OCMOCK_ANY method:@"GET" headers:OCMOCK_ANY data:nil completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        [invocation retainArguments];
        MSHttpRequestCompletionHandler completionHandler;
        [invocation getArgument:&completionHandler atIndex:6];
        NSData *payload = [self jsonFixture:@"oneDocumentPage"];
        completionHandler(payload, [MSHttpTestUtil createMockResponseForStatusCode:200 headers:nil], nil);
      });

  // When
  __block MSPaginatedDocuments *testDocuments;
  [self.sut listWithPartition:@"user"
                 documentType:[MSDictionaryDocument class]
            continuationToken:nil
            completionHandler:^(MSPaginatedDocuments *_Nonnull documents) {
              testDocuments = documents;
              [expectation fulfill];
            }];

  // Then
  id handler = ^(NSError *_Nullable error) {
    if (error) {
      XCTFail(@"Expectation Failed with error: %@", error);
    } else {
      XCTAssertNotNil(testDocuments);
      XCTAssertFalse([testDocuments hasNextPage]);
      XCTAssertEqual([[testDocuments currentPage] items].count, 1);
      MSDocumentWrapper<MSDictionaryDocument *> *documentWrapper = [[testDocuments currentPage] items][0];
      XCTAssertTrue([[documentWrapper documentId] isEqualToString:@"doc1"]);
      XCTAssertNil([documentWrapper error]);
      XCTAssertNotNil([documentWrapper jsonValue]);
      XCTAssertTrue([[documentWrapper eTag] isEqualToString:@"etag value"]);
      XCTAssertTrue([[documentWrapper partition] isEqualToString:@"partition"]);
      XCTAssertNotNil([documentWrapper lastUpdatedDate]);
      MSDictionaryDocument *deserializedDocument = [documentWrapper deserializedValue];
      NSDictionary *resultDictionary = [deserializedDocument serializeToDictionary];
      XCTAssertNotNil(deserializedDocument);
      XCTAssertTrue([resultDictionary[@"property1"] isEqualToString:@"property 1 string"]);
      XCTAssertTrue([resultDictionary[@"property2"] isEqual:@42]);
    }
  };
  [self waitForExpectationsWithTimeout:1 handler:handler];
  expectation = [self expectationWithDescription:@"Get extra page"];
  __block MSPage *testPage;
  [testDocuments nextPageWithCompletionHandler:^(MSPage *page) {
    testPage = page;
    [expectation fulfill];
  }];
  handler = ^(NSError *_Nullable error) {
    if (error) {
      XCTFail(@"Expectation Failed with error: %@", error);
    } else {
      XCTAssertNil(testPage);
    }
  };
  [self waitForExpectationsWithTimeout:1 handler:handler];
  [httpClient stopMocking];
}

- (void)testListPagination {

  // If
  id httpClient = OCMClassMock([MSHttpClient class]);
  OCMStub([httpClient new]).andReturn(httpClient);
  self.sut.httpClient = httpClient;
  id msTokenEchange = OCMClassMock([MSTokenExchange class]);
  MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithDictionary:[self prepareMutableDictionary]];
  OCMStub([msTokenEchange retrieveCachedTokenForPartition:[OCMArg any] includeExpiredToken:NO]).andReturn(tokenResult);
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"List first page"];
  NSMutableDictionary *continuationHeaders = [NSMutableDictionary new];
  continuationHeaders[@"x-ms-continuation"] = @"continuation token";

  // First page
  NSDictionary *firstPageHeaders = [MSCosmosDb defaultHeaderWithPartition:tokenResult.partition dbToken:kMSTokenTest additionalHeaders:nil];
  OCMStub([httpClient sendAsync:OCMOCK_ANY method:@"GET" headers:firstPageHeaders data:nil completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        [invocation retainArguments];
        MSHttpRequestCompletionHandler completionHandler;
        [invocation getArgument:&completionHandler atIndex:6];
        NSData *payload = [self jsonFixture:@"oneDocumentPage"];
        completionHandler(payload, [MSHttpTestUtil createMockResponseForStatusCode:200 headers:continuationHeaders], nil);
      });

  // Second page
  NSDictionary *secondPageHeaders = [MSCosmosDb defaultHeaderWithPartition:tokenResult.partition
                                                                   dbToken:kMSTokenTest
                                                         additionalHeaders:continuationHeaders];
  OCMStub([httpClient sendAsync:OCMOCK_ANY method:@"GET" headers:secondPageHeaders data:nil completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        [invocation retainArguments];
        MSHttpRequestCompletionHandler completionHandler;
        [invocation getArgument:&completionHandler atIndex:6];
        NSData *payload = [self jsonFixture:@"zeroDocumentsPage"];
        completionHandler(payload, [MSHttpTestUtil createMockResponseForStatusCode:200 headers:nil], nil);
      });

  // When
  __block MSPaginatedDocuments *testDocuments;
  [self.sut listWithPartition:@"user"
                 documentType:[MSDictionaryDocument class]
            continuationToken:nil
            completionHandler:^(MSPaginatedDocuments *_Nonnull documents) {
              testDocuments = documents;
              [expectation fulfill];
            }];

  // Then
  id handler = ^(NSError *_Nullable error) {
    if (error) {
      XCTFail(@"Expectation Failed with error: %@", error);
    } else {
      XCTAssertNotNil(testDocuments);
      XCTAssertEqual([[testDocuments currentPage] items].count, 1);
      XCTAssertTrue([testDocuments hasNextPage]);
    }
  };
  [self waitForExpectationsWithTimeout:3 handler:handler];
  expectation = [self expectationWithDescription:@"List second page"];
  __block MSPage *testPage;
  [testDocuments nextPageWithCompletionHandler:^(MSPage *page) {
    testPage = page;
    [expectation fulfill];
  }];
  handler = ^(NSError *_Nullable error) {
    if (error) {
      XCTFail(@"Expectation Failed with error: %@", error);
    } else {
      XCTAssertFalse([testDocuments hasNextPage]);
      XCTAssertEqual([[testDocuments currentPage] items].count, 0);
      XCTAssertEqual([testPage items].count, 0);
      XCTAssertEqualObjects(testPage, [testDocuments currentPage]);
    }
  };
  [self waitForExpectationsWithTimeout:3 handler:handler];
  [httpClient stopMocking];
}

- (void)testReturnsUserDocumentFromLocalStorageWhenOffline {

  // If
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@""];

  // Simulate being offline.
  MS_Reachability *reachabilityMock = OCMPartialMock([MS_Reachability reachabilityForInternetConnection]);
  OCMStub([reachabilityMock currentReachabilityStatus]).andReturn(NotReachable);
  self.sut.dataOperationProxy.reachability = reachabilityMock;

  // Mock cached token result.
  MSTokenResult *tokenResult = [self mockTokenFetchingWithError:nil];

  // Mock local storage.
  id<MSDocumentStore> localStorageMock = OCMProtocolMock(@protocol(MSDocumentStore));
  self.sut.dataOperationProxy.documentStore = localStorageMock;
  MSDocumentWrapper *expectedDocument = [MSDocumentWrapper new];
  OCMStub([localStorageMock readWithToken:tokenResult documentId:OCMOCK_ANY documentType:OCMOCK_ANY]).andReturn(expectedDocument);

  // When
  [MSDataStore readWithPartition:kMSPartitionTest
                      documentId:@"4"
                    documentType:[MSDictionaryDocument class]
               completionHandler:^(MSDocumentWrapper *_Nonnull document) {
                 // Then
                 XCTAssertEqual(expectedDocument, document);
                 [expectation fulfill];
               }];

  // Then
  [self waitForExpectationsWithTimeout:3
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testReadErrorIfNoTokenResultCachedAndReadingFromLocalStorageAndOffline {

  // If
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@""];

  // Simulate being offline.
  MS_Reachability *reachabilityMock = OCMPartialMock([MS_Reachability reachabilityForInternetConnection]);
  OCMStub([reachabilityMock currentReachabilityStatus]).andReturn(NotReachable);
  self.sut.dataOperationProxy.reachability = reachabilityMock;

  // When
  [MSDataStore readWithPartition:kMSPartitionTest
                      documentId:@"4"
                    documentType:[MSDictionaryDocument class]
               completionHandler:^(MSDocumentWrapper *_Nonnull document) {
                 // Then
                 XCTAssertNotNil(document.error);
                 XCTAssertEqualObjects(document.error.error.domain, kMSACDataStoreErrorDomain);
                 XCTAssertEqual(document.error.error.code, MSACDataStoreLocalStoreError);
                 [expectation fulfill];
               }];

  // Then
  [self waitForExpectationsWithTimeout:8
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testReadFromLocalStorageIfNoTokenResultCachedAndNonDeletePendingOperationAndOnline {

  // If
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@""];

  // Simulate being online.
  MS_Reachability *reachabilityMock = OCMPartialMock([MS_Reachability reachabilityForInternetConnection]);
  OCMStub([reachabilityMock currentReachabilityStatus]).andReturn(ReachableViaWiFi);
  self.sut.dataOperationProxy.reachability = reachabilityMock;

  // Mock tokens fetching but don't mock local cache.
  MSTokenResult *testToken = [[MSTokenResult alloc] initWithDictionary:[self prepareMutableDictionary]];
  MSTokensResponse *testTokensResponse = [[MSTokensResponse alloc] initWithTokens:@[ testToken ]];
  OCMStub([self.tokenExchangeMock performDbTokenAsyncOperationWithHttpClient:OCMOCK_ANY
                                                            tokenExchangeUrl:OCMOCK_ANY
                                                                   appSecret:OCMOCK_ANY
                                                                   partition:kMSPartitionTest
                                                         includeExpiredToken:YES
                                                                reachability:OCMOCK_ANY
                                                           completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSGetTokenAsyncCompletionHandler getTokenCallback;
        [invocation getArgument:&getTokenCallback atIndex:8];
        getTokenCallback(testTokensResponse, nil);
      });

  // Mock local storage.
  id<MSDocumentStore> localStorageMock = OCMProtocolMock(@protocol(MSDocumentStore));
  self.sut.dataOperationProxy.documentStore = localStorageMock;
  MSDocumentWrapper *expectedDocument = [MSDocumentWrapper new];
  expectedDocument.pendingOperation = kMSPendingOperationCreate;
  OCMStub([localStorageMock readWithToken:testToken documentId:OCMOCK_ANY documentType:OCMOCK_ANY]).andReturn(expectedDocument);

  // When
  [MSDataStore readWithPartition:kMSPartitionTest
                      documentId:@"4"
                    documentType:[MSDictionaryDocument class]
               completionHandler:^(MSDocumentWrapper *_Nonnull document) {
                 // Then
                 XCTAssertEqualObjects(expectedDocument, document);
                 [expectation fulfill];
               }];

  // Then
  [self waitForExpectationsWithTimeout:3
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}
- (void)testReadsFromLocalStorageWhenOnlineIfCreatePendingOperation {

  // If
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@""];

  // Simulate being online.
  MS_Reachability *reachabilityMock = OCMPartialMock([MS_Reachability reachabilityForInternetConnection]);
  OCMStub([reachabilityMock currentReachabilityStatus]).andReturn(ReachableViaWiFi);
  self.sut.dataOperationProxy.reachability = reachabilityMock;

  // Mock cached token result.
  MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithDictionary:[self prepareMutableDictionary]];
  OCMStub([self.tokenExchangeMock retrieveCachedTokenForPartition:kMSPartitionTest includeExpiredToken:YES]).andReturn(tokenResult);

  // Mock local storage.
  id<MSDocumentStore> localStorageMock = OCMProtocolMock(@protocol(MSDocumentStore));
  self.sut.dataOperationProxy.documentStore = localStorageMock;
  MSDocumentWrapper *expectedDocument = [MSDocumentWrapper new];
  expectedDocument.pendingOperation = kMSPendingOperationCreate;
  OCMStub([localStorageMock readWithToken:tokenResult documentId:OCMOCK_ANY documentType:OCMOCK_ANY]).andReturn(expectedDocument);

  // When
  [MSDataStore readWithPartition:kMSPartitionTest
                      documentId:@"4"
                    documentType:[MSDictionaryDocument class]
               completionHandler:^(MSDocumentWrapper *_Nonnull document) {
                 // Then
                 XCTAssertEqual(expectedDocument, document);
                 [expectation fulfill];
               }];

  // Then
  [self waitForExpectationsWithTimeout:3
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testReadsFromLocalStorageWhenOnlineIfUpdatePendingOperation {

  // If
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@""];

  // Simulate being online.
  MS_Reachability *reachabilityMock = OCMPartialMock([MS_Reachability reachabilityForInternetConnection]);
  OCMStub([reachabilityMock currentReachabilityStatus]).andReturn(ReachableViaWiFi);
  self.sut.dataOperationProxy.reachability = reachabilityMock;

  // Mock cached token result.
  MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithDictionary:[self prepareMutableDictionary]];
  OCMStub([self.tokenExchangeMock retrieveCachedTokenForPartition:kMSPartitionTest includeExpiredToken:YES]).andReturn(tokenResult);

  // Mock local storage.
  id<MSDocumentStore> localStorageMock = OCMProtocolMock(@protocol(MSDocumentStore));
  self.sut.dataOperationProxy.documentStore = localStorageMock;
  MSDocumentWrapper *expectedDocument = [MSDocumentWrapper new];
  expectedDocument.pendingOperation = kMSPendingOperationReplace;
  OCMStub([localStorageMock readWithToken:tokenResult documentId:OCMOCK_ANY documentType:OCMOCK_ANY]).andReturn(expectedDocument);

  // When
  [MSDataStore readWithPartition:kMSPartitionTest
                      documentId:@"4"
                    documentType:[MSDictionaryDocument class]
               completionHandler:^(MSDocumentWrapper *_Nonnull document) {
                 // Then
                 XCTAssertEqual(expectedDocument, document);
                 [expectation fulfill];
               }];

  // Then
  [self waitForExpectationsWithTimeout:3
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testReadReturnsNotFoundWhenOnlineIfDeletePendingOperations {

  // If
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@""];

  // Simulate being online.
  MS_Reachability *reachabilityMock = OCMPartialMock([MS_Reachability reachabilityForInternetConnection]);
  OCMStub([reachabilityMock currentReachabilityStatus]).andReturn(ReachableViaWiFi);
  self.sut.dataOperationProxy.reachability = reachabilityMock;

  // Mock cached token result.
  MSTokenResult *tokenResult = [self mockTokenFetchingWithError:nil];

  // Mock local storage.
  id<MSDocumentStore> localStorageMock = OCMProtocolMock(@protocol(MSDocumentStore));
  self.sut.dataOperationProxy.documentStore = localStorageMock;
  MSDocumentWrapper *expectedDocument = [MSDocumentWrapper new];
  expectedDocument.pendingOperation = kMSPendingOperationDelete;
  OCMStub([localStorageMock readWithToken:tokenResult documentId:OCMOCK_ANY documentType:OCMOCK_ANY]).andReturn(expectedDocument);

  // When
  [MSDataStore readWithPartition:kMSPartitionTest
                      documentId:@"4"
                    documentType:[MSDictionaryDocument class]
               completionHandler:^(MSDocumentWrapper *_Nonnull document) {
                 // Then
                 XCTAssertNotNil(document.error);
                 XCTAssertEqualObjects(document.error.error.domain, kMSACDataStoreErrorDomain);
                 XCTAssertEqual(document.error.error.code, MSACDataStoreErrorDocumentNotFound);
                 [expectation fulfill];
               }];

  // Then
  [self waitForExpectationsWithTimeout:3
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testReadsFromRemoteIfExpiredAndOnline {

  // If
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@""];

  // Simulate being online.
  MS_Reachability *reachabilityMock = OCMPartialMock([MS_Reachability reachabilityForInternetConnection]);
  OCMStub([reachabilityMock currentReachabilityStatus]).andReturn(ReachableViaWiFi);
  self.sut.dataOperationProxy.reachability = reachabilityMock;

  // Mock cached token result.
  MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithDictionary:[self prepareMutableDictionary]];
  OCMStub([self.tokenExchangeMock retrieveCachedTokenForPartition:kMSPartitionTest includeExpiredToken:YES]).andReturn(tokenResult);
  OCMStub([self.tokenExchangeMock retrieveCachedTokenForPartition:kMSPartitionTest includeExpiredToken:NO]).andReturn(tokenResult);

  // Mock expired document in local storage.
  NSError *expiredError = [NSError errorWithDomain:kMSACDataStoreErrorDomain code:MSACDataStoreErrorLocalDocumentExpired userInfo:nil];
  id<MSDocumentStore> localStorageMock = OCMProtocolMock(@protocol(MSDocumentStore));
  self.sut.dataOperationProxy.documentStore = localStorageMock;
  MSDocumentWrapper *expiredDocument = [[MSDocumentWrapper alloc] initWithError:expiredError documentId:@"4"];
  OCMStub([localStorageMock readWithToken:tokenResult documentId:OCMOCK_ANY documentType:OCMOCK_ANY]).andReturn(expiredDocument);

  // Mock CosmosDB requests.
  NSData *testCosmosDbResponse = [self jsonFixture:@"validTestDocument"];
  OCMStub([self.cosmosDbMock performCosmosDbAsyncOperationWithHttpClient:OCMOCK_ANY
                                                             tokenResult:tokenResult
                                                              documentId:kMSDocumentIdTest
                                                              httpMethod:kMSHttpMethodGet
                                                                document:OCMOCK_ANY
                                                       additionalHeaders:OCMOCK_ANY
                                                       additionalUrlPath:OCMOCK_ANY
                                                       completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSHttpRequestCompletionHandler cosmosdbOperationCallback;
        [invocation getArgument:&cosmosdbOperationCallback atIndex:9];
        cosmosdbOperationCallback(testCosmosDbResponse, [self generateResponseWithStatusCode:MSHTTPCodesNo200OK], nil);
      });
  MSDocumentWrapper *expectedDocumentWrapper = [MSDocumentUtils documentWrapperFromData:testCosmosDbResponse
                                                                           documentType:[MSDictionaryDocument class]
                                                                        fromDeviceCache:NO];

  // When
  [MSDataStore readWithPartition:kMSPartitionTest
                      documentId:kMSDocumentIdTest
                    documentType:[MSDictionaryDocument class]
               completionHandler:^(MSDocumentWrapper *_Nonnull document) {
                 // Then
                 XCTAssertNil(document.error);
                 XCTAssertEqualObjects(expectedDocumentWrapper.eTag, document.eTag);
                 XCTAssertEqualObjects(expectedDocumentWrapper.partition, document.partition);
                 XCTAssertEqualObjects(expectedDocumentWrapper.documentId, document.documentId);
                 XCTAssertEqual(expectedDocumentWrapper.fromDeviceCache, document.fromDeviceCache);
                 MSDictionaryDocument *expectedDictionaryDocument = (MSDictionaryDocument *)expectedDocumentWrapper.deserializedValue;
                 MSDictionaryDocument *actualDictionaryDocument = (MSDictionaryDocument *)document.deserializedValue;
                 XCTAssertEqualObjects(expectedDictionaryDocument.dictionary, actualDictionaryDocument.dictionary);
                 [expectation fulfill];
               }];

  // Then
  [self waitForExpectationsWithTimeout:3
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testReadsFromRemoteIfNotExpiredAndOnlineWithNoPendingOperation {

  // If
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@""];

  // Mock cached token result.
  MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithDictionary:[self prepareMutableDictionary]];
  OCMStub([self.tokenExchangeMock retrieveCachedTokenForPartition:kMSPartitionTest includeExpiredToken:YES]).andReturn(tokenResult);
  OCMStub([self.tokenExchangeMock retrieveCachedTokenForPartition:kMSPartitionTest includeExpiredToken:NO]).andReturn(tokenResult);

  // Mock document in local storage.
  id<MSDocumentStore> localStorageMock = OCMProtocolMock(@protocol(MSDocumentStore));
  self.sut.dataOperationProxy.documentStore = localStorageMock;
  NSData *jsonFixture = [self jsonFixture:@"validTestDocument"];
  MSDocumentWrapper *expectedDocumentWrapper = [MSDocumentUtils documentWrapperFromData:jsonFixture
                                                                           documentType:[MSDictionaryDocument class]
                                                                        fromDeviceCache:NO];

  MSDocumentWrapper *localDocumentWrapper = OCMPartialMock([MSDocumentUtils documentWrapperFromData:jsonFixture
                                                                                       documentType:[MSDictionaryDocument class]
                                                                                    fromDeviceCache:YES]);

  OCMStub(localDocumentWrapper.eTag).andReturn(@"some other etag");
  OCMStub([localStorageMock readWithToken:tokenResult documentId:OCMOCK_ANY documentType:OCMOCK_ANY]).andReturn(localDocumentWrapper);

  // Mock CosmosDB requests.
  OCMStub([self.cosmosDbMock performCosmosDbAsyncOperationWithHttpClient:OCMOCK_ANY
                                                             tokenResult:tokenResult
                                                              documentId:kMSDocumentIdTest
                                                              httpMethod:kMSHttpMethodGet
                                                                document:OCMOCK_ANY
                                                       additionalHeaders:OCMOCK_ANY
                                                       additionalUrlPath:kMSDocumentIdTest
                                                       completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSHttpRequestCompletionHandler cosmosdbOperationCallback;
        [invocation getArgument:&cosmosdbOperationCallback atIndex:9];
        cosmosdbOperationCallback(jsonFixture, [self generateResponseWithStatusCode:MSHTTPCodesNo200OK], nil);
      });

  // When
  [MSDataStore readWithPartition:kMSPartitionTest
                      documentId:kMSDocumentIdTest
                    documentType:[MSDictionaryDocument class]
               completionHandler:^(MSDocumentWrapper *_Nonnull document) {
                 // Then
                 XCTAssertNil(document.error);
                 XCTAssertEqualObjects(expectedDocumentWrapper.eTag, document.eTag);
                 XCTAssertFalse(document.fromDeviceCache);
                 [expectation fulfill];
               }];

  // Then
  [self waitForExpectationsWithTimeout:3
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testReadsReturnsErrorIfDocumentExpiredAndOffline {

  // If
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@""];

  // Mock cached token result.
  MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithDictionary:[self prepareMutableDictionary]];
  OCMStub([self.tokenExchangeMock retrieveCachedTokenForPartition:kMSPartitionTest includeExpiredToken:YES]).andReturn(tokenResult);

  // Simulate being offline.
  MS_Reachability *reachabilityMock = OCMPartialMock([MS_Reachability reachabilityForInternetConnection]);
  OCMStub([reachabilityMock currentReachabilityStatus]).andReturn(NotReachable);
  self.sut.dataOperationProxy.reachability = reachabilityMock;

  // Mock expired document in local storage.
  NSError *expiredError = [NSError errorWithDomain:kMSACDataStoreErrorDomain code:MSACDataStoreErrorLocalDocumentExpired userInfo:nil];
  id<MSDocumentStore> localStorageMock = OCMProtocolMock(@protocol(MSDocumentStore));
  self.sut.dataOperationProxy.documentStore = localStorageMock;
  MSDocumentWrapper *expiredDocument = [[MSDocumentWrapper alloc] initWithError:expiredError documentId:@"4"];
  OCMStub([localStorageMock readWithToken:tokenResult documentId:OCMOCK_ANY documentType:OCMOCK_ANY]).andReturn(expiredDocument);

  // When
  [MSDataStore readWithPartition:kMSPartitionTest
                      documentId:@"4"
                    documentType:[MSDictionaryDocument class]
               completionHandler:^(MSDocumentWrapper *_Nonnull document) {
                 // Then
                 XCTAssertNotNil(document.error);
                 XCTAssertEqualObjects(document.error.error.domain, kMSACDataStoreErrorDomain);
                 XCTAssertEqual(document.error.error.code, MSACDataStoreErrorLocalDocumentExpired);
                 [expectation fulfill];
               }];

  // Then
  [self waitForExpectationsWithTimeout:3
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

#pragma mark Utilities

+ (NSString *)fullTestPartitionName {
  return [NSString stringWithFormat:@"%@-%@", kMSPartitionTest, kMSAccountId];
}

- (MSTokenResult *)mockTokenFetchingWithError:(NSError *_Nullable)error {
  MSTokenResult *testToken = [[MSTokenResult alloc] initWithDictionary:[self prepareMutableDictionary]];
  MSTokensResponse *testTokensResponse = [[MSTokensResponse alloc] initWithTokens:@[ testToken ]];
  OCMStub([self.tokenExchangeMock performDbTokenAsyncOperationWithHttpClient:OCMOCK_ANY
                                                            tokenExchangeUrl:OCMOCK_ANY
                                                                   appSecret:OCMOCK_ANY
                                                                   partition:kMSPartitionTest
                                                         includeExpiredToken:NO
                                                                reachability:OCMOCK_ANY
                                                           completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSGetTokenAsyncCompletionHandler getTokenCallback;
        [invocation getArgument:&getTokenCallback atIndex:8];
        getTokenCallback(error ? nil : testTokensResponse, error);
      });
  OCMStub([self.tokenExchangeMock performDbTokenAsyncOperationWithHttpClient:OCMOCK_ANY
                                                            tokenExchangeUrl:OCMOCK_ANY
                                                                   appSecret:OCMOCK_ANY
                                                                   partition:kMSPartitionTest
                                                         includeExpiredToken:YES
                                                                reachability:OCMOCK_ANY
                                                           completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSGetTokenAsyncCompletionHandler getTokenCallback;
        [invocation getArgument:&getTokenCallback atIndex:8];
        getTokenCallback(error ? nil : testTokensResponse, error);
      });
  return testToken;
}

- (NSHTTPURLResponse *)generateResponseWithStatusCode:(NSInteger)statusCode {
  return [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"https://contoso.com"]
                                     statusCode:statusCode
                                    HTTPVersion:nil
                                   headerFields:nil];
}
@end
