// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthTokenContext.h"
#import "MSConstants+Internal.h"
#import "MSDataStoreErrors.h"
#import "MSHttpClientProtocol.h"
#import "MSKeychainUtil.h"
#import "MSTestFrameworks.h"
#import "MSTokenExchange.h"
#import "MSTokenResult.h"
#import "MSTokensResponse.h"
#import "MSUtility+Date.h"

static NSString *const kMSPartition = @"partition";
static NSString *const kMSToken = @"token";
static NSString *const kMSStatus = @"status";
static NSString *const kMSDbName = @"dbName";
static NSString *const kMSDbAccount = @"dbAccount";
static NSString *const kMSDbCollectionName = @"dbCollectionName";
static NSString *const kMSExpiresOn = @"expiresOn";
static NSString *const kMSTokenResultSucceed = @"Succeed";

static NSString *const expiresOn = @"1999-09-19T11:11:11.111Z";
static NSString *const token = @"mock-token";
static NSString *const mockPartition = @"mock-partition";
static NSString *const mockTokenKeyName = @"mock-token-key-name";

static NSString *const cachedToken = @"mockCachedToken";
static NSString *const kMSStorageReadOnlyDbTokenKey = @"MSStorageReadOnlyDbToken";
static NSString *const kMSStorageUserDbTokenKey = @"MSStorageUserDbToken";
static NSString *const MSDataStoreAppDocumentsPartition = @"readonly";

@interface MSTokenExchange (Test)

+ (void)removeCachedToken:(NSString *)partitionName;
+ (NSString *)tokenKeyNameForPartition:(NSString *)partitionName;
+ (void)saveToken:(MSTokenResult *)tokenResult;
+ (MSTokenResult *)retrieveCachedToken:(NSString *)partitionName;

@end

@interface MSTokenExchangeTests : XCTestCase

@property(nonatomic) id keychainUtilMock;
@property(nonatomic) id sut;

@end

@implementation MSTokenExchangeTests

- (void)setUp {
  [super setUp];
  self.sut = OCMClassMock([MSTokenExchange class]);
  self.keychainUtilMock = OCMClassMock([MSKeychainUtil class]);
  OCMStub(ClassMethod([self.sut tokenKeyNameForPartition:mockPartition])).andReturn(mockTokenKeyName);
}

- (void)tearDown {
  [super tearDown];
  [self.sut stopMocking];
  [self.keychainUtilMock stopMocking];
}

- (void)testWhenNoCachedTokenNewTokenIsCached {

  // If
  NSObject *tokenData = [self getSuccessfulTokenData];
  NSMutableDictionary *tokenList = [@{kMSTokens : @[ tokenData ]} mutableCopy];
  NSData *jsonTokenData = [NSJSONSerialization dataWithJSONObject:tokenList options:NSJSONWritingPrettyPrinted error:nil];
  MSAuthTokenContext *mockContext = [MSAuthTokenContext sharedInstance];
  [mockContext setAuthToken:@"fake-token" withAccountId:@"account-id"];
  id authContextMock = OCMClassMock([MSAuthTokenContext class]);
  OCMStub(ClassMethod([authContextMock sharedInstance])).andReturn(mockContext);
  id<MSHttpClientProtocol> httpMock = OCMProtocolMock(@protocol(MSHttpClientProtocol));
  __block NSDictionary *actualHeaders;

  // Mock HTTP call returning fake token data.
  OCMStub([httpMock sendAsync:OCMOCK_ANY method:OCMOCK_ANY headers:OCMOCK_ANY data:OCMOCK_ANY completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSHttpRequestCompletionHandler completionBlock;
        [invocation getArgument:&actualHeaders atIndex:4];
        [invocation getArgument:&completionBlock atIndex:6];
        NSHTTPURLResponse *response = [NSHTTPURLResponse new];
        id mockResponse = OCMPartialMock(response);
        OCMStub([mockResponse statusCode]).andReturn(MSHTTPCodesNo200OK);
        completionBlock(jsonTokenData, mockResponse, nil);
      });

  // Mock returning nil for cached token.
  OCMStub([self.keychainUtilMock stringForKey:mockTokenKeyName]).andReturn(nil);
  OCMStub([self.keychainUtilMock storeString:OCMOCK_ANY forKey:OCMOCK_ANY]).andReturn(YES);
  XCTestExpectation *completeExpectation = [self expectationWithDescription:@"Task finished"];

  // When
  __block MSTokenResult *returnedTokenResult = nil;
  [MSTokenExchange performDbTokenAsyncOperationWithHttpClient:httpMock
                                             tokenExchangeUrl:[NSURL new]
                                                    appSecret:@"appSecret"
                                                    partition:mockPartition
                                            completionHandler:^(MSTokensResponse *tokenResponses, NSError *_Nullable returnError) {
                                              XCTAssertNil(returnError);
                                              returnedTokenResult = [tokenResponses tokens][0];
                                              NSString *tokenValue = returnedTokenResult.token;
                                              XCTAssertTrue([tokenValue isEqualToString:token]);
                                              [completeExpectation fulfill];
                                            }];

  // Then
  [self waitForExpectationsWithTimeout:5 handler:nil];
  OCMVerify([self.keychainUtilMock storeString:[returnedTokenResult serializeToString] forKey:mockTokenKeyName]);
  XCTAssertEqualObjects(actualHeaders[@"Authorization"], @"Bearer fake-token");
  XCTAssertEqualObjects(actualHeaders[@"Content-Type"], @"application/json");
  XCTAssertEqualObjects(actualHeaders[@"App-Secret"], @"appSecret");
}

