// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSBaseOptions.h"
#import "MSDBDocumentStore.h"
#import "MSDBDocumentStorePrivate.h"
#import "MSDataConstants.h"
#import "MSDataErrorInternal.h"
#import "MSDataErrors.h"
#import "MSDataOperationProxy.h"
#import "MSDictionaryDocument.h"
#import "MSDocumentWrapperInternal.h"
#import "MSTestFrameworks.h"
#import "MSTokenResult.h"
#import "MSUtility+File.h"

@interface MSDataOperationProxyTests : XCTestCase

@property(nonatomic) MSDataOperationProxy *sut;
@property(nonatomic) id documentStoreMock;
@property(nonatomic) id reachability;
@property(nonatomic) NSError *dummyError;

@end

@implementation MSDataOperationProxyTests

- (void)setUp {
  [super setUp];

  // Init properties.
  MSDBStorage *dbStorage = [[MSDBStorage alloc] initWithVersion:0 filename:kMSDBDocumentFileName];
  _documentStoreMock = OCMPartialMock([[MSDBDocumentStore alloc] initWithDbStorage:dbStorage]);
  _reachability = OCMPartialMock([MS_Reachability reachabilityForInternetConnection]);
  _sut = [[MSDataOperationProxy alloc] initWithDocumentStore:_documentStoreMock reachability:self.reachability];
  _dummyError = [[MSDataError alloc] initWithErrorCode:-1 innerError:nil message:@"Some dummy error"];
}

- (void)tearDown {
  [super tearDown];

  [self.documentStoreMock stopMocking];
  [self.reachability stopMocking];

  // Delete existing database.
  [MSUtility deleteItemForPathComponent:kMSDBDocumentFileName];
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
                                 XCTAssertEqual(wrapper.error.code, MSACDataErrorUnsupportedOperation);
                               }];
}

- (void)testInvalidToken {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completed with error retrieving token."];
  __block MSDocumentWrapper *wrapper;

  // When
  [self.sut performOperation:kMSPendingOperationRead
      documentId:@"documentId"
      documentType:[NSString class]
      document:nil
      baseOptions:nil
      cachedTokenBlock:^(MSCachedTokenCompletionHandler _Nonnull handler) {
        handler(nil, self.dummyError);
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
                                 XCTAssertEqual(wrapper.error.code, MSACDataErrorCachedToken);
                               }];
}

- (void)testRemoteOperationWhenNoDocumentInStoreAndDefaultTTL {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completed with remote document (default TTL)."];
  __block MSDocumentWrapper *remoteDocumentWrapper = [MSDocumentWrapper alloc];
  __block MSDocumentWrapper *wrapper;
  NSString *documentId = @"documentId";
  OCMStub([self.documentStoreMock readWithToken:OCMOCK_ANY documentId:OCMOCK_ANY documentType:OCMOCK_ANY])
      .andReturn([[MSDocumentWrapper alloc] initWithError:self.dummyError partition:nil documentId:documentId]);
  MSTokenResult *token = [MSTokenResult alloc];
  __block MSTokensResponse *tokensResponse = [[MSTokensResponse alloc] initWithTokens:@[ token ]];

  // When
  [self.sut performOperation:kMSPendingOperationDelete
      documentId:documentId
      documentType:[NSString class]
      document:nil
      baseOptions:nil
      cachedTokenBlock:^(MSCachedTokenCompletionHandler _Nonnull handler) {
        handler(tokensResponse, nil);
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
                                 OCMVerify([self.documentStoreMock deleteWithToken:token documentId:documentId]);
                               }];
}

