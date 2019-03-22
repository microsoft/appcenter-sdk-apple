// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSTestFrameworks.h"
#import "MSTokenResult.h"
#import "MSTokensResponse.h"
#import <Foundation/Foundation.h>

static NSString *const kMSPartition = @"partition";
static NSString *const kMSToken = @"token";
static NSString *const kMSStatus = @"status";
static NSString *const kMSDbName = @"dbName";
static NSString *const kMSDbAccount = @"dbAccount";
static NSString *const kMSDbCollectionName = @"dbCollectionName";
static NSString *const kMSExpiresOn = @"expiresOn";

static NSString *const partitionName = @"TestAppSecret";
static NSString *const token = @"mockToken";
static NSString *const status = @"Success";
static NSString *const dbName = @"mockDB";
static NSString *const dbAccount = @"mockAccount";
static NSString *const dbCollectionName = @"mockDBCollection";
static NSString *const expiresOn = @"mockDate";

@interface MSTokenTests : XCTestCase
- (NSDictionary *)deserializeDataString:(NSString *)dataString;

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
                                                         expiresOn:expiresOn];

  // Then
  XCTAssertTrue([partitionName isEqualToString:result.partition]);
  XCTAssertTrue([token isEqualToString:result.token]);
  XCTAssertTrue([status isEqualToString:result.status]);
  XCTAssertTrue([dbName isEqualToString:result.dbName]);
  XCTAssertTrue([dbCollectionName isEqualToString:result.dbCollectionName]);
  XCTAssertTrue([expiresOn isEqualToString:result.expiresOn]);
  XCTAssertTrue([dbAccount isEqualToString:result.dbAccount]);

  // When
  NSString *resultString = [result serializeToString];
  NSDictionary *resultDic = [self deserializeDataString:resultString];

  // Then
  XCTAssertTrue([partitionName isEqualToString:resultDic[kMSPartition]]);
  XCTAssertTrue([token isEqualToString:resultDic[kMSToken]]);
  XCTAssertTrue([status isEqualToString:resultDic[kMSStatus]]);
  XCTAssertTrue([dbName isEqualToString:resultDic[kMSDbName]]);
  XCTAssertTrue([dbAccount isEqualToString:resultDic[kMSDbAccount]]);
  XCTAssertTrue([dbCollectionName isEqualToString:resultDic[kMSDbCollectionName]]);
  XCTAssertTrue([expiresOn isEqualToString:resultDic[kMSExpiresOn]]);
}

- (void)testGetTokenResultWithString {

  // If
  NSString *tokenString =
      [NSString stringWithFormat:@"{\"%@\":\"%@\",\"%@\":\"%@\",\"%@\":\"%@\",\"%@\":\"%@\",\"%@\":\"%@\",\"%@\":\"%@\",\"%@\":\"%@\"}",
                                 kMSPartition, partitionName, kMSToken, token, kMSStatus, status, kMSDbName, dbName, kMSDbCollectionName,
                                 dbCollectionName, kMSExpiresOn, expiresOn, kMSDbAccount, dbAccount];

  // When
  MSTokenResult *result = [[MSTokenResult alloc] initWithString:tokenString];

  // Then
  XCTAssertTrue([partitionName isEqualToString:result.partition]);
  XCTAssertTrue([token isEqualToString:result.token]);
  XCTAssertTrue([status isEqualToString:result.status]);
  XCTAssertTrue([dbName isEqualToString:result.dbName]);
  XCTAssertTrue([dbCollectionName isEqualToString:result.dbCollectionName]);
  XCTAssertTrue([expiresOn isEqualToString:result.expiresOn]);
  XCTAssertTrue([dbAccount isEqualToString:result.dbAccount]);

  // When
  NSString *resultString = [result serializeToString];

  NSDictionary *resultDic = [self deserializeDataString:resultString];
  NSDictionary *tokenDic = [self deserializeDataString:tokenString];

  // Then
  XCTAssertTrue([resultDic isEqualToDictionary:tokenDic]);
}

- (void)testGetTokenResultWithDictionary {

  // If
  NSMutableDictionary *tokenDic = [@{
    kMSPartition : partitionName,
    kMSToken : token,
    kMSStatus : status,
    kMSDbName : dbName,
    kMSDbAccount : dbAccount,
    kMSDbCollectionName : dbCollectionName,
    kMSExpiresOn : expiresOn
  } mutableCopy];

  // When
  MSTokenResult *result = [[MSTokenResult alloc] initWithDictionary:tokenDic];

  // Then
  XCTAssertEqual(tokenDic[kMSPartition], result.partition);
  XCTAssertEqual(tokenDic[kMSToken], result.token);
  XCTAssertEqual(tokenDic[kMSStatus], result.status);
  XCTAssertEqual(tokenDic[kMSDbName], result.dbName);
  XCTAssertEqual(tokenDic[kMSDbAccount], result.dbAccount);
  XCTAssertEqual(tokenDic[kMSDbCollectionName], result.dbCollectionName);
  XCTAssertEqual(tokenDic[kMSExpiresOn], result.expiresOn);

  // When
  NSString *resultString = [result serializeToString];
  NSDictionary *resultDic = [self deserializeDataString:resultString];

  // Then
  XCTAssertTrue([resultDic isEqualToDictionary:tokenDic]);
}

