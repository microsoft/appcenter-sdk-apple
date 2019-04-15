// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSBaseOptions.h"
#import "MSDBDocumentStore.h"
#import "MSDataOperationProxy.h"
#import "MSDataSourceError.h"
#import "MSDataStorageConstants.h"
#import "MSDataStoreErrors.h"
#import "MSDictionaryDocument.h"
#import "MSDocumentWrapperInternal.h"
#import "MSTestFrameworks.h"
#import "MSTokenResult.h"

@interface MSDataOperationProxyTests : XCTestCase

@property(nonatomic) MSDataOperationProxy *sut;
@property(nonatomic) id documentStoreMock;

@end

@implementation MSDataOperationProxyTests

- (void)setUp {
  _documentStoreMock = OCMClassMock([MSDBDocumentStore class]);
  self.sut = [[MSDataOperationProxy alloc] initWithDocumentStore:_documentStoreMock];
  [super setUp];
}

- (void)tearDown {
  [self.documentStoreMock stopMocking];
  [super tearDown];
}

- (void)testInvalidOperation {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completed with error for invalid operation."];
  __block MSDocumentWrapper *wrapper;

  // When
  [self.sut performOperation:@"badOperation"
      documentId:@"documentId"
      documentType:[NSString class]
      document:nil
      baseOptions:nil
      cachedTokenBlock:^(MSCachedTokenCompletionHandler _Nonnull __unused handler) {
      }
      remoteDocumentBlock:^(MSDocumentWrapperCompletionHandler _Nonnull __unused handler) {
      }
      completionHandler:^(MSDocumentWrapper *_Nonnull document) {
        wrapper = document;
        [expectation fulfill];
      }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertEqual(wrapper.documentId, @"documentId");
                                 XCTAssertEqual(wrapper.deserializedValue, nil);
                                 XCTAssertNotNil(wrapper.error);
                                 XCTAssertEqual(wrapper.error.error.code, MSACDataStoreLocalStoreError);
                               }];
}

- (void)testInvalidToken {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completed with error retrieving token."];
  __block NSError *tokenError;
  __block MSDocumentWrapper *wrapper;

  // When
  [self.sut performOperation:nil
      documentId:@"documentId"
      documentType:[NSString class]
      document:nil
      baseOptions:nil
      cachedTokenBlock:^(MSCachedTokenCompletionHandler _Nonnull handler) {
        tokenError = [NSError new];
        handler(nil, tokenError);
      }
      remoteDocumentBlock:^(MSDocumentWrapperCompletionHandler _Nonnull __unused handler) {
      }
      completionHandler:^(MSDocumentWrapper *_Nonnull document) {
        wrapper = document;
        [expectation fulfill];
      }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertEqual(wrapper.documentId, @"documentId");
                                 XCTAssertEqual(wrapper.deserializedValue, nil);
                                 XCTAssertEqual(wrapper.error.error.code, MSACDataStoreLocalStoreError);
                               }];
}

- (void)testRemoteOperationWhenNoDocumentInStoreAndDefaultTTL {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completed with remote document (default TTL)."];
  __block MSDocumentWrapper *remoteDocumentWrapper = [MSDocumentWrapper alloc];
  __block MSDocumentWrapper *wrapper;
  OCMStub([self.documentStoreMock readWithToken:OCMOCK_ANY documentId:OCMOCK_ANY documentType:OCMOCK_ANY])
      .andReturn([[MSDocumentWrapper alloc] initWithError:[NSError new] documentId:@"documentId"]);
  MSTokenResult *token = [MSTokenResult alloc];
  __block MSTokensResponse *response = [[MSTokensResponse alloc] initWithTokens:@[ token ]];

  // When
  [self.sut performOperation:nil
      documentId:@"documentId"
      documentType:[NSString class]
      document:nil
      baseOptions:nil
      cachedTokenBlock:^(MSCachedTokenCompletionHandler _Nonnull handler) {
        handler(response, nil);
      }
      remoteDocumentBlock:^(MSDocumentWrapperCompletionHandler _Nonnull handler) {
        handler(remoteDocumentWrapper);
      }
      completionHandler:^(MSDocumentWrapper *_Nonnull document) {
        wrapper = document;
        [expectation fulfill];
      }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertEqual(wrapper, remoteDocumentWrapper);
                                 OCMVerify([self.documentStoreMock upsertWithToken:token
                                                                   documentWrapper:remoteDocumentWrapper
                                                                         operation:nil
                                                                  deviceTimeToLive:kMSDataStoreTimeToLiveDefault]);
                               }];
}