- (void)testGetReadOnlyToken {

  // If
  NSObject *tokenData = [self getSuccessfulTokenData];
  NSMutableDictionary *tokenList = [@{kMSTokens : @[ tokenData ]} mutableCopy];
  NSData *jsonTokenData = [NSJSONSerialization dataWithJSONObject:tokenList options:NSJSONWritingPrettyPrinted error:nil];
  id<MSHttpClientProtocol> httpMock = OCMProtocolMock(@protocol(MSHttpClientProtocol));
  __block NSDictionary *actualHeaders;

  // Mock HTTP call returning fake token data.
  OCMStub([httpMock sendAsync:OCMOCK_ANY method:OCMOCK_ANY headers:OCMOCK_ANY data:OCMOCK_ANY completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSHttpRequestCompletionHandler completionBlock;
        [invocation getArgument:&actualHeaders atIndex:4];
        [invocation getArgument:&completionBlock atIndex:6];
        NSHTTPURLResponse *response = [NSHTTPURLResponse new];
        id mockResponse = OCMPartialMock(response);
        OCMStub([mockResponse statusCode]).andReturn(MSHTTPCodesNo200OK);
        completionBlock(jsonTokenData, mockResponse, nil);
      });

  // Mock returning nil for cached token.
  OCMStub([self.keychainUtilMock stringForKey:mockTokenKeyName]).andReturn(nil);
  OCMStub([self.keychainUtilMock storeString:OCMOCK_ANY forKey:OCMOCK_ANY]).andReturn(YES);
  XCTestExpectation *completeExpectation = [self expectationWithDescription:@"Task finished"];

  // When
  __block MSTokenResult *returnedTokenResult = nil;
  [MSTokenExchange performDbTokenAsyncOperationWithHttpClient:httpMock
                                             tokenExchangeUrl:[NSURL new]
                                                    appSecret:@"appSecret"
                                                    partition:mockPartition
                                            completionHandler:^(MSTokensResponse *tokenResponses, NSError *_Nullable returnError) {
                                              XCTAssertNil(returnError);
                                              returnedTokenResult = [tokenResponses tokens][0];
                                              NSString *tokenValue = returnedTokenResult.token;
                                              XCTAssertTrue([tokenValue isEqualToString:token]);
                                              [completeExpectation fulfill];
                                            }];

  // Then
  [self waitForExpectationsWithTimeout:5 handler:nil];
  OCMVerify([self.keychainUtilMock storeString:[returnedTokenResult serializeToString] forKey:mockTokenKeyName]);
  XCTAssertNil(actualHeaders[@"Authorization"]);
  XCTAssertEqualObjects(actualHeaders[@"Content-Type"], @"application/json");
  XCTAssertEqualObjects(actualHeaders[@"App-Secret"], @"appSecret");
}

