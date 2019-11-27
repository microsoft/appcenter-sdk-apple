// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSAuth.h"
#import "MSAuthConfigIngestion.h"
#import "MSHttpClient.h"
#import "MSLoggerInternal.h"
#import "MSTestFrameworks.h"

@interface MSAuthConfigIngestionTests : XCTestCase

@end

@implementation MSAuthConfigIngestionTests

- (void)testGetHeadersWithETag {

  // If
  NSString *baseUrl = @"https://contoso.com";
  NSString *appSecret = @"secret";
  // TODO?
  //  NSString *apiPath = [NSString stringWithFormat:@"/auth/%@.json", appSecret];
  NSDictionary *header = @{@"If-None-Match" : @"eTag"};
  NSString *eTag = @"eTag";
  MSAuthConfigIngestion *ingestion = [[MSAuthConfigIngestion alloc] initWithHttpClient:[MSHttpClient new] baseUrl:baseUrl appSecret:appSecret];

  // When
  NSDictionary *headers = [ingestion getHeadersWithData:nil eTag:eTag authToken:nil];
  
  // Then
  assertThat(headers, equalTo(header));
}

- (void)testBodyIsNil {
  
  // If
  NSString *baseUrl = @"https://contoso.com";
  NSString *appSecret = @"secret";
  MSAuthConfigIngestion *ingestion = [[MSAuthConfigIngestion alloc] initWithHttpClient:[MSHttpClient new] baseUrl:baseUrl appSecret:appSecret];
  
  // When
  NSData *payload = [ingestion getPayloadWithData:nil];
  
  // Then
  XCTAssertNil(payload);
}

- (void)testGetHeadersWithoutETag {

  // If
  NSString *baseUrl = @"https://contoso.com";
  NSString *appSecret = @"secret";
  // TODO?
  //  NSString *apiPath = [NSString stringWithFormat:@"/auth/%@.json", appSecret];
  MSAuthConfigIngestion *ingestion = [[MSAuthConfigIngestion alloc] initWithHttpClient:[MSHttpClient new] baseUrl:baseUrl appSecret:appSecret];
  
  // When
  NSDictionary *headers = [ingestion getHeadersWithData:nil eTag:nil authToken:nil];
  
  // Then
  XCTAssertEqual([headers count], 0);
}

@end