- (void)testRemoteOperationWhenNoDocumentInStoreAndNoCache {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completed with remote document (no cache)."];
  __block MSDocumentWrapper *remoteDocumentWrapper = [MSDocumentWrapper alloc];
  __block MSDocumentWrapper *wrapper;
  OCMStub([self.documentStoreMock readWithToken:OCMOCK_ANY documentId:OCMOCK_ANY documentType:OCMOCK_ANY])
      .andReturn([[MSDocumentWrapper alloc] initWithError:[NSError new] documentId:@"documentId"]);
  MSTokenResult *token = [MSTokenResult alloc];
  __block MSTokensResponse *response = [[MSTokensResponse alloc] initWithTokens:@[ token ]];

  // When
  [self.sut performOperation:nil
      documentId:@"documentId"
      documentType:[NSString class]
      document:nil
      baseOptions:[[MSBaseOptions alloc] initWithDeviceTimeToLive:kMSDataStoreTimeToLiveNoCache]
      cachedTokenBlock:^(MSCachedTokenCompletionHandler _Nonnull handler) {
        handler(response, nil);
      }
      remoteDocumentBlock:^(MSDocumentWrapperCompletionHandler _Nonnull handler) {
        handler(remoteDocumentWrapper);
      }
      completionHandler:^(MSDocumentWrapper *_Nonnull document) {
        wrapper = document;
        [expectation fulfill];
      }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertEqual(wrapper, remoteDocumentWrapper);
                                 OCMReject([[self.documentStoreMock ignoringNonObjectArgs] upsertWithToken:OCMOCK_ANY
                                                                                           documentWrapper:OCMOCK_ANY
                                                                                                 operation:OCMOCK_ANY
                                                                                          deviceTimeToLive:0]);
                               }];
}

- (void)testRemoteOperationWhenNoDocumentInStoreAndCustomTTL {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completed with remote document (custom TTL)."];
  __block MSDocumentWrapper *remoteDocumentWrapper = [MSDocumentWrapper alloc];
  __block MSDocumentWrapper *wrapper;
  OCMStub([self.documentStoreMock readWithToken:OCMOCK_ANY documentId:OCMOCK_ANY documentType:OCMOCK_ANY])
      .andReturn([[MSDocumentWrapper alloc] initWithError:[NSError new] documentId:@"documentId"]);
  MSTokenResult *token = [MSTokenResult alloc];
  __block MSTokensResponse *response = [[MSTokensResponse alloc] initWithTokens:@[ token ]];

  // When
  NSInteger deviceTimeToLive = 100000;
  [self.sut performOperation:nil
      documentId:@"documentId"
      documentType:[NSString class]
      document:nil
      baseOptions:[[MSBaseOptions alloc] initWithDeviceTimeToLive:deviceTimeToLive]
      cachedTokenBlock:^(MSCachedTokenCompletionHandler _Nonnull handler) {
        handler(response, nil);
      }
      remoteDocumentBlock:^(MSDocumentWrapperCompletionHandler _Nonnull handler) {
        handler(remoteDocumentWrapper);
      }
      completionHandler:^(MSDocumentWrapper *_Nonnull document) {
        wrapper = document;
        [expectation fulfill];
      }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertEqual(wrapper, remoteDocumentWrapper);
                                 OCMVerify([self.documentStoreMock upsertWithToken:token
                                                                   documentWrapper:remoteDocumentWrapper
                                                                         operation:nil
                                                                  deviceTimeToLive:deviceTimeToLive]);
                               }];
}

