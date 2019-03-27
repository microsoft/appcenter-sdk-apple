// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSChannelGroupProtocol.h"
#import "MSChannelUnitProtocol.h"
#import "MSDataStore.h"
#import "MSDataStoreInternal.h"
#import "MSDataStorePrivate.h"
#import "MSMockUserDefaults.h"
#import "MSServiceAbstract.h"
#import "MSServiceAbstractProtected.h"
#import "MSTestFrameworks.h"
#import "MSUserIdContextPrivate.h"
#import "MSTokenExchange.h"
#import "MSTokenExchangePrivate.h"
#import "MSPaginatedDocuments.h"
#import "MSCosmosDbIngestion.h"
#import "MSHttpTestUtil.h"

static NSString *const kMSTestAppSecret = @"TestAppSecret";
static NSString *const kMSPartitionName = @"partition";
static NSString *const kMSDbAccountName = @"dbAccount";
static NSString *const kMSCollectionName = @"collection";
static NSString *const kMSToken = @"token";
static NSString *const kMSStatus = @"status";
static NSString *const kMSExpiresOn = @"date";

@interface MSDataStoreTests : XCTestCase

@property(nonatomic, strong) MSDataStore *sut;
@property(nonatomic) id settingsMock;
@property(nonatomic) id cosmosDbIngestionMock;

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

- (void)setUp {
  [super setUp];
  self.settingsMock = [MSMockUserDefaults new];
  self.sut = [MSDataStore new];
  
  // Create CosmosDBIngestion mock.
  self.cosmosDbIngestionMock = OCMPartialMock([MSCosmosDbIngestion alloc]);
  OCMStub([self.cosmosDbIngestionMock alloc]).andReturn(self.cosmosDbIngestionMock);
}

- (void)tearDown {
  [super tearDown];
  [MSDataStore resetSharedInstance];
  [self.settingsMock stopMocking];
  [self.cosmosDbIngestionMock stopMocking];
}

#pragma mark - Tests

- (void)testApplyEnabledStateWorks {

  // If
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                        appSecret:kMSTestAppSecret
          transmissionTargetToken:nil
                  fromApplication:YES];

  // When
  [self.sut setEnabled:YES];

  // Then
  XCTAssertTrue([self.sut isEnabled]);

  // When
  [self.sut setEnabled:NO];

  // Then
  XCTAssertFalse([self.sut isEnabled]);

  // When
  [self.sut setEnabled:YES];

  // Then
  XCTAssertTrue([self.sut isEnabled]);
}

- (void)testListDocumentsGoldenPath {
  [self.sut startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                        appSecret:kMSTestAppSecret
          transmissionTargetToken:nil
                  fromApplication:YES];
 
  // If
  id msTokenEchangeMock = OCMClassMock([MSTokenExchange class]);
  OCMStub([msTokenEchangeMock retrieveCachedToken:[OCMArg any]])
  .andReturn([[MSTokenResult alloc] initWithPartition:@"partition"
                                            dbAccount:@"account"
                                               dbName:@"db"
                                     dbCollectionName:@"collection"
                                                token:@"token"
                                               status:@"status"
                                            expiresOn:@"date"]);
  __block MSSendAsyncCompletionHandler cosmosDbIngestionBlock;
  OCMStub([self.cosmosDbIngestionMock sendAsync:OCMOCK_ANY completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    // Get ingestion block for later call.
    [invocation retainArguments];
    [invocation getArgument:&cosmosDbIngestionBlock atIndex:4];
  });
  
  // When
  [self.sut listWithPartition:@"partition" documentType:[SomeObject class] readOptions:nil continuationToken:nil completionHandler:^(MSPaginatedDocuments * _Nonnull documents) {
    
    BOOL hasNextPage = [documents hasNextPage];
    
  }];
  NSData *payload = [self getJsonFixture:@"listDocuments"];
  // Fails here because the block was not "captured"at line 138???
  cosmosDbIngestionBlock(@"callId", [MSHttpTestUtil createMockResponseForStatusCode:200 headers:nil], payload, nil);

}

/*
 * Utils.
 */

- (NSData *) getJsonFixture:(NSString *) fixture {
  NSBundle *bundle = [NSBundle bundleForClass:[self class]];
  NSString *path = [bundle pathForResource:fixture ofType:@"json"];
  return [NSData dataWithContentsOfFile:path];
}

@end
