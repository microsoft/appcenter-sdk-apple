// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSTestFrameworks.h"
#import "MSDataOperationProxy.h"
#import "MSDataSourceError.h"
#import "MSDataStoreErrors.h"
#import "MSDBDocumentStore.h"
#import "MSDocumentWrapper.h"

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

-(void)testInvalidOperation {
  
  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completed with error for invalid operation."];
  __block MSDocumentWrapper *wrapper;
  
  // When
  [self.sut performOperation:@"badOperation" documentId:@"documentId" documentType:[NSString class] document:nil baseOptions:nil cachedTokenBlock:^(MSCachedTokenCompletionHandler _Nonnull __unused handler) {
  } remoteDocumentBlock:^(MSDocumentWrapperCompletionHandler _Nonnull __unused handler) {
  } completionHandler:^(MSDocumentWrapper * _Nonnull document) {
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

-(void)testInvalidToken {
  
  // If
  XCTestExpectation *expectation = [self expectationWithDescription:@"Completed with error retrieving token."];
  __block NSError *tokenError;
  __block MSDocumentWrapper *wrapper;
  
  // When
  [self.sut performOperation:nil documentId:@"documentId" documentType:[NSString class] document:nil baseOptions:nil cachedTokenBlock:^(MSCachedTokenCompletionHandler _Nonnull __unused handler) {
    tokenError = [NSError new];
    handler(nil, tokenError);
  } remoteDocumentBlock:^(MSDocumentWrapperCompletionHandler _Nonnull __unused handler) {
  } completionHandler:^(MSDocumentWrapper * _Nonnull document) {
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

@end

