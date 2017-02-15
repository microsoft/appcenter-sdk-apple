#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "MSDistributionSender.h"
#import "MSHttpSenderPrivate.h"


@interface MSDistributionSenderTests : XCTestCase

@end

@implementation MSDistributionSenderTests

#pragma mark - Tests

- (void)testCreateRequest {
  NSString *baseUrl = @"https://contoso.com";
  NSString *apiPath = @"/test";
  NSDictionary *header = OCMClassMock([NSDictionary class]);
  MSDistributionSender *sender = [[MSDistributionSender alloc] initWithBaseUrl:baseUrl
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
