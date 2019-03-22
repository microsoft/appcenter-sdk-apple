// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSChannelGroupProtocol.h"
#import "MSCosmosDb.h"
#import "MSCosmosDbIngestion.h"
#import "MSTestFrameworks.h"
#import "MSTokenResult.h"

@interface MSTokenResult (Test)
- (instancetype)initWithPartition:(NSString *)partition
                        dbAccount:(NSString *)dbAccount
                           dbName:(NSString *)dbName
                 dbCollectionName:(NSString *)dbCollectionName
                            token:(NSString *)token
                           status:(NSString *)status
                        expiresOn:(NSString *)expiresOn;
@end

@interface MSCosmosDb (Test)

+ (NSDictionary *)defaultHeaderWithPartition:(NSString *)partition
                                     dbToken:(NSString *)dbToken
                           additionalHeaders:(NSDictionary *_Nullable)additionalHeaders;

+ (NSString *)documentUrlWithTokenResult:tokenResult documentId:(NSString *)documentId;

@end

@interface MSDataStoreTests : XCTestCase

@property(nonatomic) id settingsMock;

@end

@implementation MSDataStoreTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testDefaultHeaderWithPartitionWithDictionaryNotNull {

    // If
    NSMutableDictionary *_Nullable additionalHeaders = [NSMutableDictionary new];
    additionalHeaders[@"Type1"] = @"Value1";
    additionalHeaders[@"Type2"] = @"Value2";
    additionalHeaders[@"Type3"] = @"Value3";

    // When
    NSDictionary *dic = [MSCosmosDb defaultHeaderWithPartition:@"partition" dbToken:@"token" additionalHeaders:additionalHeaders];

    // Then
    XCTAssertNotNil(dic);
    XCTAssertTrue(dic[@"Type1"]);
    XCTAssertTrue(dic[@"Type2"]);
    XCTAssertTrue(dic[@"Type3"]);
}

- (void)testDefaultHeaderWithPartitionWithDictionaryNull {

    // If
    NSDictionary *dic;

    // When
    dic = [MSCosmosDb defaultHeaderWithPartition:@"partition" dbToken:@"token" additionalHeaders:nil];

    // Then
    XCTAssertNotNil(dic);
    XCTAssertTrue(dic[@"Content-Type"]);
}

- (void)testDocumentUrlWithTokenResultWithStringToken {

    // If
    MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithString:@"token"];

    // When
    NSString *result = [MSCosmosDb documentUrlWithTokenResult:tokenResult documentId:@"documentId"];

    // Then
    XCTAssertNotNil(result);
}

- (void)testDocumentUrlWithTokenResultWithObjectToken {

    // If
    MSTokenResult *tokenResult;
    NSString *testResult;

    // When
    tokenResult = [[MSTokenResult alloc] initWithPartition:@"token"
                                                 dbAccount:@"dbAccount"
                                                    dbName:@"dbName"
                                          dbCollectionName:@"dbCollectionName"
                                                     token:@"token"
                                                    status:@"status"
                                                 expiresOn:@"expiresOn"];
    testResult = [MSCosmosDb documentUrlWithTokenResult:tokenResult documentId:@"documentId"];

    // Then
    XCTAssertNotNil(testResult);
    XCTAssertTrue([testResult isEqualToString:@"https://dbAccount.documents.azure.com/dbs/dbName/colls/dbCollectionName/docs/documentId"]);
}

- (void)testDocumentUrlWithTokenResultWithDictionaryToken {

    // If
    NSMutableDictionary *_Nullable tokenResultDictionary = [NSMutableDictionary new];
    tokenResultDictionary[@"partition"] = @"partition";
    tokenResultDictionary[@"dbAccount"] = @"dbAccountTest0";
    tokenResultDictionary[@"dbName"] = @"dbNameTest1";
    tokenResultDictionary[@"dbCollectionName"] = @"dbCollectionNameTest2";
    tokenResultDictionary[@"token"] = @"token";
    tokenResultDictionary[@"status"] = @"status";
    tokenResultDictionary[@"expiresOn"] = @"expiresOn";
    MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithDictionary:tokenResultDictionary];
    NSString *testResult;

    // When
    testResult = [MSCosmosDb documentUrlWithTokenResult:tokenResult documentId:@"documentId"];

    // Then
    XCTAssertNotNil(testResult);
    XCTAssertTrue([testResult containsString:@"documentId"]);
    XCTAssertTrue([testResult containsString:@"dbAccountTest0"]);
    XCTAssertTrue([testResult containsString:@"dbNameTest1"]);
    XCTAssertTrue([testResult containsString:@"dbCollectionNameTest2"]);
}

- (void)testPerformCosmosDbAsyncOperationWithHttpClientWithAdditionalParams {

    // If
    MSCosmosDbIngestion *httpClient = [[MSCosmosDbIngestion alloc] init];
    NSMutableDictionary *tokenResultDictionary = [NSMutableDictionary new];
    tokenResultDictionary[@"partition"] = @"partition";
    tokenResultDictionary[@"dbAccount"] = @"dbAccount";
    tokenResultDictionary[@"dbName"] = @"dbName";
    tokenResultDictionary[@"dbCollectionName"] = @"dbCollectionName";
    tokenResultDictionary[@"token"] = @"token";
    tokenResultDictionary[@"status"] = @"status";
    tokenResultDictionary[@"expiresOn"] = @"expiresOn";
    MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithDictionary:tokenResultDictionary];
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
                                                 documentId:@"documentID"
                                                 httpMethod:@"GET"
                                                       body:nil
                                          additionalHeaders:additionalHeaders
                                          completionHandler:handler];
    [self waitForExpectationsWithTimeout:5 handler:NULL];

    // Then
    XCTAssertTrue([completeExpectation assertForOverFulfill]);
    XCTAssertTrue(completionHandlerCalled);
}

- (void)testPerformCosmosDbAsyncOperationWithHttpClient {

    // If
    MSCosmosDbIngestion *httpClient = [[MSCosmosDbIngestion alloc] init];
    NSMutableDictionary *tokenResultDictionary = [NSMutableDictionary new];
    tokenResultDictionary[@"partition"] = @"partition";
    tokenResultDictionary[@"dbAccount"] = @"dbAccount";
    tokenResultDictionary[@"dbName"] = @"dbName";
    tokenResultDictionary[@"dbCollectionName"] = @"dbCollectionName";
    tokenResultDictionary[@"token"] = @"token";
    tokenResultDictionary[@"status"] = @"status";
    tokenResultDictionary[@"expiresOn"] = @"expiresOn";
    MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithDictionary:tokenResultDictionary];
    __block BOOL completionHandlerCalled = NO;
    XCTestExpectation *completeExpectation = [self expectationWithDescription:@"Task finished"];
    MSCosmosDbCompletionHandler handler = ^(NSData *_Nullable data, NSError *_Nullable error) {
      completionHandlerCalled = YES;
      [completeExpectation fulfill];
    };

    // When
    [MSCosmosDb performCosmosDbAsyncOperationWithHttpClient:httpClient
                                                tokenResult:tokenResult
                                                 documentId:@"documentID"
                                                 httpMethod:@"GET"
                                                       body:nil
                                          completionHandler:handler];
    [self waitForExpectationsWithTimeout:5 handler:NULL];

    // Then
    XCTAssertTrue([completeExpectation assertForOverFulfill]);
    XCTAssertTrue(completionHandlerCalled);
}
@end
