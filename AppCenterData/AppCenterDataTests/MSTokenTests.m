// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSTestFrameworks.h"
#import "MSTokenResultPrivate.h"
#import "MSTokensResponse.h"

static NSString *const partitionName = @"TestAppSecret";
static NSString *const token = @"mockToken";
static NSString *const status = @"Success";
static NSString *const dbName = @"mockDB";
static NSString *const dbAccount = @"mockAccount";
static NSString *const dbCollectionName = @"mockDBCollection";
static NSString *const expiresOn = @"mockDate";
static NSString *const accountId = @"someAccountID123";

@interface MSTokenTests : XCTestCase

@end

@implementation MSTokenTests

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testGetTokenResult {

  // When
  MSTokenResult *result = [[MSTokenResult alloc] initWithPartition:partitionName
                                                         dbAccount:dbAccount
                                                            dbName:dbName
                                                  dbCollectionName:dbCollectionName
                                                             token:token
                                                            status:status
                                                         expiresOn:expiresOn
                                                         accountId:kMSAccountId];

  // Then
  [self compareWithTokenObject:result];

  // When
  NSString *resultString = [result serializeToString];
  NSDictionary *resultDic = [self deserializeDataString:resultString];

  // Then
  [self compareWithDictionary:resultDic];
}

- (void)testGetTokenResultWithString {

  // If
  NSData *tokenData = [NSJSONSerialization dataWithJSONObject:[self getDefaultTokenData] options:NSJSONWritingPrettyPrinted error:nil];
  NSString *tokenString = [[NSString alloc] initWithData:tokenData encoding:NSUTF8StringEncoding];

  // When
  MSTokenResult *result = [[MSTokenResult alloc] initWithString:tokenString];

  // Then
  [self compareWithTokenObject:result];

  // When
  NSString *resultString = [result serializeToString];
  NSDictionary *resultDic = [self deserializeDataString:resultString];
  NSDictionary *tokenDic = [self deserializeDataString:tokenString];

  // Then
  XCTAssertEqualObjects(resultDic, tokenDic);
}

- (void)testGetTokenResultWithWrongString {

  // If
  NSData *tokenData = [NSJSONSerialization dataWithJSONObject:[self getDefaultTokenData] options:NSJSONWritingPrettyPrinted error:nil];
  NSString *tokenString = [[NSString alloc] initWithData:tokenData encoding:NSUTF8StringEncoding];
  tokenString = [tokenString stringByReplacingOccurrencesOfString:@"\"" withString:@""];

  // When
  MSTokenResult *result = [[MSTokenResult alloc] initWithString:tokenString];

  // Then
  XCTAssertNil(result);
}

- (void)testGetTokenResultWithDictionary {

  // If
  NSMutableDictionary *tokenDic = [[self getDefaultTokenData] mutableCopy];

  // When
  MSTokenResult *result = [[MSTokenResult alloc] initWithDictionary:tokenDic];

  // Then
  [self compareTokenObject:result andDictinary:tokenDic];

  // When
  NSString *resultString = [result serializeToString];
  NSDictionary *resultDic = [self deserializeDataString:resultString];

  // Then
  XCTAssertEqualObjects(resultDic, tokenDic);
}

- (void)testGetTokenResponseWithTokenList {

  // If
  NSMutableDictionary *tokenDic1 = [[self getDefaultTokenData] mutableCopy];
  MSTokenResult *token1 = [[MSTokenResult alloc] initWithDictionary:tokenDic1];

  NSMutableDictionary *tokenDic2 = [[self getUpdateTokenData] mutableCopy];
  MSTokenResult *token2 = [[MSTokenResult alloc] initWithDictionary:tokenDic2];

  NSArray<MSTokenResult *> *tokenList = @[ token1, token2 ];

  // When
  MSTokensResponse *tokensResponse = [[MSTokensResponse alloc] initWithTokens:tokenList];
  MSTokenResult *result = tokensResponse.tokens.firstObject;

  // Then
  XCTAssertEqualObjects(result, token1);

  // When
  result = tokensResponse.tokens[1];

  // Then
  XCTAssertEqualObjects(result, token2);
}

- (void)testSerializedToStringFailed {

  // If
  id serialization = OCMClassMock([NSJSONSerialization class]);
  OCMStub(ClassMethod([serialization isValidJSONObject:OCMOCK_ANY])).andReturn(NO);
  NSData *tokenData = [NSJSONSerialization dataWithJSONObject:[self getDefaultTokenData] options:NSJSONWritingPrettyPrinted error:nil];
  NSString *tokenString = [[NSString alloc] initWithData:tokenData encoding:NSUTF8StringEncoding];

  // When
  MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithString:tokenString];
  NSString *serializedString = [tokenResult serializeToString];

  // Then
  XCTAssertNil(serializedString);
  [serialization stopMocking];
}

