#import "MSDistributeIngestion.h"
#import "MSDistributePrivate.h"
#import "MSHttpIngestionPrivate.h"
#import "MSLoggerInternal.h"
#import "MSTestFrameworks.h"

@interface MSDistributeIngestionTests : XCTestCase

@end

@implementation MSDistributeIngestionTests

#pragma mark - Tests

- (void)testCreateRequest {

  // If
  NSString *baseUrl = @"https://contoso.com";
  NSString *apiPath = @"/test";
  NSDictionary *header = OCMClassMock([NSDictionary class]);
  MSDistributeIngestion *ingestion = [[MSDistributeIngestion alloc] initWithBaseUrl:baseUrl
                                                                            apiPath:apiPath
                                                                            headers:header
                                                                       queryStrings:nil
                                                                       reachability:nil
                                                                     retryIntervals:@[]];

  // When
  NSURLRequest *request = [ingestion createRequest:[NSData new]];

  // Then
  assertThat(request.HTTPMethod, equalTo(@"GET"));
  assertThat(request.allHTTPHeaderFields, equalTo(header));
  assertThat(request.HTTPBody, equalTo(nil));
  assertThat(request.URL.absoluteString, startsWith([NSString stringWithFormat:@"%@%@", baseUrl, apiPath]));

  XCTAssertFalse(request.HTTPShouldHandleCookies);

  // If
  NSString *appSecret = @"secret";
  NSString *updateToken = @"updateToken";
  NSString *distributionGroupId = @"groupId";
  NSString *secretApiPath = [NSString stringWithFormat:@"/sdk/apps/%@/releases/latest", appSecret];
  [MSLogger setCurrentLogLevel:MSLogLevelVerbose];
  id distributeMock = OCMPartialMock([MSDistribute sharedInstance]);
  OCMStub([distributeMock appSecret]).andReturn(@"secret");
  MSDistributeIngestion *ingestion1 = [[MSDistributeIngestion alloc] initWithBaseUrl:baseUrl
                                                                           appSecret:appSecret
                                                                         updateToken:updateToken
                                                                 distributionGroupId:distributionGroupId
                                                                        queryStrings:@{}];

  // When
  NSURLRequest *request1 = [ingestion1 createRequest:[NSData new]];

  // Then
  assertThat(request1.HTTPMethod, equalTo(@"GET"));
  assertThat(request1.allHTTPHeaderFields, equalTo(@{kMSHeaderUpdateApiToken : updateToken}));
  assertThat(request1.HTTPBody, equalTo(nil));
  assertThat(request1.URL.absoluteString, startsWith([NSString stringWithFormat:@"%@%@", baseUrl, secretApiPath]));

  XCTAssertFalse(request1.HTTPShouldHandleCookies);
}

@end