- (void)testRemoteOperationWhenNoDocumentInStoreAndNoCache {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completed with remote document (no cache)."];
  __block MSDocumentWrapper *remoteDocumentWrapper = [MSDocumentWrapper alloc];
  __block MSDocumentWrapper *wrapper;
  OCMStub([self.documentStoreMock readWithToken:OCMOCK_ANY documentId:OCMOCK_ANY documentType:OCMOCK_ANY])
      .andReturn([[MSDocumentWrapper alloc] initWithError:self.dummyError partition:nil documentId:@"documentId"]);
  OCMReject([[self.documentStoreMock ignoringNonObjectArgs] upsertWithToken:OCMOCK_ANY
                                                            documentWrapper:OCMOCK_ANY
                                                                  operation:OCMOCK_ANY
                                                           deviceTimeToLive:0]);
  MSTokenResult *token = [MSTokenResult alloc];
  __block MSTokensResponse *tokensResponse = [[MSTokensResponse alloc] initWithTokens:@[ token ]];

  // When
  MSBaseOptions *options = [[MSBaseOptions alloc] initWithDeviceTimeToLive:kMSDataTimeToLiveNoCache];
  [self.sut performOperation:kMSPendingOperationRead
      documentId:@"documentId"
      documentType:[NSString class]
      document:nil
      baseOptions:options
      cachedTokenBlock:^(MSCachedTokenCompletionHandler _Nonnull handler) {
        handler(tokensResponse, nil);
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
                                 OCMVerify([self.documentStoreMock deleteWithToken:token documentId:@"documentId"]);
                               }];
}

- (void)testRemoteOperationWhenNoDocumentInStoreAndCustomTTL {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completed with remote document (custom TTL)."];
  __block MSDocumentWrapper *remoteDocumentWrapper = [MSDocumentWrapper alloc];
  __block MSDocumentWrapper *wrapper;
  OCMStub([self.documentStoreMock readWithToken:OCMOCK_ANY documentId:OCMOCK_ANY documentType:OCMOCK_ANY])
      .andReturn([[MSDocumentWrapper alloc] initWithError:self.dummyError partition:nil documentId:@"documentId"]);
  MSTokenResult *token = [MSTokenResult alloc];
  __block MSTokensResponse *tokensResponse = [[MSTokensResponse alloc] initWithTokens:@[ token ]];

  // When
  NSInteger deviceTimeToLive = 100000;
  [self.sut performOperation:kMSPendingOperationRead
      documentId:@"documentId"
      documentType:[NSString class]
      document:nil
      baseOptions:[[MSBaseOptions alloc] initWithDeviceTimeToLive:deviceTimeToLive]
      cachedTokenBlock:^(MSCachedTokenCompletionHandler _Nonnull handler) {
        handler(tokensResponse, nil);
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
                                                                         operation:kMSPendingOperationRead
                                                                  deviceTimeToLive:deviceTimeToLive]);
                               }];
}

- (void)testDeleteWhenUnsyncedCreateOperation {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completed with discarded create operation."];
  __block MSDocumentWrapper *cachedDocumentWrapper = [[MSDocumentWrapper alloc] initWithDeserializedValue:[MSDictionaryDocument alloc]
                                                                                                jsonValue:@""
                                                                                                partition:@"partition"
                                                                                               documentId:@"documentId"
                                                                                                     eTag:nil
                                                                                          lastUpdatedDate:nil
                                                                                         pendingOperation:kMSPendingOperationCreate
                                                                                          fromDeviceCache:YES];
  __block MSDocumentWrapper *wrapper;
  OCMStub([self.documentStoreMock readWithToken:OCMOCK_ANY documentId:OCMOCK_ANY documentType:OCMOCK_ANY]).andReturn(cachedDocumentWrapper);
  OCMReject([[self.documentStoreMock ignoringNonObjectArgs] upsertWithToken:OCMOCK_ANY
                                                            documentWrapper:OCMOCK_ANY
                                                                  operation:OCMOCK_ANY
                                                           deviceTimeToLive:0]);
  MSTokenResult *token = [MSTokenResult alloc];
  __block MSTokensResponse *tokensResponse = [[MSTokensResponse alloc] initWithTokens:@[ token ]];

  // When
  [self.sut performOperation:kMSPendingOperationDelete
      documentId:@"documentId"
      documentType:[NSString class]
      document:nil
      baseOptions:nil
      cachedTokenBlock:^(MSCachedTokenCompletionHandler _Nonnull handler) {
        handler(tokensResponse, nil);
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
                                 XCTAssertTrue(wrapper.fromDeviceCache);
                                 XCTAssertTrue(wrapper.fromDeviceCache);
                                 OCMVerify([self.documentStoreMock deleteWithToken:token documentId:@"documentId"]);
                               }];
}

