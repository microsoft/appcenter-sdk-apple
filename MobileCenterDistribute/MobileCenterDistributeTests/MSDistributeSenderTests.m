#import "MSDistributeSender.h"
#import "MSHttpSenderPrivate.h"
#import "MSTestFrameworks.h"

@interface MSDistributeSenderTests : XCTestCase

@end

@implementation MSDistributeSenderTests

#pragma mark - Tests

- (void)testCreateRequest {
  NSString *baseUrl = @"https://contoso.com";
  NSString *apiPath = @"/test";
  NSDictionary *header = OCMClassMock([NSDictionary class]);
  MSDistributeSender *sender = [[MSDistributeSender alloc] initWithBaseUrl:baseUrl
                                                                   apiPath:apiPath
                                                                   headers:header
                                                              queryStrings:nil
                                                              reachability:nil
                                                            retryIntervals:@[]];

  NSURLRequest *request = [sender createRequest:[NSData new]];

  assertThat(request.HTTPMethod, equalTo(@"GET"));
  assertThat(request.allHTTPHeaderFields, equalTo(header));
  assertThat(request.HTTPBody, equalTo(nil));
  assertThat(request.URL.absoluteString, startsWith([NSString stringWithFormat:@"%@%@", baseUrl, apiPath]));

  XCTAssertFalse(request.HTTPShouldHandleCookies);
}

@end