- (void)testDeleteWhenUnsyncedCreateOperation {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completed with discarded create or replace operation."];
  __block MSDocumentWrapper *cachedDocumentWrapper = [[MSDocumentWrapper alloc] initWithDeserializedValue:[MSDictionaryDocument alloc]
                                                                                                jsonValue:@""
                                                                                                partition:@"partition"
                                                                                               documentId:@"documentId"
                                                                                                     eTag:nil
                                                                                          lastUpdatedDate:nil
                                                                                         pendingOperation:kMSPendingOperationCreate
                                                                                                    error:nil];
  __block MSDocumentWrapper *wrapper;
  OCMStub([self.documentStoreMock readWithToken:OCMOCK_ANY documentId:OCMOCK_ANY documentType:OCMOCK_ANY]).andReturn(cachedDocumentWrapper);
  MSTokenResult *token = [MSTokenResult alloc];
  __block MSTokensResponse *response = [[MSTokensResponse alloc] initWithTokens:@[ token ]];

  // When
  [self.sut performOperation:kMSPendingOperationDelete
      documentId:@"documentId"
      documentType:[NSString class]
      document:nil
      baseOptions:nil
      cachedTokenBlock:^(MSCachedTokenCompletionHandler _Nonnull handler) {
        handler(response, nil);
      }
      remoteDocumentBlock:^(MSDocumentWrapperCompletionHandler _Nonnull __unused handler) {
      }
      completionHandler:^(MSDocumentWrapper *_Nonnull document) {
        wrapper = document;
        [expectation fulfill];
      }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertNotEqual(wrapper, cachedDocumentWrapper);
                                 XCTAssertEqual(wrapper.documentId, cachedDocumentWrapper.documentId);
                                 XCTAssertEqual(wrapper.pendingOperation, kMSPendingOperationDelete);
                                 OCMReject([[self.documentStoreMock ignoringNonObjectArgs] upsertWithToken:OCMOCK_ANY
                                                                                           documentWrapper:OCMOCK_ANY
                                                                                                 operation:OCMOCK_ANY
                                                                                          deviceTimeToLive:0]);
                                 OCMVerify([self.documentStoreMock deleteWithToken:token documentId:@"documentId"]);
                               }];
}

- (void)testDeleteWhenUnsyncedReplaceOperation {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completed with discarded create or replace operation."];
  __block MSDocumentWrapper *cachedDocumentWrapper = [[MSDocumentWrapper alloc] initWithDeserializedValue:[MSDictionaryDocument alloc]
                                                                                                jsonValue:@""
                                                                                                partition:@"partition"
                                                                                               documentId:@"documentId"
                                                                                                     eTag:nil
                                                                                          lastUpdatedDate:nil
                                                                                         pendingOperation:kMSPendingOperationReplace
                                                                                                    error:nil];
  __block MSDocumentWrapper *wrapper;
  OCMStub([self.documentStoreMock readWithToken:OCMOCK_ANY documentId:OCMOCK_ANY documentType:OCMOCK_ANY]).andReturn(cachedDocumentWrapper);
  MSTokenResult *token = [MSTokenResult alloc];
  __block MSTokensResponse *response = [[MSTokensResponse alloc] initWithTokens:@[ token ]];

  // When
  [self.sut performOperation:kMSPendingOperationDelete
      documentId:@"documentId"
      documentType:[NSString class]
      document:nil
      baseOptions:nil
      cachedTokenBlock:^(MSCachedTokenCompletionHandler _Nonnull handler) {
        handler(response, nil);
      }
      remoteDocumentBlock:^(MSDocumentWrapperCompletionHandler _Nonnull __unused handler) {
      }
      completionHandler:^(MSDocumentWrapper *_Nonnull document) {
        wrapper = document;
        [expectation fulfill];
      }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertNotEqual(wrapper, cachedDocumentWrapper);
                                 XCTAssertEqual(wrapper.documentId, cachedDocumentWrapper.documentId);
                                 XCTAssertEqual(wrapper.pendingOperation, kMSPendingOperationDelete);
                                 OCMReject([[self.documentStoreMock ignoringNonObjectArgs] upsertWithToken:OCMOCK_ANY
                                                                                           documentWrapper:OCMOCK_ANY
                                                                                                 operation:OCMOCK_ANY
                                                                                          deviceTimeToLive:0]);
                                 OCMVerify([self.documentStoreMock deleteWithToken:token documentId:@"documentId"]);
                               }];
}

