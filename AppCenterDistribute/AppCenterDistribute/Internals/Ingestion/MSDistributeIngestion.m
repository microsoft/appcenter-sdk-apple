// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDistributeIngestion.h"
#import "MSAppCenter.h"
#import "MSAppCenterInternal.h"
#import "MSHttpIngestionPrivate.h"
#import "MSLoggerInternal.h"

@implementation MSDistributeIngestion

/**
 * The API paths for latest release requests.
 */
static NSString *const kMSLatestPrivateReleaseApiPathFormat = @"/sdk/apps/%@/releases/latest";
static NSString *const kMSLatestPublicReleaseApiPathFormat = @"/public/sdk/apps/%@/distribution_groups/%@/releases/latest";

- (id)initWithHttpClient:(id<MSHttpClientProtocol>)httpClient
                 baseUrl:(NSString *)baseUrl
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
  if ((self = [super initWithHttpClient:httpClient
                                baseUrl:baseUrl
                             apiPath:apiPath
                             headers:header
                        queryStrings:queryStrings])) {
    _appSecret = appSecret;
  }

  return self;
}

- (NSURLRequest *)createRequest:(NSObject *)__unused data eTag:(NSString *)__unused eTag authToken:(nullable NSString *)__unused authToken {
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.sendURL];

  // Set method.
  request.HTTPMethod = @"GET";

  // Set header params.
  request.allHTTPHeaderFields = self.httpHeaders;

  // Set body.
  request.HTTPBody = nil;

  // Always disable cookies.
  [request setHTTPShouldHandleCookies:NO];

  // Don't lose time pretty printing headers if not going to be printed.
  if ([MSLogger currentLogLevel] <= MSLogLevelVerbose) {
    NSString *url = [request.URL.absoluteString stringByReplacingOccurrencesOfString:self.appSecret
                                                                          withString:[MSHttpUtil hideSecret:self.appSecret]];
    MSLogVerbose([MSAppCenter logTag], @"URL: %@", url);
    MSLogVerbose([MSAppCenter logTag], @"Headers: %@", [super prettyPrintHeaders:request.allHTTPHeaderFields]);
  }

  return request;
}

- (NSString *)obfuscateHeaderValue:(NSString *)value forKey:(NSString *)key {
  return [key isEqualToString:kMSHeaderUpdateApiToken] ? [MSHttpUtil hideSecret:value] : value;
}

@end
