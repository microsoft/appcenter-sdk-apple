#import "MSIdentityConfigIngestion.h"
#import "MSAppCenter.h"
#import "MSAppCenterInternal.h"
#import "MSHttpIngestionPrivate.h"
#import "MSIdentityPrivate.h"
#import "MSLoggerInternal.h"

@implementation MSIdentityConfigIngestion

- (id)initWithBaseUrl:(NSString *)baseUrl appSecret:(NSString *)appSecret headers:(NSDictionary *)headers {
  NSString *apiPath = [NSString stringWithFormat:@"/identity/%@.json", appSecret];
  if ((self = [super initWithBaseUrl:baseUrl
                             apiPath:apiPath
                             headers:headers
                        queryStrings:nil
                        reachability:[MS_Reachability reachabilityForInternetConnection]
                      retryIntervals:@[ @(10), @(5 * 60), @(20 * 60) ]])) {
    _appSecret = appSecret;
  }

  return self;
}

- (NSURLRequest *)createRequest:(NSObject *)__unused data {
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.sendURL];

  // Set method.
  request.HTTPMethod = @"GET";

  // Always disable cookies.
  [request setHTTPShouldHandleCookies:NO];

  NSString *url = [request.URL.absoluteString stringByReplacingOccurrencesOfString:self.appSecret
                                                                        withString:[MSIngestionUtil hideSecret:self.appSecret]];
  MSLogVerbose([MSAppCenter logTag], @"URL: %@", url);

  return request;
}

@end
