// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "AppCenter.h"
#import "MSDataErrorInternal.h"
#import "MSDataErrors.h"
#import "MSTestFrameworks.h"

@interface MSDataErrorTests : XCTestCase

@end

@implementation MSDataErrorTests

- (void)testInitWithErrorCallsParsingMethod {

  // If
  NSInteger expectedErrorCode = MSHTTPCodesNo500InternalServerError;
  NSDictionary *userInfo = @{@"MSHttpCodeKey" : @(expectedErrorCode)};
  NSError *error = [NSError errorWithDomain:kMSACErrorDomain code:0 userInfo:userInfo];
  id dataErrorMock = OCMClassMock([MSDataError class]);

  // When
  MSDataError *dataError = [[MSDataError alloc] initWithError:error];

  // Then
  OCMVerify([dataErrorMock errorCodeFromError:OCMOCK_ANY]);
  XCTAssertEqual(expectedErrorCode, dataError.errorCode);
  XCTAssertEqualObjects(error, dataError.error);
  [dataErrorMock stopMocking];
}

- (void)testErrorCodeFromErrorParsesCodeFromUserInfo {

  // If
  NSInteger expectedErrorCode = MSHTTPCodesNo500InternalServerError;
  NSDictionary *userInfo = @{@"MSHttpCodeKey" : @(expectedErrorCode)};
  NSError *error = [NSError errorWithDomain:kMSACErrorDomain code:0 userInfo:userInfo];

  // When
  NSInteger actualErrorCode = [MSDataError errorCodeFromError:error];

  // Then
  XCTAssertEqual(expectedErrorCode, actualErrorCode);
}

- (void)testErrorCodeFromErrorReturnsUnknownWhenNoUserInfo {

  // If
  NSInteger expectedErrorCode = MSHTTPCodesNo0XXInvalidUnknown;
  NSError *error = [NSError errorWithDomain:kMSACErrorDomain code:0 userInfo:nil];

  // When
  NSInteger actualErrorCode = [MSDataError errorCodeFromError:error];

  // Then
  XCTAssertEqual(expectedErrorCode, actualErrorCode);
}

@end