- (void)testDeleteWhenUnsyncedReplaceOperation {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completed with discarded replace operation."];
  __block MSDocumentWrapper *cachedDocumentWrapper = [[MSDocumentWrapper alloc] initWithDeserializedValue:[MSDictionaryDocument alloc]
                                                                                                jsonValue:@""
                                                                                                partition:@"partition"
                                                                                               documentId:@"documentId"
                                                                                                     eTag:nil
                                                                                          lastUpdatedDate:nil
                                                                                         pendingOperation:kMSPendingOperationReplace
                                                                                          fromDeviceCache:YES];
  __block MSDocumentWrapper *wrapper;
  OCMStub([self.documentStoreMock readWithToken:OCMOCK_ANY documentId:OCMOCK_ANY documentType:OCMOCK_ANY]).andReturn(cachedDocumentWrapper);
  OCMReject([[self.documentStoreMock ignoringNonObjectArgs] upsertWithToken:OCMOCK_ANY
                                                            documentWrapper:OCMOCK_ANY
                                                                  operation:OCMOCK_ANY
                                                           deviceTimeToLive:0]);
  MSTokenResult *token = [MSTokenResult alloc];
  __block MSTokensResponse *tokensResponse = [[MSTokensResponse alloc] initWithTokens:@[ token ]];

  // When
  [self.sut performOperation:kMSPendingOperationDelete
      documentId:@"documentId"
      documentType:[NSString class]
      document:nil
      baseOptions:nil
      cachedTokenBlock:^(MSCachedTokenCompletionHandler _Nonnull handler) {
        handler(tokensResponse, nil);
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
                                 XCTAssertTrue(wrapper.fromDeviceCache);
                                 OCMVerify([self.documentStoreMock deleteWithToken:token documentId:@"documentId"]);
                               }];
}

- (void)testReadOperationFailsWhenPendingDelete {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completed with failure pending local delete."];
  __block MSDocumentWrapper *cachedDocumentWrapper = [[MSDocumentWrapper alloc] initWithDeserializedValue:[MSDictionaryDocument alloc]
                                                                                                jsonValue:@""
                                                                                                partition:@"partition"
                                                                                               documentId:@"documentId"
                                                                                                     eTag:@""
                                                                                          lastUpdatedDate:nil
                                                                                         pendingOperation:kMSPendingOperationDelete
                                                                                          fromDeviceCache:YES];
  __block MSDocumentWrapper *wrapper;
  OCMStub([self.documentStoreMock readWithToken:OCMOCK_ANY documentId:OCMOCK_ANY documentType:OCMOCK_ANY]).andReturn(cachedDocumentWrapper);
  OCMReject([[self.documentStoreMock ignoringNonObjectArgs] upsertWithToken:OCMOCK_ANY
                                                            documentWrapper:OCMOCK_ANY
                                                                  operation:OCMOCK_ANY
                                                           deviceTimeToLive:0]);
  MSTokenResult *token = [MSTokenResult alloc];
  __block MSTokensResponse *tokensResponse = [[MSTokensResponse alloc] initWithTokens:@[ token ]];

  // When
  [self.sut performOperation:kMSPendingOperationRead
      documentId:@"documentId"
      documentType:[NSString class]
      document:nil
      baseOptions:nil
      cachedTokenBlock:^(MSCachedTokenCompletionHandler _Nonnull handler) {
        handler(tokensResponse, nil);
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
                                 XCTAssertFalse(wrapper.fromDeviceCache); // Error state should not have from device cache set to YES.
                                 XCTAssertEqual(wrapper.error.code, MSACDataErrorDocumentNotFound);
                               }];
}

