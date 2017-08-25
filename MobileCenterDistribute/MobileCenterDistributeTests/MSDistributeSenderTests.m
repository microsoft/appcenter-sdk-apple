#import "MSDistributePrivate.h"
#import "MSDistributeSender.h"
#import "MSHttpSenderPrivate.h"
#import "MSLogger.h"
#import "MSTestFrameworks.h"

@interface MSDistributeSenderTests : XCTestCase

@end

@implementation MSDistributeSenderTests

#pragma mark - Tests

- (void)testCreateRequest {

  // If
  NSString *baseUrl = @"https://contoso.com";
  NSString *apiPath = @"/test";
  NSDictionary *header = OCMClassMock([NSDictionary class]);
  MSDistributeSender *sender = [[MSDistributeSender alloc] initWithBaseUrl:baseUrl
                                                                   apiPath:apiPath
                                                                   headers:header
                                                              queryStrings:nil
                                                              reachability:nil
                                                            retryIntervals:@[]];

  // When
  NSURLRequest *request = [sender createRequest:[NSData new]];

  // Then
  assertThat(request.HTTPMethod, equalTo(@"GET"));
  assertThat(request.allHTTPHeaderFields, equalTo(header));
  assertThat(request.HTTPBody, equalTo(nil));
  assertThat(request.URL.absoluteString, startsWith([NSString stringWithFormat:@"%@%@", baseUrl, apiPath]));

  XCTAssertFalse(request.HTTPShouldHandleCookies);

  // If
  NSString *appSecret = @"secret";
  NSString *updateToken = @"updateToken";
  NSString *secretApiPath = [NSString stringWithFormat:@"/sdk/apps/%@/releases/latest", appSecret];
  [MSLogger setCurrentLogLevel:MSLogLevelVerbose];
  id distributeMock = OCMPartialMock([MSDistribute sharedInstance]);
  OCMStub([distributeMock appSecret]).andReturn(@"secret");
  MSDistributeSender *sender1 = [[MSDistributeSender alloc] initWithBaseUrl:baseUrl appSecret:appSecret updateToken:updateToken queryStrings:@{}];

  // When
  NSURLRequest *request1 = [sender1 createRequest:[NSData new]];

  // Then
  assertThat(request1.HTTPMethod, equalTo(@"GET"));
  assertThat(request1.allHTTPHeaderFields, equalTo(@{kMSHeaderUpdateApiToken : updateToken}));
  assertThat(request1.HTTPBody, equalTo(nil));
  assertThat(request1.URL.absoluteString, startsWith([NSString stringWithFormat:@"%@%@", baseUrl, secretApiPath]));

  XCTAssertFalse(request1.HTTPShouldHandleCookies);
}

@end
