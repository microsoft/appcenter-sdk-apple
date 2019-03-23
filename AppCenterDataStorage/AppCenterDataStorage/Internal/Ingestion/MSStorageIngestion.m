// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSStorageIngestion.h"
#import "MSAppCenter.h"
#import "MSAppCenterInternal.h"
#import "MSHttpIngestionPrivate.h"
#import "MSLoggerInternal.h"

@implementation MSStorageIngestion

/**
 * The API paths for cosmosDb token.
 */
static NSString *const kMSGetTokenPath = @"/data/tokens";

- (id)initWithBaseUrl:(NSString *)baseUrl appSecret:(NSString *)appSecret {
  if ((self = [super initWithBaseUrl:baseUrl
                             apiPath:kMSGetTokenPath
                             headers:@{kMSHeaderAppSecretKey : appSecret, kMSHeaderContentTypeKey : kMSAppCenterContentType}
                        queryStrings:nil
                        reachability:[MS_Reachability reachabilityForInternetConnection]
                      retryIntervals:@[ @(10), @(5 * 60), @(20 * 60) ]])) {
    _appSecret = appSecret;
  }
  return self;
}

- (NSURLRequest *)createRequest:(NSObject *)data eTag:(NSString *)__unused eTag authToken:(nullable NSString *)__unused authToken {
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.sendURL];

  // Set method.
  request.HTTPMethod = @"POST";

  // Set header params.
  request.allHTTPHeaderFields = self.httpHeaders;

  // Set body.
  request.HTTPBody = (NSData *)data;

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
  return [key isEqualToString:kMSHeaderAppSecretKey] ? [MSIngestionUtil hideSecret:value] : value;
}

@end
