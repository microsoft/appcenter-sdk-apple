// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSCosmosDbIngestion.h"
#import "MSDataStore.h"
#import "MSTestFrameworks.h"
#import "MSUtility.h"

@interface MSCosmosDbIngestionTests : XCTestCase

@end

@implementation MSCosmosDbIngestionTests

- (void)testOfflineModeCallsCompletionHandlerWithError {

  // If
  __block NSData *testData = [NSData new];
  __block NSString *testETag = @"etag";
  __block NSString *testAuthToken = @"token";
  __block NSString *testCallId = MS_UUID_STRING;
  id ingestionMock = OCMPartialMock([MSCosmosDbIngestion new]);
  __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Completion handler called."];

  // When
  [ingestionMock setOfflineMode:YES];
  [ingestionMock sendAsync:testData
                      eTag:testETag
                 authToken:testAuthToken
                    callId:testCallId
         completionHandler:^(NSString *callId, NSHTTPURLResponse *response, NSData *data, NSError *error) {
           XCTAssertEqualObjects(testCallId, callId);
           XCTAssertNil(response);
           XCTAssertNil(data);
           XCTAssertNotNil(error);
           XCTAssertEqualObjects(error.domain, MSDataStorageErrorDomain);
           XCTAssertEqual(error.code, NSURLErrorNotConnectedToInternet);
           OCMReject([ingestionMock sendAsync:testData
                                         eTag:testETag
                                    authToken:testAuthToken
                                       callId:testCallId
                            completionHandler:OCMOCK_ANY]);
           [expectation fulfill];
         }];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}

@end