- (void)testLocalReadWhenCachedDocumentMaintainPendingOperation {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completed with local read."];
  __block MSDocumentWrapper *cachedDocumentWrapper = [[MSDocumentWrapper alloc] initWithDeserializedValue:[MSDictionaryDocument alloc]
                                                                                                jsonValue:@""
                                                                                                partition:@"partition"
                                                                                               documentId:@"documentId"
                                                                                                     eTag:@""
                                                                                          lastUpdatedDate:nil
                                                                                         pendingOperation:kMSPendingOperationReplace
                                                                                          fromDeviceCache:YES];
  __block MSDocumentWrapper *wrapper;
  OCMStub([self.documentStoreMock readWithToken:OCMOCK_ANY documentId:OCMOCK_ANY documentType:OCMOCK_ANY]).andReturn(cachedDocumentWrapper);
  MSTokenResult *token = [MSTokenResult alloc];
  __block MSTokensResponse *tokensResponse = [[MSTokensResponse alloc] initWithTokens:@[ token ]];

  // Simulate being offline.
  OCMStub([self.reachability currentReachabilityStatus]).andReturn(NotReachable);

  // When
  [self.sut performOperation:kMSPendingOperationRead
      documentId:@"documentId"
      documentType:[NSString class]
      document:nil
      baseOptions:nil
      cachedTokenBlock:^(MSCachedTokenCompletionHandler _Nonnull handler) {
        handler(tokensResponse, nil);
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
                                 XCTAssertEqual(wrapper.documentId, cachedDocumentWrapper.documentId);
                                 XCTAssertEqual(wrapper.pendingOperation, kMSPendingOperationReplace);
                                 XCTAssertTrue(wrapper.fromDeviceCache);
                                 OCMVerify([self.documentStoreMock upsertWithToken:token
                                                                   documentWrapper:wrapper
                                                                         operation:kMSPendingOperationReplace
                                                                  deviceTimeToLive:kMSDataTimeToLiveDefault]);
                               }];
}

- (void)testLocalDeleteWhenCachedDocumentPresent {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completed with delete and local cached document."];
  __block MSDocumentWrapper *cachedDocumentWrapper = [[MSDocumentWrapper alloc] initWithDeserializedValue:[MSDictionaryDocument alloc]
                                                                                                jsonValue:@""
                                                                                                partition:@"partition"
                                                                                               documentId:@"documentId"
                                                                                                     eTag:@""
                                                                                          lastUpdatedDate:nil
                                                                                         pendingOperation:kMSPendingOperationRead
                                                                                          fromDeviceCache:YES];
  __block MSDocumentWrapper *wrapper;
  OCMStub([self.documentStoreMock readWithToken:OCMOCK_ANY documentId:OCMOCK_ANY documentType:OCMOCK_ANY]).andReturn(cachedDocumentWrapper);
  MSTokenResult *token = [MSTokenResult alloc];
  __block MSTokensResponse *tokensResponse = [[MSTokensResponse alloc] initWithTokens:@[ token ]];

  // Simulate being offline.
  OCMStub([self.reachability currentReachabilityStatus]).andReturn(NotReachable);

  // When
  [self.sut performOperation:kMSPendingOperationDelete
      documentId:@"documentId"
      documentType:[NSString class]
      document:nil
      baseOptions:nil
      cachedTokenBlock:^(MSCachedTokenCompletionHandler _Nonnull handler) {
        handler(tokensResponse, nil);
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
                                 XCTAssertTrue(wrapper.fromDeviceCache);
                                 OCMVerify([self.documentStoreMock upsertWithToken:token
                                                                   documentWrapper:wrapper
                                                                         operation:kMSPendingOperationDelete
                                                                  deviceTimeToLive:kMSDataTimeToLiveDefault]);
                               }];
}

