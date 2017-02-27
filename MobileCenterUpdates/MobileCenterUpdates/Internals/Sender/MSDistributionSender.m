#import "MSDistributionSender.h"
#import "MSHttpSenderPrivate.h"
#import "MSLogger.h"
#import "MSMobileCenter.h"
#import "MSMobileCenterInternal.h"
#import "MSUpdates.h"

@implementation MSDistributionSender

/**
 * The API path for latest release request.
 */
static NSString *const kMSUpdtsLatestReleaseApiPathFormat = @"/sdk/apps/%@/releases/latest";

- (id)initWithBaseUrl:(NSString *)baseUrl
              headers:(NSDictionary *)headers
         queryStrings:(NSDictionary *)queryStrings
         reachability:(MS_Reachability *)reachability
       retryIntervals:(NSArray *)retryIntervals {
  self = [super initWithBaseUrl:baseUrl
                        // FIXME: Temporary fix to avoid merge conflict.
                        apiPath:[NSString stringWithFormat:kMSUpdtsLatestReleaseApiPathFormat,
                                                           [[MSUpdates sharedInstance] appSecret]]
                        headers:headers
                   queryStrings:queryStrings
                   reachability:reachability
                 retryIntervals:retryIntervals];
  if (self) {
    self.appSecret = [[MSUpdates sharedInstance] appSecret];
  }
  return self;
}

- (NSURLRequest *)createRequest:(NSObject *)data {
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.sendURL];

  // Set method.
  request.HTTPMethod = @"GET";

  // Set header params.
  request.allHTTPHeaderFields = self.httpHeaders;

  // Set body.
  request.HTTPBody = nil;

  // Always disable cookies.
  [request setHTTPShouldHandleCookies:NO];

  // Don't loose time pretty printing headers if not going to be printed.
  if ([MSLogger currentLogLevel] <= MSLogLevelVerbose) {
    NSString *url =
        [request.URL.absoluteString stringByReplacingOccurrencesOfString:self.appSecret
                                                              withString:[MSSenderUtil hideSecret:self.appSecret]];
    MSLogVerbose([MSMobileCenter logTag], @"URL: %@", url);
    MSLogVerbose([MSMobileCenter logTag], @"Headers: %@", [super prettyPrintHeaders:request.allHTTPHeaderFields]);
  }

  return request;
}

- (NSString *)obfuscateHeaderValue:(NSString *)key value:(NSString *)value {
  return [key isEqualToString:kMSHeaderUpdateApiToken] ? [MSSenderUtil hideSecret:value] : value;
}

@end