- (void)testGetTokenResponseWithDictionary {

  // If
  NSObject *token1 = [self getDefaultTokenData];
  NSObject *token2 = [self getUpdateTokenData];
  NSMutableDictionary *tokenList = [@{@"tokens" : @[ token1, token2 ]} mutableCopy];

  // When
  MSTokensResponse *tokensResponse = [[MSTokensResponse alloc] initWithDictionary:tokenList];

  MSTokenResult *result = tokensResponse.tokens.firstObject;
  NSDictionary *tokenDic = tokenList[@"tokens"][0];

  // Then
  [self compareTokenObject:result andDictinary:tokenDic];

  // When
  result = tokensResponse.tokens[1];
  tokenDic = tokenList[@"tokens"][1];

  // Then
  [self compareTokenObject:result andDictinary:tokenDic];
}

- (void)testConvertToDictionary {

  // If
  MSTokenResult *token1 = [[MSTokenResult alloc] initWithDictionary:(NSDictionary *)[self getDefaultTokenData]];
  MSTokenResult *token2 = [[MSTokenResult alloc] initWithDictionary:(NSDictionary *)[self getUpdateTokenData]];

  // When
  NSDictionary *dictionary1 = [token1 convertToDictionary];
  NSDictionary *dictionary2 = [token2 convertToDictionary];

  // Then
  [self compareTokenObject:token1 andDictinary:dictionary1];
  [self compareTokenObject:token2 andDictinary:dictionary2];
}

#pragma mark - Helper methods

- (NSObject *)getDefaultTokenData {
  return @{
    kMSPartition : partitionName,
    kMSToken : token,
    kMSStatus : status,
    kMSDbName : dbName,
    kMSDbAccount : dbAccount,
    kMSDbCollectionName : dbCollectionName,
    kMSExpiresOn : expiresOn,
    kMSAccountId : accountId
  };
}

- (NSObject *)getUpdateTokenData {
  return @{
    kMSPartition : [[NSString alloc] initWithFormat:@"%@Sec", partitionName],
    kMSToken : [[NSString alloc] initWithFormat:@"%@Sec", token],
    kMSStatus : [[NSString alloc] initWithFormat:@"%@Sec", status],
    kMSDbName : [[NSString alloc] initWithFormat:@"%@Sec", dbName],
    kMSDbAccount : [[NSString alloc] initWithFormat:@"%@Sec", dbAccount],
    kMSDbCollectionName : [[NSString alloc] initWithFormat:@"%@Sec", dbCollectionName],
    kMSExpiresOn : [[NSString alloc] initWithFormat:@"%@Sec", expiresOn]
  };
}

- (NSDictionary *)deserializeDataString:(NSString *)dataString {
  NSData *jsonData = [dataString dataUsingEncoding:NSUTF8StringEncoding];
  NSError *error = nil;
  return [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
}

- (void)compareWithTokenObject:(MSTokenResult *)tokenResult {
  XCTAssertEqualObjects(partitionName, tokenResult.partition);
  XCTAssertEqualObjects(token, tokenResult.token);
  XCTAssertEqualObjects(status, tokenResult.status);
  XCTAssertEqualObjects(dbName, tokenResult.dbName);
  XCTAssertEqualObjects(dbAccount, tokenResult.dbAccount);
  XCTAssertEqualObjects(dbCollectionName, tokenResult.dbCollectionName);
  XCTAssertEqualObjects(expiresOn, tokenResult.expiresOn);
}

- (void)compareWithDictionary:(NSDictionary *)tokenDic {
  XCTAssertEqualObjects(partitionName, tokenDic[kMSPartition]);
  XCTAssertEqualObjects(token, tokenDic[kMSToken]);
  XCTAssertEqualObjects(status, tokenDic[kMSStatus]);
  XCTAssertEqualObjects(dbName, tokenDic[kMSDbName]);
  XCTAssertEqualObjects(dbAccount, tokenDic[kMSDbAccount]);
  XCTAssertEqualObjects(dbCollectionName, tokenDic[kMSDbCollectionName]);
  XCTAssertEqualObjects(expiresOn, tokenDic[kMSExpiresOn]);
}

- (void)compareTokenObject:(MSTokenResult *)tokenResult andDictinary:(NSDictionary *)tokenDic {

  XCTAssertEqualObjects(tokenDic[kMSPartition], tokenResult.partition);
  XCTAssertEqualObjects(tokenDic[kMSToken], tokenResult.token);
  XCTAssertEqualObjects(tokenDic[kMSStatus], tokenResult.status);
  XCTAssertEqualObjects(tokenDic[kMSDbName], tokenResult.dbName);
  XCTAssertEqualObjects(tokenDic[kMSDbAccount], tokenResult.dbAccount);
  XCTAssertEqualObjects(tokenDic[kMSDbCollectionName], tokenResult.dbCollectionName);
  XCTAssertEqualObjects(tokenDic[kMSExpiresOn], tokenResult.expiresOn);
  if (tokenDic[kMSAccountId] == [NSNull null]) {
    XCTAssertNil(tokenResult.accountId);
  } else {
    XCTAssertEqualObjects(tokenDic[kMSAccountId], tokenResult.accountId);
  }
}
@end
