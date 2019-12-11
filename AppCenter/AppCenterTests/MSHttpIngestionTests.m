// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDevice.h"
#import "MSHttpClient.h"
#import "MSHttpIngestionPrivate.h"
#import "MSTestFrameworks.h"

@interface MSHttpIngestionTests : XCTestCase

@property(nonatomic) MSHttpIngestion *sut;
@property(nonatomic) MSHttpClient *httpClientMock;

@end

@implementation MSHttpIngestionTests

- (void)setUp {
  [super setUp];
  NSDictionary *queryStrings = @{@"api-version" : @"1.0.0"};
  self.httpClientMock = OCMPartialMock([MSHttpClient new]);

  // sut: System under test
  self.sut = [[MSHttpIngestion alloc] initWithHttpClient:self.httpClientMock
                                                 baseUrl:@"https://www.contoso.com"
                                                 apiPath:@"/test-path"
                                                 headers:nil
                                            queryStrings:queryStrings
                                          retryIntervals:@[ @(0.5), @(1), @(1.5) ]];
}

- (void)tearDown {
  [super tearDown];
  self.sut = nil;
}

- (void)testValidETagFromResponse {

  // If
  NSString *expectedETag = @"IAmAnETag";
  NSHTTPURLResponse *response = [NSHTTPURLResponse new];
  id responseMock = OCMPartialMock(response);
  OCMStub([responseMock allHeaderFields]).andReturn(@{@"Etag" : expectedETag});

  // When
  NSString *eTag = [MSHttpIngestion eTagFromResponse:responseMock];

  // Then
  XCTAssertEqualObjects(expectedETag, eTag);
}

- (void)testInvalidETagFromResponse {

  // If
  NSHTTPURLResponse *response = [NSHTTPURLResponse new];
  id responseMock = OCMPartialMock(response);
  OCMStub([responseMock allHeaderFields]).andReturn(@{@"Etag1" : @"IAmAnETag"});

  // When
  NSString *eTag = [MSHttpIngestion eTagFromResponse:responseMock];

  // Then
  XCTAssertNil(eTag);
}

- (void)testNoETagFromResponse {

  // If
  NSHTTPURLResponse *response = [NSHTTPURLResponse new];

  // When
  NSString *eTag = [MSHttpIngestion eTagFromResponse:response];

  // Then
  XCTAssertNil(eTag);
}

@end