- (void)testReadOperationFailsWhenPendingDelete {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completed with remote document (custom TTL)."];
  __block MSDocumentWrapper *cachedDocumentWrapper = [[MSDocumentWrapper alloc] initWithDeserializedValue:[MSDictionaryDocument alloc]
                                                                                                jsonValue:@""
                                                                                                partition:@"partition"
                                                                                               documentId:@"documentId"
                                                                                                     eTag:@""
                                                                                          lastUpdatedDate:nil
                                                                                         pendingOperation:kMSPendingOperationDelete
                                                                                                    error:nil];
  __block MSDocumentWrapper *wrapper;
  OCMStub([self.documentStoreMock readWithToken:OCMOCK_ANY documentId:OCMOCK_ANY documentType:OCMOCK_ANY]).andReturn(cachedDocumentWrapper);
  MSTokenResult *token = [MSTokenResult alloc];
  __block MSTokensResponse *response = [[MSTokensResponse alloc] initWithTokens:@[ token ]];

  // When
  [self.sut performOperation:nil
      documentId:@"documentId"
      documentType:[NSString class]
      document:nil
      baseOptions:nil
      cachedTokenBlock:^(MSCachedTokenCompletionHandler _Nonnull handler) {
        handler(response, nil);
      }
      remoteDocumentBlock:^(MSDocumentWrapperCompletionHandler _Nonnull __unused handler) {
      }
      completionHandler:^(MSDocumentWrapper *_Nonnull document) {
        wrapper = document;
        [expectation fulfill];
      }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertNotNil(wrapper.error);
                                 XCTAssertEqual(wrapper.error.error.code, MSACDataStoreErrorDocumentNotFound);
                                 OCMReject([[self.documentStoreMock ignoringNonObjectArgs] upsertWithToken:OCMOCK_ANY
                                                                                           documentWrapper:OCMOCK_ANY
                                                                                                 operation:OCMOCK_ANY
                                                                                          deviceTimeToLive:0]);
                               }];
}

- (void)testLocalDeleteWhenCachedDocumentPresent {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completed with discarded create or replace operation."];
  __block MSDocumentWrapper *cachedDocumentWrapper = [[MSDocumentWrapper alloc] initWithDeserializedValue:[MSDictionaryDocument alloc]
                                                                                                jsonValue:@""
                                                                                                partition:@"partition"
                                                                                               documentId:@"documentId"
                                                                                                     eTag:@""
                                                                                          lastUpdatedDate:nil
                                                                                         pendingOperation:nil
                                                                                                    error:nil];
  __block MSDocumentWrapper *wrapper;
  OCMStub([self.documentStoreMock readWithToken:OCMOCK_ANY documentId:OCMOCK_ANY documentType:OCMOCK_ANY]).andReturn(cachedDocumentWrapper);
  MSTokenResult *token = [MSTokenResult alloc];
  __block MSTokensResponse *response = [[MSTokensResponse alloc] initWithTokens:@[ token ]];

  // Simulate being offline.
  MS_Reachability *reachabilityMock = OCMPartialMock([MS_Reachability reachabilityForInternetConnection]);
  OCMStub([reachabilityMock currentReachabilityStatus]).andReturn(NotReachable);
  self.sut.reachability = reachabilityMock;

  // When
  [self.sut performOperation:kMSPendingOperationDelete
      documentId:@"documentId"
      documentType:[NSString class]
      document:nil
      baseOptions:nil
      cachedTokenBlock:^(MSCachedTokenCompletionHandler _Nonnull handler) {
        handler(response, nil);
      }
      remoteDocumentBlock:^(MSDocumentWrapperCompletionHandler _Nonnull __unused handler) {
      }
      completionHandler:^(MSDocumentWrapper *_Nonnull document) {
        wrapper = document;
        [expectation fulfill];
      }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertNotEqual(wrapper, cachedDocumentWrapper);
                                 XCTAssertEqual(wrapper.documentId, cachedDocumentWrapper.documentId);
                                 XCTAssertEqual(wrapper.pendingOperation, kMSPendingOperationDelete);
                                 OCMVerify([self.documentStoreMock upsertWithToken:token
                                                                   documentWrapper:wrapper
                                                                         operation:kMSPendingOperationDelete
                                                                  deviceTimeToLive:kMSDataStoreTimeToLiveDefault]);
                               }];
}

