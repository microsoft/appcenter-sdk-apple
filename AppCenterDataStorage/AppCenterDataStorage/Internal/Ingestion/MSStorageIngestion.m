#import "MSAppCenter.h"
#import "MSAppCenterInternal.h"
#import "MSStorageIngestion.h"
#import "MSHttpIngestionPrivate.h"
#import "MSLoggerInternal.h"

@implementation MSStorageIngestion

/**
 * The API paths for latest release requests.
 */
static NSString *const kMSAppSecrectHeader = @"App-Secret";
static NSString *const kMSGetTokenPath = @"/data/tokens";
static NSString *const kMSPartitions = @"partitions";

- (id)initWithBaseUrl:(NSString *)baseUrl
              appSecret:(NSString *)appSecret {

  if ((self = [super initWithBaseUrl:baseUrl
                             apiPath:kMSGetTokenPath
                             headers:@{kMSAppSecrectHeader : appSecret}
                        queryStrings:nil
                        reachability:[MS_Reachability reachabilityForInternetConnection]
                      retryIntervals:@[ @(10), @(5 * 60), @(20 * 60) ]])) {
    _appSecret = appSecret;
  }

  return self;
}

- (NSURLRequest *)createRequest:(NSObject *)data {
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.sendURL];

  // Set method.
  request.HTTPMethod = @"POST";

  // Set header params.
  request.allHTTPHeaderFields = self.httpHeaders;
  
  // Set body.
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:@{kMSPartitions : data} options:0 error:NULL];
  request.HTTPBody = jsonData;

  // Always disable cookies.
  [request setHTTPShouldHandleCookies:NO];

  // Don't lose time pretty printing headers if not going to be printed.
  if ([MSLogger currentLogLevel] <= MSLogLevelVerbose) {
    NSString *url = [request.URL.absoluteString stringByReplacingOccurrencesOfString:self.appSecret
                                                                          withString:[MSIngestionUtil hideSecret:self.appSecret]];
    MSLogVerbose([MSAppCenter logTag], @"URL: %@", url);
    MSLogVerbose([MSAppCenter logTag], @"Headers: %@", [super prettyPrintHeaders:request.allHTTPHeaderFields]);
  }

  return request;
}

- (NSString *)obfuscateHeaderValue:(NSString *)value forKey:(NSString *)key {
  return [key isEqualToString:kMSHeaderUpdateApiToken] ? [MSIngestionUtil hideSecret:value] : value;
}

@end
