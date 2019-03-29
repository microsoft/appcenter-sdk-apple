// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSChannelGroupProtocol.h"
#import "MSChannelUnitProtocol.h"
#import "MSCosmosDb.h"
#import "MSCosmosDbIngestion.h"
#import "MSCosmosDbPrivate.h"
#import "MSDataStore.h"
#import "MSDataStoreInternal.h"
#import "MSDataStorePrivate.h"
#import "MSHttpTestUtil.h"
#import "MSMockUserDefaults.h"
#import "MSPaginatedDocuments.h"
#import "MSServiceAbstract.h"
#import "MSServiceAbstractProtected.h"
#import "MSTestFrameworks.h"
#import "MSTokenExchange.h"
#import "MSTokenExchangePrivate.h"
#import "MSTokenResult.h"
#import "MSUserIdContextPrivate.h"

static NSString *const kMSTokenTest = @"token";
static NSString *const kMSPartitionTest = @"partition";
static NSString *const kMSDbAccountTest = @"dbAccount";
static NSString *const kMSDbNameTest = @"dbName";
static NSString *const kMSDbCollectionNameTest = @"dbCollectionName";
static NSString *const kMSStatusTest = @"status";
static NSString *const kMSExpiresOnTest = @"20191212";
static NSString *const kMSDocumentIdTest = @"documentId";

@interface MSDataStoreTests : XCTestCase

@end

/*
 * Test document object.
 */

@interface SomeObject : NSObject <MSSerializableDocument>

@property(strong, nonatomic) NSString *property1;
@property(strong, nonatomic) NSNumber *property2;

@end

@implementation SomeObject

@synthesize property1 = _property1;
@synthesize property2 = _property2;

- (instancetype)initFromDictionary:(NSDictionary *)dictionary {
  self.property1 = ((NSDictionary *)dictionary[@"document"])[@"property1"];
  self.property2 = ((NSDictionary *)dictionary[@"document"])[@"property2"];
  return self;
}

- (nonnull NSDictionary *)serializeToDictionary {
  return [NSDictionary new];
}

@end

/*
 * Tests.
 */

@implementation MSDataStoreTests

#pragma mark - Tests

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
  MSCosmosDbCompletionHandler handler =
      ^(NSData *_Nullable __unused data, NSDictionary *_Nullable __unused headers, NSError *_Nullable __unused error) {
        completionHandlerCalled = YES;
      };
  NSString *expectedURLString = @"https://dbAccount.documents.azure.com/dbs/dbName/colls/dbCollectionName/docs/documentId";
  __block NSData *actualData;
  OCMStub([httpClient sendAsync:OCMOCK_ANY completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    MSCosmosDbCompletionHandler completionHandler;
    [invocation retainArguments];
    [invocation getArgument:&actualData atIndex:2];
    [invocation getArgument:&completionHandler atIndex:3];
    completionHandler(actualData, nil, (NSError *)nil);
  });
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
  MSCosmosDbCompletionHandler handler =
      ^(NSData *_Nullable __unused data, NSDictionary *_Nullable __unused headers, NSError *_Nullable __unused error) {
        completionHandlerCalled = YES;
      };
  NSString *expectedURLString = @"https://dbAccount.documents.azure.com/dbs/dbName/colls/dbCollectionName/docs/documentId";
  __block NSData *actualData;
  OCMStub([httpClient sendAsync:OCMOCK_ANY completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    MSCosmosDbCompletionHandler completionHandler;
    [invocation retainArguments];
    [invocation getArgument:&actualData atIndex:2];
    [invocation getArgument:&completionHandler atIndex:3];
    completionHandler(actualData, nil, nil);
  });
  NSDictionary *dic = @{@"abv" : @1, @"foo" : @"bar"};
  __block NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:0 error:nil];

  // When
  [MSCosmosDb performCosmosDbAsyncOperationWithHttpClient:httpClient
                                              tokenResult:tokenResult
                                               documentId:kMSDocumentIdTest
                                               httpMethod:kMSHttpMethodGet
                                                     body:data
                                        additionalHeaders:nil
                                        completionHandler:handler];

  // Then
  XCTAssertTrue(completionHandlerCalled);
  XCTAssertEqualObjects(data, actualData);
  XCTAssertTrue([expectedURLString isEqualToString:httpClient.sendURL.absoluteString]);
}

// TODO: add more tests for list operation.
- (void)testListSingleDocument {

  // If
  MSDataStore *sut = [MSDataStore new];
  id httpClient = OCMClassMock([MSCosmosDbIngestion class]);
  OCMStub([httpClient new]).andReturn(httpClient);
  id msTokenEchange = OCMClassMock([MSTokenExchange class]);
  OCMStub([msTokenEchange retrieveCachedToken:[OCMArg any]])
      .andReturn([[MSTokenResult alloc] initWithDictionary:[self prepareMutableDictionary]]);
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"List single document"];
  OCMStub([httpClient sendAsync:OCMOCK_ANY completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation retainArguments];
    MSSendAsyncCompletionHandler completionHandler;
    [invocation getArgument:&completionHandler atIndex:3];
    NSData *payload = [self getJsonFixture:@"oneDocumentPage"];
    completionHandler(@"callId", [MSHttpTestUtil createMockResponseForStatusCode:200 headers:nil], payload, nil);
  });

  // When
  __block MSPaginatedDocuments *testDocuments;
  [sut listWithPartition:@"partition"
            documentType:[SomeObject class]
             readOptions:nil
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
      [testDocuments nextPageWithCompletionHandler:^(MSPage *page) {
        XCTAssertNil(page);
      }];
      MSDocumentWrapper<SomeObject *> *documentWrapper = [[testDocuments currentPage] items][0];
      XCTAssertTrue([[documentWrapper documentId] isEqualToString:@"doc1"]);
      XCTAssertNil([documentWrapper error]);
      XCTAssertNotNil([documentWrapper jsonValue]);
      XCTAssertTrue([[documentWrapper eTag] isEqualToString:@"etag value"]);
      XCTAssertTrue([[documentWrapper partition] isEqualToString:@"partition"]);
      XCTAssertNotNil([documentWrapper lastUpdatedDate]);
      SomeObject *deserializedDocument = [documentWrapper deserializedValue];
      XCTAssertNotNil(deserializedDocument);
      XCTAssertTrue([[deserializedDocument property1] isEqualToString:@"property 1 string"]);
      XCTAssertTrue([[deserializedDocument property2] isEqual:@42]);
    }
  };
  [self waitForExpectationsWithTimeout:1
                               handler:handler];
  [httpClient stopMocking];
}

/*
 * Utils.
 */

- (NSData *)getJsonFixture:(NSString *)fixture {
  NSBundle *bundle = [NSBundle bundleForClass:[self class]];
  NSString *path = [bundle pathForResource:fixture ofType:@"json"];
  return [NSData dataWithContentsOfFile:path];
}

@end
