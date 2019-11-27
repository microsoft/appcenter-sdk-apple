// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthConfigIngestion.h"
#import "MSAppCenter.h"
#import "MSAppCenterInternal.h"
#import "MSAuthConstants.h"
#import "MSAuthPrivate.h"
#import "MSHttpIngestionPrivate.h"
#import "MSLoggerInternal.h"
#import "MSHttpClientProtocol.h"

@implementation MSAuthConfigIngestion

- (id)initWithHttpClient:(id<MSHttpClientProtocol>)httpClient
                 baseUrl:(NSString *)baseUrl appSecret:(NSString *)appSecret {
  NSString *apiPath = [NSString stringWithFormat:kMSAuthConfigApiFormat, appSecret];
  if ((self = [super initWithHttpClient:httpClient
                                baseUrl:baseUrl
                             apiPath:apiPath
                             headers:nil
                        queryStrings:nil])) {
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
                                                                          withString:[MSHttpUtil hideSecret:self.appSecret]];
    MSLogVerbose([MSAuth logTag], @"URL: %@", url);
    if (request.allHTTPHeaderFields) {
      MSLogVerbose([MSAuth logTag], @"Headers: %@", [super prettyPrintHeaders:request.allHTTPHeaderFields]);
    }
  }
  return request;
}

- (NSString *)obfuscateHeaderValue:(NSString *)value forKey:(NSString *)__unused key {

  // No secrets in headers at the moment.
  return value;
}

@end
