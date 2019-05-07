// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthTokenContext.h"
#import "MSConstants.h"
#import "MSData.h"
#import "MSDataConstants.h"
#import "MSDataErrors.h"
#import "MSHttpClientProtocol.h"
#import "MSHttpTestUtil.h"
#import "MSKeychainUtil.h"
#import "MSMockKeychainUtil.h"
#import "MSTestFrameworks.h"
#import "MSTokenExchange.h"
#import "MSTokenResult.h"
#import "MSTokenResultPrivate.h"
#import "MSTokensResponse.h"
#import "MSUtility+Date.h"

static NSString *const kMSExpiredDate = @"1999-09-19T11:11:11.111Z";
static NSString *const kMSNotExpiredDate = @"2999-09-19T11:11:11.111Z";
static NSString *const kMSMockTokenValue = @"mock-token";
static NSString *const kMSMockTokenKeyName = @"mock-token-key-name";

static NSString *const kMSCachedToken = @"mockCachedToken";
static NSString *const kMSStorageReadOnlyDbTokenKey = @"MSStorageReadOnlyDbToken";
static NSString *const kMSStorageUserDbTokenKey = @"MSStorageUserDbToken";

@interface MSTokenExchange (Test)

+ (NSString *)tokenKeyNameForPartition:(NSString *)partitionName;
+ (void)saveToken:(MSTokenResult *)tokenResult;

@end

@interface MSTokenExchangeTests : XCTestCase

@property(nonatomic) id keychainUtilMock;
@property(nonatomic) id sut;
@property(nonatomic) id reachabilityMock;
@end

@implementation MSTokenExchangeTests

- (void)setUp {
  [super setUp];
  self.sut = OCMClassMock([MSTokenExchange class]);
  self.keychainUtilMock = [MSMockKeychainUtil new];
  OCMStub(ClassMethod([self.sut tokenKeyNameForPartition:kMSDataUserDocumentsPartition])).andReturn(kMSMockTokenKeyName);
  self.reachabilityMock = OCMClassMock([MS_Reachability class]);
  OCMStub([self.reachabilityMock reachabilityForInternetConnection]).andReturn(self.reachabilityMock);
  OCMStub([self.reachabilityMock currentReachabilityStatus]).andReturn(ReachableViaWiFi);
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

  OCMStub(ClassMethod([self.sut tokenKeyNameForPartition:kMSDataUserDocumentsPartition])).andReturn(nil);

  // Create instance of MSAuthTokenContext to mock.
  id contextInstanceMock = OCMPartialMock([MSAuthTokenContext sharedInstance]);

  // Stub method on mocked instance.
  OCMStub([contextInstanceMock authToken]).andReturn(@"fake-token");

  // Make static method always return mocked instance with stubbed method.
  OCMStub(ClassMethod([MSAuthTokenContext sharedInstance])).andReturn(contextInstanceMock);
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
  XCTestExpectation *completeExpectation = [self expectationWithDescription:@"Task finished"];

  // When
  __block MSTokenResult *returnedTokenResult = nil;
  [MSTokenExchange performDbTokenAsyncOperationWithHttpClient:httpMock
                                             tokenExchangeUrl:[NSURL new]
                                                    appSecret:@"appSecret"
                                                    partition:kMSDataUserDocumentsPartition
                                          includeExpiredToken:NO
                                                 reachability:self.reachabilityMock
                                            completionHandler:^(MSTokensResponse *tokensResponse, NSError *_Nullable returnError) {
                                              XCTAssertNil(returnError);
                                              returnedTokenResult = [tokensResponse tokens][0];
                                              NSString *tokenValue = returnedTokenResult.token;
                                              XCTAssertTrue([tokenValue isEqualToString:kMSMockTokenValue]);
                                              [completeExpectation fulfill];
                                            }];
  [self waitForExpectationsWithTimeout:5
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }

                                 // Then
                                 XCTAssertEqualObjects([returnedTokenResult serializeToString],
                                                       [MSKeychainUtil stringForKey:kMSMockTokenKeyName]);
                                 XCTAssertEqualObjects(actualHeaders[@"Authorization"], @"Bearer fake-token");
                                 XCTAssertEqualObjects(actualHeaders[@"Content-Type"], @"application/json");
                                 XCTAssertEqualObjects(actualHeaders[@"App-Secret"], @"appSecret");
                               }];
  [contextInstanceMock stopMocking];
}

