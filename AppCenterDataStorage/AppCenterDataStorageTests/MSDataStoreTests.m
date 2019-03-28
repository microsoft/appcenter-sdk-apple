// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSChannelGroupProtocol.h"
#import "MSChannelUnitProtocol.h"
#import "MSCosmosDbIngestion.h"
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
#import "MSUserIdContextPrivate.h"

static NSTimeInterval const kMSTestExpectationTimeoutInSeconds = 1.0;
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
@property(nonatomic) id ingestionMock;

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
  self.ingestionMock = OCMClassMock([MSCosmosDbIngestion class]);
  OCMStub([self.ingestionMock new]).andReturn(self.ingestionMock);
}

- (void)tearDown {
  [super tearDown];
  [MSDataStore resetSharedInstance];
  [self.settingsMock stopMocking];
  [self.ingestionMock stopMocking];
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

// TODO: add more tests for list operation.
- (void)testListSingleDocument {
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

  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP Response 200"];
  OCMStub([self.ingestionMock sendAsync:OCMOCK_ANY completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    [invocation retainArguments];

    MSSendAsyncCompletionHandler ingestionBlock;
    [invocation getArgument:&ingestionBlock atIndex:3];
    NSData *payload = [self getJsonFixture:@"oneDocumentPage"];
    ingestionBlock(@"callId", [MSHttpTestUtil createMockResponseForStatusCode:200 headers:nil], payload, nil);
  });

  // When
  __block MSPaginatedDocuments *testDocuments;
  [self.sut listWithPartition:@"partition"
                 documentType:[SomeObject class]
                  readOptions:nil
            continuationToken:nil
            completionHandler:^(MSPaginatedDocuments *_Nonnull documents) {
              testDocuments = documents;
              [expectation fulfill];
            }];

  // Then
  [self waitForExpectationsWithTimeout:kMSTestExpectationTimeoutInSeconds
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 } else {
                                   // WIP do verification
                                   XCTAssertNotNil(testDocuments);
                                   XCTAssertFalse([testDocuments hasNextPage]);
                                   XCTAssertEqual([[testDocuments currentPage] items].count, 1);
                                   [testDocuments nextPageWithCompletionHandler:^(MSPage *page) {
                                     XCTAssertNil(page);
                                   }];
                                   MSDocumentWrapper<SomeObject *> *documentWrapper = [[testDocuments currentPage] items][0];
                                   XCTAssertTrue([[documentWrapper documentId] isEqualToString:@"doc1"]);
                                   XCTAssertNil([documentWrapper error]);
                                   // TODO: fix
                                   // XCTAssertNotNil([documentWrapper jsonValue]);
                                   XCTAssertTrue([[documentWrapper eTag] isEqualToString:@"etag value"]);
                                   XCTAssertTrue([[documentWrapper partition] isEqualToString:@"partition"]);
                                   XCTAssertNotNil([documentWrapper lastUpdatedDate]);
                                   SomeObject *deserializedDocument = [documentWrapper deserializedValue];
                                   XCTAssertNotNil(deserializedDocument);
                                   XCTAssertTrue([[deserializedDocument property1] isEqualToString:@"property 1 string"]);
                                   XCTAssertTrue([[deserializedDocument property2] isEqual:@42]);
                                 }
                               }];
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