- (void)testLocalCreateWhenCachedDocumentPresent {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completed with discarded create or replace operation."];
  __block MSDocumentWrapper *cachedDocumentWrapper = [[MSDocumentWrapper alloc] initWithDeserializedValue:[MSDictionaryDocument alloc]
                                                                                                jsonValue:@""
                                                                                                partition:@"partition"
                                                                                               documentId:@"documentId"
                                                                                                     eTag:@""
                                                                                          lastUpdatedDate:nil
                                                                                         pendingOperation:nil
                                                                                                    error:nil];
  __block MSDocumentWrapper *wrapper;
  OCMStub([self.documentStoreMock readWithToken:OCMOCK_ANY documentId:OCMOCK_ANY documentType:OCMOCK_ANY]).andReturn(cachedDocumentWrapper);
  MSTokenResult *token = [MSTokenResult alloc];
  __block MSTokensResponse *response = [[MSTokensResponse alloc] initWithTokens:@[ token ]];

  // Simulate being offline.
  MS_Reachability *reachabilityMock = OCMPartialMock([MS_Reachability reachabilityForInternetConnection]);
  OCMStub([reachabilityMock currentReachabilityStatus]).andReturn(NotReachable);
  self.sut.reachability = reachabilityMock;

  // When
  NSMutableDictionary *dict = [NSMutableDictionary new];
  dict[@"key"] = @"value";
  [self.sut performOperation:kMSPendingOperationCreate
      documentId:@"documentId"
      documentType:[NSString class]
      document:[[MSDictionaryDocument alloc] initFromDictionary:dict]
      baseOptions:nil
      cachedTokenBlock:^(MSCachedTokenCompletionHandler _Nonnull handler) {
        handler(response, nil);
      }
      remoteDocumentBlock:^(MSDocumentWrapperCompletionHandler _Nonnull __unused handler) {
      }
      completionHandler:^(MSDocumentWrapper *_Nonnull document) {
        wrapper = document;
        [expectation fulfill];
      }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertNotEqual(wrapper, cachedDocumentWrapper);
                                 XCTAssertEqual(wrapper.documentId, cachedDocumentWrapper.documentId);
                                 XCTAssertEqual(wrapper.pendingOperation, kMSPendingOperationCreate);
                                 NSDictionary *actualDict = [wrapper.deserializedValue serializeToDictionary];
                                 XCTAssertEqual(actualDict[@"key"], @"value");
                                 OCMVerify([self.documentStoreMock upsertWithToken:token
                                                                   documentWrapper:wrapper
                                                                         operation:kMSPendingOperationCreate
                                                                  deviceTimeToLive:kMSDataStoreTimeToLiveDefault]);
                               }];
}

- (void)testLocalReplaceWhenCachedDocumentPresent {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completed with discarded create or replace operation."];
  __block MSDocumentWrapper *cachedDocumentWrapper = [[MSDocumentWrapper alloc] initWithDeserializedValue:[MSDictionaryDocument alloc]
                                                                                                jsonValue:@""
                                                                                                partition:@"partition"
                                                                                               documentId:@"documentId"
                                                                                                     eTag:@""
                                                                                          lastUpdatedDate:nil
                                                                                         pendingOperation:nil
                                                                                                    error:nil];
  __block MSDocumentWrapper *wrapper;
  OCMStub([self.documentStoreMock readWithToken:OCMOCK_ANY documentId:OCMOCK_ANY documentType:OCMOCK_ANY]).andReturn(cachedDocumentWrapper);
  MSTokenResult *token = [MSTokenResult alloc];
  __block MSTokensResponse *response = [[MSTokensResponse alloc] initWithTokens:@[ token ]];

  // Simulate being offline.
  MS_Reachability *reachabilityMock = OCMPartialMock([MS_Reachability reachabilityForInternetConnection]);
  OCMStub([reachabilityMock currentReachabilityStatus]).andReturn(NotReachable);
  self.sut.reachability = reachabilityMock;

  // When
  NSMutableDictionary *dict = [NSMutableDictionary new];
  dict[@"key"] = @"value";
  [self.sut performOperation:kMSPendingOperationReplace
      documentId:@"documentId"
      documentType:[NSString class]
      document:[[MSDictionaryDocument alloc] initFromDictionary:dict]
      baseOptions:nil
      cachedTokenBlock:^(MSCachedTokenCompletionHandler _Nonnull handler) {
        handler(response, nil);
      }
      remoteDocumentBlock:^(MSDocumentWrapperCompletionHandler _Nonnull __unused handler) {
      }
      completionHandler:^(MSDocumentWrapper *_Nonnull document) {
        wrapper = document;
        [expectation fulfill];
      }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertNotEqual(wrapper, cachedDocumentWrapper);
                                 XCTAssertEqual(wrapper.documentId, cachedDocumentWrapper.documentId);
                                 XCTAssertEqual(wrapper.pendingOperation, kMSPendingOperationReplace);
                                 NSDictionary *actualDict = [wrapper.deserializedValue serializeToDictionary];
                                 XCTAssertEqual(actualDict[@"key"], @"value");
                                 OCMVerify([self.documentStoreMock upsertWithToken:token
                                                                   documentWrapper:wrapper
                                                                         operation:kMSPendingOperationReplace
                                                                  deviceTimeToLive:kMSDataStoreTimeToLiveDefault]);
                               }];
}

@end
