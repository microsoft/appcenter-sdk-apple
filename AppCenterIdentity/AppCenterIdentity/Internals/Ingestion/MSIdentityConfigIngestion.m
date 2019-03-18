#import "MSIdentityConfigIngestion.h"
#import "MSAppCenter.h"
#import "MSAppCenterInternal.h"
#import "MSHttpIngestionPrivate.h"
#import "MSIdentityConstants.h"
#import "MSIdentityPrivate.h"
#import "MSLoggerInternal.h"

@implementation MSIdentityConfigIngestion

- (id)initWithBaseURL:(NSString *)baseURL appSecret:(NSString *)appSecret {
  NSString *apiPath = [NSString stringWithFormat:kMSIdentityConfigApiFormat, appSecret];
  if ((self = [super initWithBaseUrl:baseURL
                             apiPath:apiPath
                             headers:nil
                        queryStrings:nil
                        reachability:[MS_Reachability reachabilityForInternetConnection]])) {
    _appSecret = appSecret;
  }

  return self;
}

- (NSURLRequest *)createRequest:(NSObject *)__unused data eTag:(NSString *)eTag authToken:(nullable NSString *)__unused authToken {

  // Ignoring local cache data to receive 304 when configuration hasn't changed since last download.
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.sendURL
                                                         cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                     timeoutInterval:0];

  // Set method.
  request.HTTPMethod = @"GET";

  // Set Header params.
  request.allHTTPHeaderFields = self.httpHeaders;
  if (eTag != nil) {
    [request setValue:eTag forHTTPHeaderField:kMSETagRequestHeader];
  }

  // Always disable cookies.
  [request setHTTPShouldHandleCookies:NO];

  // Don't lose time pretty printing headers if not going to be printed.
  if ([MSLogger currentLogLevel] <= MSLogLevelVerbose) {
    NSString *url = [request.URL.absoluteString stringByReplacingOccurrencesOfString:self.appSecret
                                                                          withString:[MSIngestionUtil hideSecret:self.appSecret]];
    MSLogVerbose([MSIdentity logTag], @"URL: %@", url);
    if (request.allHTTPHeaderFields) {
      MSLogVerbose([MSIdentity logTag], @"Headers: %@", [super prettyPrintHeaders:request.allHTTPHeaderFields]);
    }
  }
  return request;
}

- (NSString *)obfuscateHeaderValue:(NSString *)value forKey:(NSString *)__unused key {

  // No secrets in headers at the moment.
  return value;
}

@end