- (void)testValidCachedTokenExists {

  // If
  NSData *tokenData = [NSJSONSerialization dataWithJSONObject:[self getSuccessfulTokenData] options:NSJSONWritingPrettyPrinted error:nil];
  NSString *tokenString = [[NSString alloc] initWithData:tokenData encoding:NSUTF8StringEncoding];
  OCMStub([self.keychainUtilMock stringForKey:mockTokenKeyName]).andReturn(tokenString);
  id utilityMock = OCMClassMock([MSUtility class]);
  id<MSHttpClientProtocol> httpMock = OCMProtocolMock(@protocol(MSHttpClientProtocol));

  // Mock returning valid expire date.
  OCMStub(ClassMethod([utilityMock dateFromISO8601:OCMOCK_ANY])).andReturn([NSDate dateWithTimeIntervalSinceNow:100000]);

  // We should not call for new token if the cached valid.
  OCMReject([httpMock sendAsync:OCMOCK_ANY method:OCMOCK_ANY headers:OCMOCK_ANY data:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
  XCTestExpectation *completeExpectation = [self expectationWithDescription:@"Task finished"];

  // When
  [MSTokenExchange performDbTokenAsyncOperationWithHttpClient:httpMock
                                             tokenExchangeUrl:[NSURL new]
                                                    appSecret:@"appSecret"
                                                    partition:mockPartition
                                            completionHandler:^(MSTokensResponse *tokenResponses, NSError *_Nullable error) {
                                              XCTAssertNil(error);
                                              NSString *tokenValue = [tokenResponses tokens][0].token;
                                              XCTAssertTrue([tokenValue isEqualToString:token]);
                                              [completeExpectation fulfill];
                                            }];

  // Then
  [self waitForExpectationsWithTimeout:5 handler:nil];
  [utilityMock stopMocking];
}

- (void)testRemoveAllTokens {

  // If
  OCMStub([self.keychainUtilMock deleteStringForKey:OCMOCK_ANY]).andReturn(@"success");

  // When
  [MSTokenExchange removeAllCachedTokens];

  // Then
  OCMVerify([self.keychainUtilMock deleteStringForKey:kMSStorageReadOnlyDbTokenKey]);
  OCMVerify([self.keychainUtilMock deleteStringForKey:kMSStorageUserDbTokenKey]);
}

- (void)testCachedTokenIsExpired {

  // If
  NSData *tokenData = [NSJSONSerialization dataWithJSONObject:[self getExpiredTokenData] options:NSJSONWritingPrettyPrinted error:nil];
  NSString *tokenString = [[NSString alloc] initWithData:tokenData encoding:NSUTF8StringEncoding];
  OCMStub([self.keychainUtilMock stringForKey:mockTokenKeyName]).andReturn(tokenString);
  OCMStub([self.keychainUtilMock deleteStringForKey:OCMOCK_ANY]).andReturn(@"success");
  id<MSHttpClientProtocol> httpMock = OCMProtocolMock(@protocol(MSHttpClientProtocol));
  OCMStub([httpMock sendAsync:OCMOCK_ANY method:OCMOCK_ANY headers:OCMOCK_ANY data:OCMOCK_ANY completionHandler:OCMOCK_ANY]);

  // When
  [MSTokenExchange
      performDbTokenAsyncOperationWithHttpClient:httpMock
                                tokenExchangeUrl:[NSURL new]
                                       appSecret:@"appSecret"
                                       partition:mockPartition
                               completionHandler:^(MSTokensResponse *__unused tokenResponses, NSError *_Nullable __unused error){
                               }];

  // Then
  OCMVerify([self.keychainUtilMock deleteStringForKey:OCMOCK_ANY]);
}

- (void)testCachedTokenNotFoundInKeychain {

  // If
  id<MSHttpClientProtocol> httpMock = OCMProtocolMock(@protocol(MSHttpClientProtocol));
  OCMStub([httpMock sendAsync:OCMOCK_ANY method:OCMOCK_ANY headers:OCMOCK_ANY data:OCMOCK_ANY completionHandler:OCMOCK_ANY]);

  // Mock that there is no cached token.
  OCMStub([self.keychainUtilMock stringForKey:mockTokenKeyName]).andReturn(nil);

  // When
  [MSTokenExchange
      performDbTokenAsyncOperationWithHttpClient:httpMock
                                tokenExchangeUrl:[NSURL new]
                                       appSecret:@"appSecret"
                                       partition:mockPartition
                               completionHandler:^(MSTokensResponse *__unused tokenResponses, NSError *_Nullable __unused returnError){
                               }];

  // Then
  OCMVerify([httpMock sendAsync:OCMOCK_ANY method:OCMOCK_ANY headers:OCMOCK_ANY data:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
}

- (void)testExchangeServiceSerializationFails {

  // If
  // Mock that there is no cached token.
  OCMStub([self.keychainUtilMock stringForKey:mockTokenKeyName]).andReturn(nil);
  id<MSHttpClientProtocol> httpMock = OCMProtocolMock(@protocol(MSHttpClientProtocol));

  // Mock returning invalid token data.
  OCMStub([httpMock sendAsync:OCMOCK_ANY method:OCMOCK_ANY headers:OCMOCK_ANY data:OCMOCK_ANY completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __block MSHttpRequestCompletionHandler completionBlock;
        [invocation getArgument:&completionBlock atIndex:6];
        NSHTTPURLResponse *response = [NSHTTPURLResponse new];
        id mockResponse = OCMPartialMock(response);
        OCMStub([mockResponse statusCode]).andReturn(MSHTTPCodesNo200OK);
        completionBlock([NSData new], mockResponse, nil);
      });
  XCTestExpectation *completeExpectation = [self expectationWithDescription:@"Task finished"];

  // When
  [MSTokenExchange performDbTokenAsyncOperationWithHttpClient:httpMock
                                             tokenExchangeUrl:[NSURL new]
                                                    appSecret:@"appSecret"
                                                    partition:mockPartition
                                            completionHandler:^(MSTokensResponse *__unused tokenResponses, NSError *_Nullable returnError) {
                                              XCTAssertNotNil(returnError);
                                              XCTAssertEqual(returnError.code, MSDataStoreErrorJSONSerializationFailed);
                                              [completeExpectation fulfill];
                                            }];

  // Then
  [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testExchangeServiceReturnsError {

  // If
  // Mock that there is no cached token.
  OCMStub([self.keychainUtilMock stringForKey:mockTokenKeyName]).andReturn(nil);
  id<MSHttpClientProtocol> httpMock = OCMProtocolMock(@protocol(MSHttpClientProtocol));

  // Mock returning error.
  NSError *serviceError = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorCannotDecodeRawData userInfo:nil];
  OCMStub([httpMock sendAsync:OCMOCK_ANY method:OCMOCK_ANY headers:OCMOCK_ANY data:OCMOCK_ANY completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __block MSHttpRequestCompletionHandler completionBlock;
        [invocation getArgument:&completionBlock atIndex:6];
        NSHTTPURLResponse *response = [NSHTTPURLResponse new];
        id mockResponse = OCMPartialMock(response);
        OCMStub([mockResponse statusCode]).andReturn(MSHTTPCodesNo200OK);
        completionBlock([NSData new], mockResponse, serviceError);
      });
  XCTestExpectation *completeExpectation = [self expectationWithDescription:@"Task finished"];

  // When
  [MSTokenExchange performDbTokenAsyncOperationWithHttpClient:httpMock
                                             tokenExchangeUrl:[NSURL new]
                                                    appSecret:@"appSecret"
                                                    partition:mockPartition
                                            completionHandler:^(MSTokensResponse *__unused tokenResponses, NSError *_Nullable returnError) {
                                              XCTAssertEqual(returnError, serviceError);
                                              [completeExpectation fulfill];
                                            }];

  // Then
  [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testExchangeServiceReturnsTokenError {

  // If
  // Mock that there is no cached token.
  OCMStub([self.keychainUtilMock stringForKey:mockTokenKeyName]).andReturn(nil);
  id<MSHttpClientProtocol> httpMock = OCMProtocolMock(@protocol(MSHttpClientProtocol));

  // Mock returning failed token.
  NSObject *failedToken = [self getFailedTokenData];
  NSMutableDictionary *tokenList = [@{kMSTokens : @[ failedToken ]} mutableCopy];
  NSData *jsonTokenData = [NSJSONSerialization dataWithJSONObject:tokenList options:NSJSONWritingPrettyPrinted error:nil];
  OCMStub([httpMock sendAsync:OCMOCK_ANY method:OCMOCK_ANY headers:OCMOCK_ANY data:OCMOCK_ANY completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __block MSHttpRequestCompletionHandler completionBlock;
        [invocation getArgument:&completionBlock atIndex:6];
        NSHTTPURLResponse *response = [NSHTTPURLResponse new];
        id mockResponse = OCMPartialMock(response);
        OCMStub([mockResponse statusCode]).andReturn(MSHTTPCodesNo200OK);
        completionBlock(jsonTokenData, mockResponse, nil);
      });
  XCTestExpectation *completeExpectation = [self expectationWithDescription:@"Task finished"];

  // When
  [MSTokenExchange performDbTokenAsyncOperationWithHttpClient:httpMock
                                             tokenExchangeUrl:[NSURL new]
                                                    appSecret:@"appSecret"
                                                    partition:mockPartition
                                            completionHandler:^(MSTokensResponse *__unused tokenResponses, NSError *_Nullable returnError) {
                                              XCTAssertNotNil(returnError);
                                              XCTAssertEqual([returnError code], MSDataStoreErrorHTTPError);
                                              [completeExpectation fulfill];
                                            }];

  // Then
  [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testSaveTokenFails {

  // If
  OCMReject([self.keychainUtilMock storeString:OCMOCK_ANY forKey:OCMOCK_ANY]);

  // When
  [MSTokenExchange saveToken:nil];

  // Then
  OCMVerifyAll(self.keychainUtilMock);
}

- (void)testSaveTokenFailsWithoutPartition {

  // If
  OCMReject([self.keychainUtilMock storeString:OCMOCK_ANY forKey:OCMOCK_ANY]);
  NSData *tokenData = [NSJSONSerialization dataWithJSONObject:[self getSuccessfulTokenData] options:NSJSONWritingPrettyPrinted error:nil];
  NSString *tokenString = [[NSString alloc] initWithData:tokenData encoding:NSUTF8StringEncoding];
  MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithString:tokenString];
  id mockResult = OCMPartialMock(tokenResult);
  OCMStub([mockResult partition]).andReturn(nil);
  OCMStub([mockResult serializeToString]).andReturn(@"string");

  // When
  [MSTokenExchange saveToken:mockResult];

  // Then
  OCMVerifyAll(self.keychainUtilMock);
}

- (void)testSaveTokenFailsIfStoreStringFails {

  // If
  OCMStub([self.keychainUtilMock storeString:OCMOCK_ANY forKey:OCMOCK_ANY]).andReturn(NO);
  NSData *tokenData = [NSJSONSerialization dataWithJSONObject:[self getSuccessfulTokenData] options:NSJSONWritingPrettyPrinted error:nil];
  NSString *tokenString = [[NSString alloc] initWithData:tokenData encoding:NSUTF8StringEncoding];
  MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithString:tokenString];

  // When
  [MSTokenExchange saveToken:tokenResult];

  // Then
  OCMVerifyAll(self.keychainUtilMock);
}

- (void)testRemoveCachedTokenNotRaisesError {

  // If
  OCMStub([self.keychainUtilMock deleteStringForKey:OCMOCK_ANY]).andReturn(nil);

  // When
  [MSTokenExchange removeCachedToken:@"token"];

  // Then
  OCMVerifyAll(self.keychainUtilMock);
}

- (void)testRemoveAllCachedTokensNotRaisesError {

  // If
  OCMStub([self.keychainUtilMock deleteStringForKey:OCMOCK_ANY]).andReturn(nil);

  // When
  [MSTokenExchange removeAllCachedTokens];

  // Then
  OCMVerifyAll(self.keychainUtilMock);
}

- (void)testTokenKeyNameForPartitionReturnsReadOnlyKey {

  // If
  NSString *readonlyPartition = [NSString stringWithFormat:@"partition-%@", MSDataStoreAppDocumentsPartition];

  // When
  NSString *tokenKeyName = [MSTokenExchange tokenKeyNameForPartition:readonlyPartition];

  // Then
  XCTAssertTrue([tokenKeyName isEqualToString:kMSStorageReadOnlyDbTokenKey]);
}

- (void)testTokenKeyNameForPartitionReturnsValidKey {

  // If
  NSString *notReadonlyPartition = @"partition";

  // When
  NSString *tokenKeyName = [MSTokenExchange tokenKeyNameForPartition:notReadonlyPartition];

  // Then
  XCTAssertTrue([tokenKeyName isEqualToString:kMSStorageUserDbTokenKey]);
}

- (NSObject *)getExpiredTokenData {
  return @{
    kMSPartition : @"",
    kMSToken : token,
    kMSStatus : @"",
    kMSDbName : @"",
    kMSDbAccount : @"",
    kMSDbCollectionName : @"",
    kMSExpiresOn : expiresOn
  };
}

- (NSObject *)getFailedTokenData {
  return @{
    kMSPartition : @"",
    kMSToken : @"",
    kMSStatus : @"Failed",
    kMSDbName : @"",
    kMSDbAccount : @"",
    kMSDbCollectionName : @"",
    kMSExpiresOn : expiresOn
  };
}

- (NSObject *)getSuccessfulTokenData {
  return @{
    kMSPartition : mockPartition,
    kMSToken : token,
    kMSStatus : kMSTokenResultSucceed,
    kMSDbName : @"",
    kMSDbAccount : @"",
    kMSDbCollectionName : @"",
    kMSExpiresOn : expiresOn
  };
}

@end
