// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSKeychainUtil.h"
#import "MSTestFrameworks.h"
#import "MSTokenExchange.h"
#import "MSStorageIngestion.h"
#import "MSTokenResult.h"
#import "MSDataStoreErrors.h"
#import "MSTokensResponse.h"
#import "MSConstants+Internal.h"

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

@interface MSTokenExchange (Test)

+ (void)removeCachedToken:(NSString *)partitionName;
+ (NSString *)tokenKeyNameForPartition:(NSString *)partitionName;
+ (void)saveToken:(MSTokenResult *)tokenResult;
+ (MSTokenResult *)retrieveCachedToken:(NSString *)partitionName;

@end

@interface MSTokenExchangeTests : XCTestCase

@property(nonatomic) id keychainUtilMock;
@property(nonatomic) id ingestionStoreMock;
@property(nonatomic) id sut;

@end

@implementation MSTokenExchangeTests

- (void)setUp {
  [super setUp];
  self.sut = OCMClassMock([MSTokenExchange class]);
  self.keychainUtilMock = OCMClassMock([MSKeychainUtil class]);
  self.ingestionStoreMock = OCMClassMock([MSStorageIngestion class]);
  OCMStub(ClassMethod([self.sut tokenKeyNameForPartition:mockPartition])).andReturn(mockTokenKeyName);
}

- (void)tearDown {
  [super tearDown];
  [self.sut stopMocking];
  [self.keychainUtilMock stopMocking];
  [self.ingestionStoreMock stopMocking];
}

- (void)testWhenNoCachedTokenNewTokenIsCached {
  
  // If
  NSObject *tokenData = [self getSuccessfulTokenData];
  NSMutableDictionary *tokenList = [@{kMSTokens : @[ tokenData ]} mutableCopy];
  NSData *jsonTokenData = [NSJSONSerialization dataWithJSONObject:tokenList
                                                          options:NSJSONWritingPrettyPrinted
                                                            error:nil];
  
  // Mock HTTP call returning fake token data.
  OCMStub([self.ingestionStoreMock sendAsync:OCMOCK_ANY completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    MSSendAsyncCompletionHandler completionBlock;
    [invocation getArgument:&completionBlock atIndex:3];
    NSHTTPURLResponse *response = [NSHTTPURLResponse new];
    id mockResponse = OCMPartialMock(response);
    OCMStub([mockResponse statusCode]).andReturn(MSHTTPCodesNo200OK);
    completionBlock(@"", mockResponse, jsonTokenData, nil);
  });
  
  // Mock returning nil for cached token.
  OCMStub([self.keychainUtilMock stringForKey:mockTokenKeyName]).andReturn(nil);
  OCMStub([self.keychainUtilMock storeString:OCMOCK_ANY forKey:OCMOCK_ANY]);
  XCTestExpectation *completeExpectation = [self expectationWithDescription:@"Task finished"];
  
  // When
  __block MSTokenResult *returnedTokenResult = nil;
  [MSTokenExchange performDbTokenAsyncOperationWithHttpClient:self.ingestionStoreMock
                                                    partition:mockPartition
                                            completionHandler:^(MSTokensResponse * tokenResponses, NSError *_Nullable returnError) {
                                              XCTAssertNil(returnError);
                                              returnedTokenResult = [tokenResponses tokens][0];
                                              NSString *tokenValue = returnedTokenResult.token;
                                              XCTAssertTrue([tokenValue isEqualToString:token]);
                                              [completeExpectation fulfill];
                                            }];
  
  // Then
  [self waitForExpectationsWithTimeout:5 handler:nil];
  OCMVerify([self.keychainUtilMock storeString:[returnedTokenResult serializeToString] forKey:mockTokenKeyName]);
}

