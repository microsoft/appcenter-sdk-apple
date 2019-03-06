#import "MSCosmosDbIngestion.h"
#import "MSAppCenter.h"
#import "MSAppCenterInternal.h"
#import "MSHttpIngestionPrivate.h"
#import "MSLoggerInternal.h"

@implementation MSCosmosDbIngestion

- (instancetype)init {
  // @TODO: clean up once the MSHttpIngestion is refactored to take generic requests.
  if ((self = [super initWithBaseUrl:@""
                             apiPath:@""
                             headers:@{}
                        queryStrings:nil
                        reachability:[MS_Reachability reachabilityForInternetConnection]
                      retryIntervals:@[ @(10), @(5 * 60), @(20 * 60) ]])) {
  }
  return self;
}

- (NSURLRequest *)createRequest:(NSObject *)data eTag:(NSString *)__unused eTag {
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.sendURL];

  // Set method.
  request.HTTPMethod = self.httpVerb;

  // Set header params.
  request.allHTTPHeaderFields = self.httpHeaders;

  // Set body.
  request.HTTPBody = (NSData *)data;

  // Always disable cookies.
  [request setHTTPShouldHandleCookies:NO];

  // Log.
  if ([MSLogger currentLogLevel] <= MSLogLevelVerbose) {
    MSLogVerbose([MSAppCenter logTag], @"Creating CosmosDB request with URL: %@", request.URL.absoluteString);
    MSLogVerbose([MSAppCenter logTag], @"CosmosDB request headers: %@", [super prettyPrintHeaders:request.allHTTPHeaderFields]);
  }
  return request;
}

- (NSString *)obfuscateHeaderValue:(NSString *)value forKey:(NSString *)key {
  return [key isEqualToString:kMSAuthorizationHeaderKey] ? [MSIngestionUtil hideSecret:value] : value;
}

@end