- (void)testGetTokenResponseWithTokenList {

  // If
  NSMutableDictionary *tokenDic1 = [@{
    kMSPartition : partitionName,
    kMSToken : token,
    kMSStatus : status,
    kMSDbName : dbName,
    kMSDbAccount : dbAccount,
    kMSDbCollectionName : dbCollectionName,
    kMSExpiresOn : expiresOn
  } mutableCopy];
  MSTokenResult *token1 = [[MSTokenResult alloc] initWithDictionary:tokenDic1];

  NSMutableDictionary *tokenDic2 = [@{
    kMSPartition : [[NSString alloc] initWithFormat:@"%@Sec", partitionName],
    kMSToken : [[NSString alloc] initWithFormat:@"%@Sec", token],
    kMSStatus : [[NSString alloc] initWithFormat:@"%@Sec", status],
    kMSDbName : [[NSString alloc] initWithFormat:@"%@Sec", dbName],
    kMSDbAccount : [[NSString alloc] initWithFormat:@"%@Sec", dbAccount],
    kMSDbCollectionName : [[NSString alloc] initWithFormat:@"%@Sec", dbCollectionName],
    kMSExpiresOn : [[NSString alloc] initWithFormat:@"%@Sec", expiresOn]
  } mutableCopy];
  MSTokenResult *token2 = [[MSTokenResult alloc] initWithDictionary:tokenDic2];

  NSArray<MSTokenResult *> *tokenList = @[ token1, token2 ];

  // When
  MSTokensResponse *response = [[MSTokensResponse alloc] initWithTokens:tokenList];
  MSTokenResult *result = response.tokens[0];

  // Then
  XCTAssertEqual(result, token1);

  // When
  result = response.tokens[1];

  // Then
  XCTAssertEqual(result, token2);
}

- (void)testGetTokenResponseWithDictionary {

  // If
  NSObject *token1 = @{
    kMSPartition : partitionName,
    kMSToken : token,
    kMSStatus : status,
    kMSDbName : dbName,
    kMSDbAccount : dbAccount,
    kMSDbCollectionName : dbCollectionName,
    kMSExpiresOn : expiresOn
  };
  NSObject *token2 = @{
    kMSPartition : [[NSString alloc] initWithFormat:@"%@Sec", partitionName],
    kMSToken : [[NSString alloc] initWithFormat:@"%@Sec", token],
    kMSStatus : [[NSString alloc] initWithFormat:@"%@Sec", status],
    kMSDbName : [[NSString alloc] initWithFormat:@"%@Sec", dbName],
    kMSDbAccount : [[NSString alloc] initWithFormat:@"%@Sec", dbAccount],
    kMSDbCollectionName : [[NSString alloc] initWithFormat:@"%@Sec", dbCollectionName],
    kMSExpiresOn : [[NSString alloc] initWithFormat:@"%@Sec", expiresOn]
  };
  NSMutableDictionary *tokenList = [@{@"tokens" : @[ token1, token2 ]} mutableCopy];

  // When
  MSTokensResponse *response = [[MSTokensResponse alloc] initWithDictionary:tokenList];

  MSTokenResult *result = response.tokens[0];
  NSDictionary *tokenDic = tokenList[@"tokens"][0];

  // Then
  XCTAssertEqual(tokenDic[kMSPartition], result.partition);
  XCTAssertEqual(tokenDic[kMSToken], result.token);
  XCTAssertEqual(tokenDic[kMSStatus], result.status);
  XCTAssertEqual(tokenDic[kMSDbName], result.dbName);
  XCTAssertEqual(tokenDic[kMSDbAccount], result.dbAccount);
  XCTAssertEqual(tokenDic[kMSDbCollectionName], result.dbCollectionName);
  XCTAssertEqual(tokenDic[kMSExpiresOn], result.expiresOn);

  // When
  result = response.tokens[1];
  tokenDic = tokenList[@"tokens"][1];

  // Then
  XCTAssertEqual(tokenDic[kMSPartition], result.partition);
  XCTAssertEqual(tokenDic[kMSToken], result.token);
  XCTAssertEqual(tokenDic[kMSStatus], result.status);
  XCTAssertEqual(tokenDic[kMSDbName], result.dbName);
  XCTAssertEqual(tokenDic[kMSDbAccount], result.dbAccount);
  XCTAssertEqual(tokenDic[kMSDbCollectionName], result.dbCollectionName);
  XCTAssertEqual(tokenDic[kMSExpiresOn], result.expiresOn);
}

- (NSDictionary *)deserializeDataString:(NSString *)dataString {
  NSData *jsonData = [dataString dataUsingEncoding:NSUTF8StringEncoding];
  NSError *error = nil;
  return [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
}
@end