- (void)testRequestTokenFailedAuthentication {

  // If
  NSObject *tokenData = [self getUnauthenticatedTokenData];
  NSMutableDictionary *tokenList = [@{kMSTokens : @[ tokenData ]} mutableCopy];
  NSData *jsonTokenData = [NSJSONSerialization dataWithJSONObject:tokenList options:NSJSONWritingPrettyPrinted error:nil];

  OCMStub(ClassMethod([self.sut tokenKeyNameForPartition:kMSDataUserDocumentsPartition])).andReturn(nil);

  // Create instance of MSAuthTokenContext to mock.
  id contextInstanceMock = OCMPartialMock([MSAuthTokenContext sharedInstance]);

  // Stub method on mocked instance.
  OCMStub([contextInstanceMock authToken]).andReturn(@"fake-token");

  // Make static method always return mocked instance with stubbed method.
  OCMStub(ClassMethod([MSAuthTokenContext sharedInstance])).andReturn(contextInstanceMock);
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
  XCTestExpectation *completeExpectation = [self expectationWithDescription:@"Task finished"];

  // When
  [MSTokenExchange performDbTokenAsyncOperationWithHttpClient:httpMock
                                             tokenExchangeUrl:[NSURL new]
                                                    appSecret:@"appSecret"
                                                    partition:kMSDataUserDocumentsPartition
                                          includeExpiredToken:NO
                                                 reachability:self.reachabilityMock
                                            completionHandler:^(__unused MSTokensResponse *tokensResponse, NSError *_Nullable returnError) {
                                              XCTAssertEqual(returnError.code, MSACDataErrorHTTPError);
                                              [completeExpectation fulfill];
                                            }];
  [self waitForExpectationsWithTimeout:5
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Failed with error: %@ due to timeout.", error);
                                 }
                               }];
  [contextInstanceMock stopMocking];
}

- (void)testRequestTokenInvalidResponse {

  // If
  NSMutableDictionary *tokenList = [@{kMSTokens : @[]} mutableCopy];
  NSData *jsonTokenData = [NSJSONSerialization dataWithJSONObject:tokenList options:NSJSONWritingPrettyPrinted error:nil];

  OCMStub(ClassMethod([self.sut tokenKeyNameForPartition:kMSDataUserDocumentsPartition])).andReturn(nil);

  // Create instance of MSAuthTokenContext to mock.
  id contextInstanceMock = OCMPartialMock([MSAuthTokenContext sharedInstance]);

  // Stub method on mocked instance.
  OCMStub([contextInstanceMock authToken]).andReturn(@"fake-token");

  // Make static method always return mocked instance with stubbed method.
  OCMStub(ClassMethod([MSAuthTokenContext sharedInstance])).andReturn(contextInstanceMock);
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
  XCTestExpectation *completeExpectation = [self expectationWithDescription:@"Task finished"];

  // When
  [MSTokenExchange performDbTokenAsyncOperationWithHttpClient:httpMock
                                             tokenExchangeUrl:[NSURL new]
                                                    appSecret:@"appSecret"
                                                    partition:kMSDataUserDocumentsPartition
                                          includeExpiredToken:NO
                                                 reachability:self.reachabilityMock
                                            completionHandler:^(__unused MSTokensResponse *tokensResponse, NSError *_Nullable returnError) {
                                              XCTAssertEqual(returnError.code, MSACDataErrorInvalidTokenExchangeResponse);
                                              [completeExpectation fulfill];
                                            }];
  [self waitForExpectationsWithTimeout:0
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Failed with error: %@ due to timeout.", error);
                                 }
                               }];
  [contextInstanceMock stopMocking];
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
  [[MSAuthTokenContext sharedInstance] setAuthToken:nil withAccountId:nil expiresOn:nil];
  XCTestExpectation *completeExpectation = [self expectationWithDescription:@"Task finished"];

  // When
  __block MSTokenResult *returnedTokenResult = nil;
  [MSTokenExchange performDbTokenAsyncOperationWithHttpClient:httpMock
                                             tokenExchangeUrl:[NSURL new]
                                                    appSecret:@"appSecret"
                                                    partition:kMSDataAppDocumentsPartition
                                          includeExpiredToken:NO
                                                 reachability:self.reachabilityMock
                                            completionHandler:^(MSTokensResponse *tokensResponse, NSError *_Nullable returnError) {
                                              XCTAssertNil(returnError);
                                              returnedTokenResult = [tokensResponse tokens][0];
                                              NSString *tokenValue = returnedTokenResult.token;
                                              XCTAssertTrue([tokenValue isEqualToString:kMSMockTokenValue]);
                                              [completeExpectation fulfill];
                                            }];
  [self waitForExpectationsWithTimeout:5
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }

                                 // Then
                                 XCTAssertEqualObjects([returnedTokenResult serializeToString],
                                                       [MSKeychainUtil stringForKey:kMSMockTokenKeyName]);
                                 XCTAssertNil(actualHeaders[@"Authorization"]);
                                 XCTAssertEqualObjects(actualHeaders[@"Content-Type"], @"application/json");
                                 XCTAssertEqualObjects(actualHeaders[@"App-Secret"], @"appSecret");
                               }];
}