- (void)testLocalCreateWhenCachedDocumentPresent {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completed with create and local cached document."];
  __block MSDocumentWrapper *cachedDocumentWrapper = [[MSDocumentWrapper alloc] initWithDeserializedValue:[MSDictionaryDocument alloc]
                                                                                                jsonValue:@""
                                                                                                partition:@"partition"
                                                                                               documentId:@"documentId"
                                                                                                     eTag:@""
                                                                                          lastUpdatedDate:nil
                                                                                         pendingOperation:kMSPendingOperationRead
                                                                                          fromDeviceCache:YES];
  __block MSDocumentWrapper *wrapper;
  OCMStub([self.documentStoreMock readWithToken:OCMOCK_ANY documentId:OCMOCK_ANY documentType:OCMOCK_ANY]).andReturn(cachedDocumentWrapper);
  MSTokenResult *token = [MSTokenResult alloc];
  __block MSTokensResponse *tokensResponse = [[MSTokensResponse alloc] initWithTokens:@[ token ]];

  // Simulate being offline.
  OCMStub([self.reachability currentReachabilityStatus]).andReturn(NotReachable);

  // When
  NSMutableDictionary *dict = [NSMutableDictionary new];
  dict[@"key"] = @"value";
  [self.sut performOperation:kMSPendingOperationCreate
      documentId:@"documentId"
      documentType:[MSDictionaryDocument class]
      document:[[MSDictionaryDocument alloc] initFromDictionary:dict]
      baseOptions:nil
      cachedTokenBlock:^(MSCachedTokenCompletionHandler _Nonnull handler) {
        handler(tokensResponse, nil);
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
                                 XCTAssertTrue(wrapper.fromDeviceCache);
                                 NSDictionary *actualDict = [wrapper.deserializedValue serializeToDictionary];
                                 XCTAssertEqual(actualDict[@"key"], @"value");
                                 OCMVerify([self.documentStoreMock upsertWithToken:token
                                                                   documentWrapper:wrapper
                                                                         operation:kMSPendingOperationCreate
                                                                  deviceTimeToLive:kMSDataTimeToLiveDefault]);
                               }];
}

- (void)testLocalReplaceWhenCachedDocumentPresent {

  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completed with replace and local cached document."];
  __block MSDocumentWrapper *cachedDocumentWrapper = [[MSDocumentWrapper alloc] initWithDeserializedValue:[MSDictionaryDocument alloc]
                                                                                                jsonValue:@""
                                                                                                partition:@"partition"
                                                                                               documentId:@"documentId"
                                                                                                     eTag:@""
                                                                                          lastUpdatedDate:nil
                                                                                         pendingOperation:kMSPendingOperationRead
                                                                                          fromDeviceCache:YES];
  __block MSDocumentWrapper *wrapper;
  OCMStub([self.documentStoreMock readWithToken:OCMOCK_ANY documentId:OCMOCK_ANY documentType:OCMOCK_ANY]).andReturn(cachedDocumentWrapper);
  MSTokenResult *token = [MSTokenResult alloc];
  __block MSTokensResponse *tokensResponse = [[MSTokensResponse alloc] initWithTokens:@[ token ]];

  // Simulate being offline.
  OCMStub([self.reachability currentReachabilityStatus]).andReturn(NotReachable);

  // When
  NSMutableDictionary *dict = [NSMutableDictionary new];
  dict[@"key"] = @"value";
  [self.sut performOperation:kMSPendingOperationReplace
      documentId:@"documentId"
      documentType:[MSDictionaryDocument class]
      document:[[MSDictionaryDocument alloc] initFromDictionary:dict]
      baseOptions:nil
      cachedTokenBlock:^(MSCachedTokenCompletionHandler _Nonnull handler) {
        handler(tokensResponse, nil);
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
                                 XCTAssertTrue(wrapper.fromDeviceCache);
                                 NSDictionary *actualDict = [wrapper.deserializedValue serializeToDictionary];
                                 XCTAssertEqual(actualDict[@"key"], @"value");
                                 OCMVerify([self.documentStoreMock upsertWithToken:token
                                                                   documentWrapper:wrapper
                                                                         operation:kMSPendingOperationReplace
                                                                  deviceTimeToLive:kMSDataTimeToLiveDefault]);
                               }];
}

