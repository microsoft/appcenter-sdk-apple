#import "MSDistribute.h"
#import "MSDistributeSender.h"
#import "MSHttpSenderPrivate.h"
#import "MSLogger.h"
#import "MSMobileCenter.h"
#import "MSMobileCenterInternal.h"

@implementation MSDistributeSender

/**
 * The API paths for latest release requests.
 */
static NSString *const kMSLatestPrivateReleaseApiPathFormat = @"/sdk/apps/%@/releases/latest";
static NSString *const kMSLatestPublicReleaseApiPathFormat =
    @"/public/sdk/apps/%@/distribution_groups/%@/releases/latest";

- (id)initWithBaseUrl:(NSString *)baseUrl
              appSecret:(NSString *)appSecret
            updateToken:(NSString *)updateToken
    distributionGroupId:(NSString *)distributionGroupId
           queryStrings:(NSDictionary *)queryStrings {
  NSString *apiPath;
  NSDictionary *header = nil;
  if (updateToken) {
    apiPath = [NSString stringWithFormat:kMSLatestPrivateReleaseApiPathFormat, appSecret];
    header = @{kMSHeaderUpdateApiToken : updateToken};
  } else {
    apiPath = [NSString stringWithFormat:kMSLatestPublicReleaseApiPathFormat, appSecret, distributionGroupId];
  }
  if ((self = [super initWithBaseUrl:baseUrl
                             apiPath:apiPath
                             headers:header
                        queryStrings:queryStrings
                        reachability:[MS_Reachability reachabilityForInternetConnection]
                      retryIntervals:@[ @(10), @(5 * 60), @(20 * 60) ]])) {
    self.appSecret = [[MSDistribute sharedInstance] appSecret];
  }

  return self;
}

- (NSURLRequest *)createRequest:(NSObject *)data {
  (void)data;
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