- (void)testValidCachedTokenExists {
  
  // If
  NSData *tokenData = [NSJSONSerialization dataWithJSONObject:[self getSuccessfulTokenData] options:NSJSONWritingPrettyPrinted error:nil];
  NSString *tokenString = [[NSString alloc] initWithData:tokenData encoding:NSUTF8StringEncoding];
  
  // Mock returning valid cached token.
  MSTokenResult *result = [[MSTokenResult alloc] initWithString:tokenString];
  OCMStub(ClassMethod([self.sut retrieveCachedToken:mockPartition])).andReturn(result);
  
  // We should not call for new token if the cached valid.
  OCMReject([self.ingestionStoreMock sendAsync:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
  XCTestExpectation *completeExpectation = [self expectationWithDescription:@"Task finished"];
  
  // When
  [MSTokenExchange performDbTokenAsyncOperationWithHttpClient:self.ingestionStoreMock
                                                    partition:mockPartition
                                            completionHandler:^(MSTokensResponse * tokenResponses, NSError *_Nullable error) {
                                              XCTAssertNil(error);
                                              NSString *tokenValue = [tokenResponses tokens][0].token;
                                              XCTAssertTrue([tokenValue isEqualToString:token]);
                                              [completeExpectation fulfill];
                                            }];
  
  // Then
  [self waitForExpectationsWithTimeout:5 handler:nil];
  OCMVerifyAll(self.ingestionStoreMock);
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
  OCMStub(ClassMethod([self.sut removeCachedToken:mockPartition]));
  NSData *tokenData = [NSJSONSerialization dataWithJSONObject:[self getExpiredTokenData] options:NSJSONWritingPrettyPrinted error:nil];
  NSString *tokenString = [[NSString alloc] initWithData:tokenData encoding:NSUTF8StringEncoding];
  OCMStub([self.keychainUtilMock stringForKey:mockTokenKeyName]).andReturn(tokenString);
  OCMStub([self.ingestionStoreMock sendAsync:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
  
  // When
  [MSTokenExchange performDbTokenAsyncOperationWithHttpClient:self.ingestionStoreMock
                                                    partition:mockPartition
                                            completionHandler:^(MSTokensResponse * __unused tokenResponses, NSError *_Nullable __unused error) {
                                            }];
  
  // Then
  OCMVerify(ClassMethod([self.sut removeCachedToken:mockPartition]));
}

- (void)testCachedTokenNotFoundInKeychain {
  
  // If
  OCMStub([self.ingestionStoreMock sendAsync:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
  
  // Mock that there is no cached token.
  OCMStub([self.keychainUtilMock stringForKey:mockTokenKeyName]).andReturn(nil);
  
  // When
  [MSTokenExchange performDbTokenAsyncOperationWithHttpClient:self.ingestionStoreMock
                                                    partition:mockPartition
                                            completionHandler:^(MSTokensResponse * __unused tokenResponses, NSError *_Nullable __unused returnError) {
                                            }];
  
  // Then
  OCMVerify([self.ingestionStoreMock sendAsync:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
}

- (void)testExchangeServiceSerializationFails {
  
  // If
  // Mock that there is no cached token.
  OCMStub([self.keychainUtilMock stringForKey:mockTokenKeyName]).andReturn(nil);
  
  // Mock returning invalid token data.
  OCMStub([self.ingestionStoreMock sendAsync:OCMOCK_ANY completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __block MSSendAsyncCompletionHandler completionBlock;
    [invocation getArgument:&completionBlock atIndex:3];
    NSHTTPURLResponse *response = [NSHTTPURLResponse new];
    id mockResponse = OCMPartialMock(response);
    OCMStub([mockResponse statusCode]).andReturn(MSHTTPCodesNo200OK);
    completionBlock(@"", mockResponse, [NSData new], nil);
  });
  XCTestExpectation *completeExpectation = [self expectationWithDescription:@"Task finished"];
  
  // When
  [MSTokenExchange performDbTokenAsyncOperationWithHttpClient:self.ingestionStoreMock
                                                    partition:mockPartition
                                            completionHandler:^(MSTokensResponse * __unused tokenResponses, NSError *_Nullable returnError) {
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
  
  // Mock returning error.
  NSError *serviceError = [NSError new];
  OCMStub([self.ingestionStoreMock sendAsync:OCMOCK_ANY completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __block MSSendAsyncCompletionHandler completionBlock;
    [invocation getArgument:&completionBlock atIndex:3];
    NSHTTPURLResponse *response = [NSHTTPURLResponse new];
    id mockResponse = OCMPartialMock(response);
    OCMStub([mockResponse statusCode]).andReturn(MSHTTPCodesNo200OK);
    completionBlock(@"", mockResponse, [NSData new], serviceError);
  });
  XCTestExpectation *completeExpectation = [self expectationWithDescription:@"Task finished"];
  
  // When
  [MSTokenExchange performDbTokenAsyncOperationWithHttpClient:self.ingestionStoreMock
                                                    partition:mockPartition
                                            completionHandler:^(MSTokensResponse * __unused tokenResponses, NSError *_Nullable returnError) {
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
  
  // Mock returning failed token.
  NSObject *failedToken = [self getFailedTokenData];
  NSMutableDictionary *tokenList = [@{kMSTokens : @[ failedToken ]} mutableCopy];
  NSData *jsonTokenData = [NSJSONSerialization dataWithJSONObject:tokenList
                                                          options:NSJSONWritingPrettyPrinted
                                                            error:nil];
  OCMStub([self.ingestionStoreMock sendAsync:OCMOCK_ANY completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __block MSSendAsyncCompletionHandler completionBlock;
    [invocation getArgument:&completionBlock atIndex:3];
    NSHTTPURLResponse *response = [NSHTTPURLResponse new];
    id mockResponse = OCMPartialMock(response);
    OCMStub([mockResponse statusCode]).andReturn(MSHTTPCodesNo200OK);
    completionBlock(@"", mockResponse, jsonTokenData, nil);
  });
  XCTestExpectation *completeExpectation = [self expectationWithDescription:@"Task finished"];
  
  // When
  [MSTokenExchange performDbTokenAsyncOperationWithHttpClient:self.ingestionStoreMock
                                                    partition:mockPartition
                                            completionHandler:^(MSTokensResponse * __unused tokenResponses, NSError *_Nullable returnError) {
                                              XCTAssertNotNil(returnError);
                                              XCTAssertEqual([returnError code], MSDataStoreErrorHTTPError);
                                              [completeExpectation fulfill];
                                            }];
  
  // Then
  [self waitForExpectationsWithTimeout:5 handler:nil];
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