- (void)testLocalCreateWhenCachedDocumentIsUnserializable {

  // If
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Completed with error on create with unserializable local cached document."];
  NSErrorDomain expectedErrorDomain = kMSACDataErrorDomain;
  NSInteger expectedErrorCode = MSACDataErrorJSONSerializationFailed;
  __block MSDocumentWrapper *cachedDocumentWrapper = [[MSDocumentWrapper alloc] initWithDeserializedValue:[MSDictionaryDocument alloc]
                                                                                                jsonValue:@""
                                                                                                partition:@"partition"
                                                                                               documentId:@"documentId"
                                                                                                     eTag:@""
                                                                                          lastUpdatedDate:nil
                                                                                         pendingOperation:kMSPendingOperationRead
                                                                                          fromDeviceCache:NO];
  __block MSDocumentWrapper *wrapper;
  OCMStub([self.documentStoreMock readWithToken:OCMOCK_ANY documentId:OCMOCK_ANY documentType:OCMOCK_ANY]).andReturn(cachedDocumentWrapper);
  MSTokenResult *token = [MSTokenResult alloc];
  __block MSTokensResponse *tokensResponse = [[MSTokensResponse alloc] initWithTokens:@[ token ]];

  // Simulate being offline.
  OCMStub([self.reachability currentReachabilityStatus]).andReturn(NotReachable);

  // When
  NSMutableDictionary *dict = [NSMutableDictionary new];
  dict[@"shouldFail"] = [NSSet set];
  [self.sut performOperation:kMSPendingOperationCreate
      documentId:@"documentId"
      documentType:[MSDictionaryDocument class]
      document:[[MSDictionaryDocument alloc] initFromDictionary:dict]
      baseOptions:nil
      cachedTokenBlock:^(MSCachedTokenCompletionHandler _Nonnull handler) {
        handler(tokensResponse, nil);
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
                                 XCTAssertNotNil(wrapper);
                                 XCTAssertNotNil(wrapper.error);
                                 XCTAssertEqual(wrapper.error.domain, expectedErrorDomain);
                                 XCTAssertEqual([wrapper.error innerError].code, expectedErrorCode);
                                 XCTAssertNotEqual(wrapper, cachedDocumentWrapper);
                                 XCTAssertEqual(wrapper.documentId, cachedDocumentWrapper.documentId);
                               }];
}

- (void)testLocalReplaceWhenCachedDocumentIsUnserializable {

  // If
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Completed with error on replace with unserializable local cached document."];
  NSErrorDomain expectedErrorDomain = kMSACDataErrorDomain;
  NSInteger expectedErrorCode = MSACDataErrorJSONSerializationFailed;
  __block MSDocumentWrapper *cachedDocumentWrapper = [[MSDocumentWrapper alloc] initWithDeserializedValue:[MSDictionaryDocument alloc]
                                                                                                jsonValue:@""
                                                                                                partition:@"partition"
                                                                                               documentId:@"documentId"
                                                                                                     eTag:@""
                                                                                          lastUpdatedDate:nil
                                                                                         pendingOperation:kMSPendingOperationRead
                                                                                          fromDeviceCache:NO];
  __block MSDocumentWrapper *wrapper;
  OCMStub([self.documentStoreMock readWithToken:OCMOCK_ANY documentId:OCMOCK_ANY documentType:OCMOCK_ANY]).andReturn(cachedDocumentWrapper);
  MSTokenResult *token = [MSTokenResult alloc];
  __block MSTokensResponse *tokensResponse = [[MSTokensResponse alloc] initWithTokens:@[ token ]];

  // Simulate being offline.
  OCMStub([self.reachability currentReachabilityStatus]).andReturn(NotReachable);

  // When
  NSMutableDictionary *dict = [NSMutableDictionary new];
  dict[@"shouldFail"] = [NSSet set];
  [self.sut performOperation:kMSPendingOperationReplace
      documentId:@"documentId"
      documentType:[MSDictionaryDocument class]
      document:[[MSDictionaryDocument alloc] initFromDictionary:dict]
      baseOptions:nil
      cachedTokenBlock:^(MSCachedTokenCompletionHandler _Nonnull handler) {
        handler(tokensResponse, nil);
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
                                 XCTAssertNotNil(wrapper);
                                 XCTAssertNotNil(wrapper.error);
                                 XCTAssertNotNil(wrapper.error);
                                 XCTAssertEqual(wrapper.error.domain, expectedErrorDomain);
                                 XCTAssertEqual([wrapper.error innerError].code, expectedErrorCode);
                                 XCTAssertNotEqual(wrapper, cachedDocumentWrapper);
                                 XCTAssertEqual(wrapper.documentId, cachedDocumentWrapper.documentId);
                               }];
}

@end
