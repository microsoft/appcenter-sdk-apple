// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#else
#import <UserNotifications/UserNotifications.h>
#endif

#import "MSCosmosDb.h"
#import "MSChannelGroupProtocol.h"
#import "MSChannelUnitProtocol.h"
#import "MSTestFrameworks.h"
#import "MSUserIdContextPrivate.h"
#import "MSDataStore.h"
#import "MSTokenResult.h"
#import "MSCosmosDbIngestion.h"
#import "MSDataStoreInternal.h"

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
+ (NSDictionary*) defaultHeaderWithPartition:(NSString *)partition
dbToken:(NSString *)dbToken
additionalHeaders:(NSDictionary *_Nullable)additionalHeaders;
+ (NSString*) documentUrlWithTokenResult: tokenResult documentId:(NSString *)documentId ;
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
    NSMutableDictionary *_Nullable additionalHeaders = [NSMutableDictionary new];
    [additionalHeaders setObject:@"Value1" forKey:@"Typy1"];
    [additionalHeaders setObject:@"Value2" forKey:@"Typy2"];
    [additionalHeaders setObject:@"Value3" forKey:@"Typy3"];
    NSDictionary *dic = [MSCosmosDb defaultHeaderWithPartition:@"partition"
                                                       dbToken:@"token"
                                             additionalHeaders:additionalHeaders];
    
    XCTAssertNotNil(dic);
    XCTAssertTrue(dic[@"Typy1"]);
    XCTAssertTrue(dic[@"Typy2"]);
    XCTAssertTrue(dic[@"Typy3"]);
}

- (void)testDefaultHeaderWithPartitionWithDictionaryNull {
    NSDictionary *dic = [MSCosmosDb defaultHeaderWithPartition:@"partition"
                                                       dbToken:@"token"
                                             additionalHeaders:nil];
    XCTAssertNotNil(dic);
    XCTAssertTrue(dic[@"Content-Type"]);
}

- (void)testDocumentUrlWithTokenResultWithStringToken {
    MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithString:@"token"];
    NSString *result = [MSCosmosDb documentUrlWithTokenResult:tokenResult
                                                              documentId:@"documentId"];
    XCTAssertNotNil(result);
}

- (void)testDocumentUrlWithTokenResultWithObjectToken {
    MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithPartition:@"token"
                                                                     dbAccount: @"dbAccount"
                                                                        dbName: @"dbName"
                                                              dbCollectionName: @"dbCollectionName"
                                                                         token: @"token"
                                                                        status: @"status"
                                                                     expiresOn: @"expiresOn"];
    NSString *result = [MSCosmosDb documentUrlWithTokenResult:tokenResult
                                                   documentId:@"documentId"];
    XCTAssertNotNil(result);
    XCTAssertTrue([result containsString:@"documentId"]);
    XCTAssertTrue([result containsString:@"dbAccount"]);
    XCTAssertTrue([result containsString:@"dbName"]);
    XCTAssertTrue([result containsString:@"dbCollectionName"]);
}

- (void)testDocumentUrlWithTokenResultWithDictionaryToken {
    NSMutableDictionary *_Nullable tokenResult = [NSMutableDictionary new];
    [tokenResult setObject:@"partition" forKey:@"partition"];
    [tokenResult setObject:@"dbAccount" forKey:@"dbAccount"];
    [tokenResult setObject:@"dbName" forKey:@"dbName"];
    [tokenResult setObject:@"dbCollectionName" forKey:@"dbCollectionName"];
    [tokenResult setObject:@"token" forKey:@"token"];
    [tokenResult setObject:@"status" forKey:@"status"];
    [tokenResult setObject:@"expiresOn" forKey:@"expiresOn"];
    
    NSString *result = [MSCosmosDb documentUrlWithTokenResult:tokenResult
                                                   documentId:@"documentId"];
    XCTAssertNotNil(result);
    XCTAssertTrue([result containsString:@"documentId"]);
    XCTAssertTrue([result containsString:@"dbAccount"]);
    XCTAssertTrue([result containsString:@"dbName"]);
    XCTAssertTrue([result containsString:@"dbCollectionName"]);
}

@end
