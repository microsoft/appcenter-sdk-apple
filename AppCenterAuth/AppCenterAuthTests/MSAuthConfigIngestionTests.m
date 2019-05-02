// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSAuth.h"
#import "MSAuthConfigIngestion.h"
#import "MSLoggerInternal.h"
#import "MSTestFrameworks.h"

@interface MSAuthConfigIngestionTests : XCTestCase

@end

@implementation MSAuthConfigIngestionTests

- (void)testCreateRequestWithETag {

  // If
  NSString *baseUrl = @"https://contoso.com";
  NSString *appSecret = @"secret";
  NSString *apiPath = [NSString stringWithFormat:@"/auth/%@.json", appSecret];
  NSDictionary *header = @{@"If-None-Match" : @"eTag"};
  NSString *eTag = @"eTag";
  MSAuthConfigIngestion *ingestion = [[MSAuthConfigIngestion alloc] initWithBaseUrl:baseUrl appSecret:appSecret];

  // When
  NSURLRequest *request = [ingestion createRequest:[NSData new] eTag:eTag authToken:nil];

  // Then
  assertThat(request.HTTPMethod, equalTo(@"GET"));
  assertThat(request.allHTTPHeaderFields, equalTo(header));
  assertThat(request.HTTPBody, equalTo(nil));
  assertThat(request.URL.absoluteString, startsWith([NSString stringWithFormat:@"%@%@", baseUrl, apiPath]));
  XCTAssertFalse(request.HTTPShouldHandleCookies);
}

- (void)testCreateRequestWithoutETag {

  // If
  NSString *baseUrl = @"https://contoso.com";
  NSString *appSecret = @"secret";
  NSString *apiPath = [NSString stringWithFormat:@"/auth/%@.json", appSecret];
  MSAuthConfigIngestion *ingestion = [[MSAuthConfigIngestion alloc] initWithBaseUrl:baseUrl appSecret:appSecret];

  // When
  NSURLRequest *request = [ingestion createRequest:[NSData new] eTag:nil authToken:nil];

  // Then
  assertThat(request.HTTPMethod, equalTo(@"GET"));
  assertThat(request.allHTTPHeaderFields, equalTo(@{}));
  assertThat(request.HTTPBody, equalTo(nil));
  assertThat(request.URL.absoluteString, startsWith([NSString stringWithFormat:@"%@%@", baseUrl, apiPath]));
  XCTAssertFalse(request.HTTPShouldHandleCookies);

  // If
  [MSLogger setCurrentLogLevel:MSLogLevelVerbose];
  MSAuthConfigIngestion *ingestion1 = [[MSAuthConfigIngestion alloc] initWithBaseUrl:baseUrl appSecret:appSecret];

  // When
  NSURLRequest *request1 = [ingestion1 createRequest:[NSData new] eTag:nil authToken:nil];

  // Then
  assertThat(request1.HTTPMethod, equalTo(@"GET"));
  assertThat(request1.HTTPBody, equalTo(nil));
  assertThat(request1.URL.absoluteString, startsWith([NSString stringWithFormat:@"%@%@", baseUrl, apiPath]));
  XCTAssertFalse(request1.HTTPShouldHandleCookies);
}

@end