- (void)testValidCachedTokenExists {

  // If
  NSData *tokenData = [NSJSONSerialization dataWithJSONObject:[self getSuccessfulTokenData] options:NSJSONWritingPrettyPrinted error:nil];
  NSString *tokenString = [[NSString alloc] initWithData:tokenData encoding:NSUTF8StringEncoding];
  [MSKeychainUtil storeString:tokenString forKey:kMSMockTokenKeyName];
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
                                                    partition:kMSDataUserDocumentsPartition
                                          includeExpiredToken:NO
                                                 reachability:self.reachabilityMock
                                            completionHandler:^(MSTokensResponse *tokensResponse, NSError *_Nullable error) {
                                              // Then
                                              XCTAssertNil(error);
                                              NSString *tokenValue = [tokensResponse tokens][0].token;
                                              XCTAssertTrue([tokenValue isEqualToString:kMSMockTokenValue]);
                                              [completeExpectation fulfill];
                                            }];
  [self waitForExpectationsWithTimeout:5
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
  [utilityMock stopMocking];
}

- (void)testWhenOfflineAndNoCachedTokenFound {

  // If
  NSData *tokenData = [NSJSONSerialization dataWithJSONObject:[self getSuccessfulTokenData] options:NSJSONWritingPrettyPrinted error:nil];
  NSString *tokenString = [[NSString alloc] initWithData:tokenData encoding:NSUTF8StringEncoding];
  [MSKeychainUtil storeString:tokenString forKey:kMSMockTokenKeyName];
  id utilityMock = OCMClassMock([MSUtility class]);
  id<MSHttpClientProtocol> httpMock = OCMProtocolMock(@protocol(MSHttpClientProtocol));

  // Mock returning expire date.
  OCMStub(ClassMethod([utilityMock dateFromISO8601:OCMOCK_ANY])).andReturn([NSDate dateWithTimeIntervalSinceNow:-100000]);

  // We should not call for new token when network is disconnected
  id nonReachabilityMock = OCMClassMock([MS_Reachability class]);
  OCMStub([nonReachabilityMock reachabilityForInternetConnection]).andReturn(nonReachabilityMock);
  OCMStub([nonReachabilityMock currentReachabilityStatus]).andReturn(NotReachable);
  XCTestExpectation *completeExpectation = [self expectationWithDescription:@"Task finished"];

  // When
  [MSTokenExchange performDbTokenAsyncOperationWithHttpClient:httpMock
                                             tokenExchangeUrl:[NSURL new]
                                                    appSecret:@"appSecret"
                                                    partition:kMSDataUserDocumentsPartition
                                          includeExpiredToken:NO
                                                 reachability:nonReachabilityMock
                                            completionHandler:^(MSTokensResponse __unused *tokensResponse, NSError *_Nullable error) {
                                              // Then
                                              XCTAssertNotNil(error);
                                              XCTAssertEqual(error.code, MSACDataErrorUnableToGetToken);
                                              [completeExpectation fulfill];
                                            }];
  [self waitForExpectationsWithTimeout:5
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
  [utilityMock stopMocking];
}

- (void)testReadTokenFromCacheWhenTokenResultStatusFailed {

  // If
  NSData *tokenData = [NSJSONSerialization dataWithJSONObject:[self getFailedTokenData] options:NSJSONWritingPrettyPrinted error:nil];
  NSString *tokenString = [[NSString alloc] initWithData:tokenData encoding:NSUTF8StringEncoding];
  [MSKeychainUtil storeString:tokenString forKey:kMSMockTokenKeyName];
  id<MSHttpClientProtocol> httpMock = OCMProtocolMock(@protocol(MSHttpClientProtocol));

  // Mock returning failed token.
  NSObject *failedToken = [self getFailedTokenData];
  NSMutableDictionary *tokenList = [@{kMSTokens : @[ failedToken ]} mutableCopy];
  NSData *jsonTokenData = [NSJSONSerialization dataWithJSONObject:tokenList options:NSJSONWritingPrettyPrinted error:nil];
  OCMStub([httpMock sendAsync:OCMOCK_ANY method:OCMOCK_ANY headers:OCMOCK_ANY data:OCMOCK_ANY completionHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        MSHttpRequestCompletionHandler completionBlock;
        [invocation getArgument:&completionBlock atIndex:6];
        NSHTTPURLResponse *response = [NSHTTPURLResponse new];
        id mockResponse = OCMPartialMock(response);
        OCMStub([mockResponse statusCode]).andReturn(MSHTTPCodesNo404NotFound);
        completionBlock(jsonTokenData, mockResponse, nil);
      });
  XCTestExpectation *completeExpectation = [self expectationWithDescription:@"Task finished"];

  // When
  [MSTokenExchange performDbTokenAsyncOperationWithHttpClient:httpMock
                                             tokenExchangeUrl:[NSURL new]
                                                    appSecret:@"appSecret"
                                                    partition:kMSDataUserDocumentsPartition
                                          includeExpiredToken:NO
                                                 reachability:self.reachabilityMock
                                            completionHandler:^(MSTokensResponse *tokensResponse, NSError *_Nullable returnError) {
                                              // Then
                                              XCTAssertNotNil(returnError);
                                              XCTAssertEqual([tokensResponse tokens].count, 0);
                                              [completeExpectation fulfill];
                                            }];
  [self waitForExpectationsWithTimeout:5
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testCachedTokenNotFoundInKeychain {

  // If
  id<MSHttpClientProtocol> httpMock = OCMProtocolMock(@protocol(MSHttpClientProtocol));
  OCMStub([httpMock sendAsync:OCMOCK_ANY method:OCMOCK_ANY headers:OCMOCK_ANY data:OCMOCK_ANY completionHandler:OCMOCK_ANY]);

  // When
  [MSTokenExchange
      performDbTokenAsyncOperationWithHttpClient:httpMock
                                tokenExchangeUrl:[NSURL new]
                                       appSecret:@"appSecret"
                                       partition:kMSDataUserDocumentsPartition
                             includeExpiredToken:NO
                                    reachability:self.reachabilityMock
                               completionHandler:^(MSTokensResponse *__unused tokensResponse, NSError *_Nullable __unused returnError){
                               }];

  // Then
  OCMVerify([httpMock sendAsync:OCMOCK_ANY method:OCMOCK_ANY headers:OCMOCK_ANY data:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
}

- (void)testExchangeServiceSerializationFails {

  // If
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
                                                    partition:kMSDataUserDocumentsPartition
                                          includeExpiredToken:NO
                                                 reachability:self.reachabilityMock
                                            completionHandler:^(MSTokensResponse *__unused tokensResponse, NSError *_Nullable returnError) {
                                              // Then
                                              XCTAssertNotNil(returnError);
                                              XCTAssertEqual(returnError.code, MSACDataErrorJSONSerializationFailed);
                                              [completeExpectation fulfill];
                                            }];
  [self waitForExpectationsWithTimeout:5
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testExchangeServiceReturnsError {

  // If
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
                                                    partition:kMSDataUserDocumentsPartition
                                          includeExpiredToken:NO
                                                 reachability:self.reachabilityMock
                                            completionHandler:^(MSTokensResponse *__unused tokensResponse, NSError *_Nullable returnError) {
                                              // Then
                                              XCTAssertEqual(returnError, serviceError);
                                              [completeExpectation fulfill];
                                            }];
  [self waitForExpectationsWithTimeout:5
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testPassInvalidPartitionToTokenExchangeReturnsError {

  // If
  NSString *invalidPartitionName = @"Invalid Partition Name";
  id<MSHttpClientProtocol> httpMock = OCMProtocolMock(@protocol(MSHttpClientProtocol));
  XCTestExpectation *completeExpectation = [self expectationWithDescription:@"Task finished"];

  // When
  [MSTokenExchange performDbTokenAsyncOperationWithHttpClient:httpMock
                                             tokenExchangeUrl:[NSURL new]
                                                    appSecret:@"appSecret"
                                                    partition:invalidPartitionName
                                          includeExpiredToken:NO
                                                 reachability:self.reachabilityMock
                                            completionHandler:^(MSTokensResponse *__unused tokensResponse, NSError *_Nullable returnError) {
                                              // Then
                                              XCTAssertEqual(returnError.code, MSACDataErrorInvalidPartition);
                                              [completeExpectation fulfill];
                                            }];
  [self waitForExpectationsWithTimeout:5
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testExchangeServiceReturnsTokenError {

  // If
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
                                                    partition:kMSDataUserDocumentsPartition
                                          includeExpiredToken:NO
                                                 reachability:self.reachabilityMock
                                            completionHandler:^(MSTokensResponse *__unused tokensResponse, NSError *_Nullable returnError) {
                                              // Then
                                              XCTAssertNotNil(returnError);
                                              XCTAssertEqual([returnError code], MSACDataErrorHTTPError);
                                              [completeExpectation fulfill];
                                            }];
  [self waitForExpectationsWithTimeout:5
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

- (void)testSaveTokenFails {

  // When
  [MSTokenExchange saveToken:nil];

  // Then
  XCTAssertNil([MSKeychainUtil stringForKey:kMSMockTokenKeyName]);
}

- (void)testSaveTokenFailsWithoutPartition {

  // If
  NSData *tokenData = [NSJSONSerialization dataWithJSONObject:[self getSuccessfulTokenData] options:NSJSONWritingPrettyPrinted error:nil];
  NSString *tokenString = [[NSString alloc] initWithData:tokenData encoding:NSUTF8StringEncoding];
  MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithString:tokenString];
  id mockResult = OCMPartialMock(tokenResult);
  OCMStub([mockResult partition]).andReturn(nil);
  OCMStub([mockResult serializeToString]).andReturn(@"string");

  // When
  [MSTokenExchange saveToken:mockResult];

  // Then
  XCTAssertNil([MSKeychainUtil stringForKey:kMSMockTokenKeyName]);
}

- (void)testRemoveAllTokens {

  // If
  [MSKeychainUtil storeString:@"a" forKey:kMSStorageReadOnlyDbTokenKey];
  [MSKeychainUtil storeString:@"a" forKey:kMSStorageUserDbTokenKey];
  XCTAssertNotNil([MSKeychainUtil stringForKey:kMSStorageReadOnlyDbTokenKey]);
  XCTAssertNotNil([MSKeychainUtil stringForKey:kMSStorageUserDbTokenKey]);

  // When
  [MSTokenExchange removeAllCachedTokens];

  // Then
  XCTAssertNil([MSKeychainUtil stringForKey:kMSStorageReadOnlyDbTokenKey]);
  XCTAssertNil([MSKeychainUtil stringForKey:kMSStorageUserDbTokenKey]);
}

- (void)testTokenKeyNameForPartitionReturnsReadOnlyKey {

  // When
  NSString *tokenKeyName = [MSTokenExchange tokenKeyNameForPartition:kMSDataAppDocumentsPartition];

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

- (void)testRetrieveCachedTokenWhenExpiredTokenResultIsCachedAndIncludeExpiredIsYes {

  // If
  // An expired token is cached.
  NSData *tokenData = [NSJSONSerialization dataWithJSONObject:[self getExpiredTokenData] options:NSJSONWritingPrettyPrinted error:nil];
  NSString *tokenString = [[NSString alloc] initWithData:tokenData encoding:NSUTF8StringEncoding];
  [MSKeychainUtil storeString:tokenString forKey:kMSMockTokenKeyName];

  // When
  // Retrieve token and include it even when expired.
  MSTokenResult *tokenResult = [MSTokenExchange retrieveCachedTokenForPartition:kMSDataUserDocumentsPartition includeExpiredToken:YES];

  // Then
  XCTAssertNotNil(tokenResult);
  XCTAssertEqualObjects(tokenResult.expiresOn, kMSExpiredDate);
  XCTAssertEqualObjects(tokenResult.status, kMSTokenResultSucceed);
  XCTAssertEqualObjects(tokenResult.token, kMSMockTokenValue);
}

- (void)testRetrieveCachedTokenWhenExpiredTokenResultIsCachedAndIncludeExpiredIsNo {

  // If
  // An expired token is cached.
  NSData *tokenData = [NSJSONSerialization dataWithJSONObject:[self getExpiredTokenData] options:NSJSONWritingPrettyPrinted error:nil];
  NSString *tokenString = [[NSString alloc] initWithData:tokenData encoding:NSUTF8StringEncoding];
  [MSKeychainUtil storeString:tokenString forKey:kMSMockTokenKeyName];

  // When
  // Retrieve token and include it even when expired.
  MSTokenResult *tokenResult = [MSTokenExchange retrieveCachedTokenForPartition:kMSDataUserDocumentsPartition includeExpiredToken:NO];

  // Then
  XCTAssertNil(tokenResult);
}

- (void)testRetrieveCachedTokenWhenNotExpiredTokenResultIsCachedAndIncludeExpiredIsNo {

  // If
  // An expired token is cached.
  NSData *tokenData = [NSJSONSerialization dataWithJSONObject:[self getSuccessfulTokenData] options:NSJSONWritingPrettyPrinted error:nil];
  NSString *tokenString = [[NSString alloc] initWithData:tokenData encoding:NSUTF8StringEncoding];
  [MSKeychainUtil storeString:tokenString forKey:kMSMockTokenKeyName];

  // When
  // Retrieve token and include it even when expired.
  MSTokenResult *tokenResult = [MSTokenExchange retrieveCachedTokenForPartition:kMSDataUserDocumentsPartition includeExpiredToken:NO];

  // Then
  XCTAssertNotNil(tokenResult);
  XCTAssertEqualObjects(tokenResult.expiresOn, kMSNotExpiredDate);
  XCTAssertEqualObjects(tokenResult.status, kMSTokenResultSucceed);
  XCTAssertEqualObjects(tokenResult.token, kMSMockTokenValue);
}

- (NSObject *)getExpiredTokenData {
  return @{
    kMSPartition : @"",
    kMSToken : kMSMockTokenValue,
    kMSStatus : kMSTokenResultSucceed,
    kMSDbName : @"",
    kMSDbAccount : @"",
    kMSDbCollectionName : @"",
    kMSExpiresOn : kMSExpiredDate
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
    kMSExpiresOn : kMSExpiredDate
  };
}

- (NSObject *)getSuccessfulTokenData {
  return @{
    kMSPartition : kMSDataUserDocumentsPartition,
    kMSToken : kMSMockTokenValue,
    kMSStatus : kMSTokenResultSucceed,
    kMSDbName : @"",
    kMSDbAccount : @"",
    kMSDbCollectionName : @"",
    kMSExpiresOn : kMSNotExpiredDate
  };
}

- (NSObject *)getUnauthenticatedTokenData {
  return @{
    kMSPartition : @"",
    kMSToken : @"",
    kMSStatus : @"Unauthenticated",
    kMSDbName : @"",
    kMSDbAccount : @"",
    kMSDbCollectionName : @"",
    kMSExpiresOn : @""
  };
}

@end
