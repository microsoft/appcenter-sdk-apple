// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACDistributeIngestion.h"
#import "MSACAppCenter.h"
#import "MSACAppCenterInternal.h"
#import "MSACConstants+Internal.h"
#import "MSACHttpIngestionPrivate.h"
#import "MSACLoggerInternal.h"
#import "MSACUtility+StringFormatting.h"

@implementation MSACDistributeIngestion

/**
 * The API paths for latest release requests.
 */
static NSString *const kMSACLatestPrivateReleaseApiPathFormat = @"/sdk/apps/%@/releases/private/latest";
static NSString *const kMSACLatestPublicReleaseApiPathFormat = @"/public/sdk/apps/%@/releases/latest";

- (id)initWithHttpClient:(id<MSACHttpClientProtocol>)httpClient baseUrl:(NSString *)baseUrl appSecret:(NSString *)appSecret {
  if ((self = [super initWithHttpClient:httpClient baseUrl:baseUrl apiPath:nil headers:nil queryStrings:nil])) {
    _appSecret = appSecret;
  }
  return self;
}

- (NSString *)getHttpMethod {
  return kMSACHttpMethodGet;
};

- (NSDictionary *)getHeadersWithData:(NSObject *__unused)data eTag:(NSString *__unused)eTag {
  return self.httpHeaders;
}

- (NSData *)getPayloadWithData:(NSObject *__unused)data {
  return nil;
}

- (NSString *)obfuscateResponsePayload:(NSString *)payload {
  return [MSACUtility obfuscateString:payload
                  searchingForPattern:kMSACRedirectUriPattern
                toReplaceWithTemplate:kMSACRedirectUriObfuscatedTemplate];
}

#pragma mark - MSACHttpClientDelegate

- (void)willSendHTTPRequestToURL:(NSURL *)url withHeaders:(nullable NSDictionary<NSString *, NSString *> *)headers {

  // Don't lose time pretty printing headers if not going to be printed.
  if ([MSACLogger currentLogLevel] <= MSACLogLevelVerbose) {

    // Obfuscate secrets.
    NSMutableArray<NSString *> *flattenedHeaders = [NSMutableArray<NSString *> new];
    [headers enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop __unused) {
      if ([key isEqualToString:kMSACHeaderUpdateApiToken]) {
        value = [MSACHttpUtil hideSecret:value];
      }
      [flattenedHeaders addObject:[NSString stringWithFormat:@"%@ = %@", key, value]];
    }];

    // Log URL and headers.
    MSACLogVerbose([MSACAppCenter logTag], @"URL: %@", [MSACHttpUtil hideSecretInString:url.absoluteString secret:self.appSecret]);
    MSACLogVerbose([MSACAppCenter logTag], @"Headers: %@", [flattenedHeaders componentsJoinedByString:@", "]);
  }
}

#pragma mark - MSACDistributeIngestion

- (void)checkForPublicUpdateWithQueryStrings:(NSDictionary *)queryStrings
                           completionHandler:(MSACSendAsyncCompletionHandler)completionHandler {
  self.httpHeaders = @{};
  self.apiPath = [NSString stringWithFormat:kMSACLatestPublicReleaseApiPathFormat, self.appSecret];
  self.sendURL = [super buildURLWithBaseURL:self.baseURL apiPath:self.apiPath queryStrings:queryStrings];
  [self sendAsync:nil completionHandler:completionHandler];
}

- (void)checkForPrivateUpdateWithUpdateToken:(NSString *)updateToken
                                queryStrings:(NSDictionary *)queryStrings
                           completionHandler:(MSACSendAsyncCompletionHandler)completionHandler {
  self.httpHeaders = @{kMSACHeaderUpdateApiToken : updateToken};
  self.apiPath = [NSString stringWithFormat:kMSACLatestPrivateReleaseApiPathFormat, self.appSecret];
  self.sendURL = [super buildURLWithBaseURL:self.baseURL apiPath:self.apiPath queryStrings:queryStrings];
  [self sendAsync:nil completionHandler:completionHandler];
}

@end
