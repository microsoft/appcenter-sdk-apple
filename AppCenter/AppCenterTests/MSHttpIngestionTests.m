// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSHttpIngestion.h"
#import "MSTestFrameworks.h"

@interface MSHttpIngestionTests : XCTestCase

@end

@implementation MSHttpIngestionTests

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
