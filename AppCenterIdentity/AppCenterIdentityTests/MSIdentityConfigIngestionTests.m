#import "MSIdentity.h"
#import "MSIdentityConfigIngestion.h"
#import "MSLoggerInternal.h"
#import "MSTestFrameworks.h"
#import <Foundation/Foundation.h>

@interface MSIdentityConfigIngestionTests : XCTestCase

@end

@implementation MSIdentityConfigIngestionTests

- (void)testCreateRequestWithETag {

  // If
  NSString *baseUrl = @"https://contoso.com";
  NSString *appSecret = @"secret";
  NSString *apiPath = [NSString stringWithFormat:@"/identity/%@.json", appSecret];
  NSDictionary *header = @{@"If-None-Match" : @"eTag"};
  NSString *eTag = @"eTag";
  MSIdentityConfigIngestion *ingestion = [[MSIdentityConfigIngestion alloc] initWithBaseURL:baseUrl appSecret:appSecret];

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
  NSString *apiPath = [NSString stringWithFormat:@"/identity/%@.json", appSecret];
  MSIdentityConfigIngestion *ingestion = [[MSIdentityConfigIngestion alloc] initWithBaseURL:baseUrl appSecret:appSecret];

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
  MSIdentityConfigIngestion *ingestion1 = [[MSIdentityConfigIngestion alloc] initWithBaseURL:baseUrl appSecret:appSecret];

  // When
  NSURLRequest *request1 = [ingestion1 createRequest:[NSData new] eTag:nil authToken:nil];

  // Then
  assertThat(request1.HTTPMethod, equalTo(@"GET"));
  assertThat(request1.HTTPBody, equalTo(nil));
  assertThat(request1.URL.absoluteString, startsWith([NSString stringWithFormat:@"%@%@", baseUrl, apiPath]));
  XCTAssertFalse(request1.HTTPShouldHandleCookies);
}

@end
