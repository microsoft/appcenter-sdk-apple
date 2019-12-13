// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDistributeIngestion.h"
#import "MSAppCenter.h"
#import "MSAppCenterInternal.h"
#import "MSConstants+Internal.h"
#import "MSHttpIngestionPrivate.h"
#import "MSLoggerInternal.h"
#import "MSUtility+StringFormatting.h"

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
  if ((self = [super initWithHttpClient:httpClient baseUrl:baseUrl apiPath:apiPath headers:header queryStrings:queryStrings])) {
    _appSecret = appSecret;
  }

  return self;
}

- (NSString *)getHttpMethod {
  return kMSHttpMethodGet;
};

- (NSDictionary *)getHeadersWithData:(NSObject *__unused)data eTag:(NSString *)eTag authToken:(NSString *__unused)authToken {

  // Set Header params.
  NSMutableDictionary *headers = [self.httpHeaders mutableCopy];
  if (eTag != nil) {
    [headers setValue:eTag forKey:kMSETagRequestHeader];
  }
  return headers;
}

- (NSData *)getPayloadWithData:(NSObject *__unused)data {
  return nil;
}

- (NSString *)obfuscateResponsePayload:(NSString *)payload {
  return [MSUtility obfuscateString:payload
                searchingForPattern:kMSRedirectUriPattern
              toReplaceWithTemplate:kMSRedirectUriObfuscatedTemplate];
}

#pragma mark - MSHttpClientDelegate

- (void)willSendHTTPRequestToURL:(NSURL *)url withHeaders:(NSDictionary<NSString *, NSString *> *)headers {

  // Don't lose time pretty printing headers if not going to be printed.
  if ([MSLogger currentLogLevel] <= MSLogLevelVerbose) {

    // Obfuscate secrets.
    NSMutableArray<NSString *> *flattenedHeaders = [NSMutableArray<NSString *> new];
    [headers enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop __unused) {
      if ([key isEqualToString:kMSHeaderUpdateApiToken]) {
        value = [MSHttpUtil hideSecret:value];
      }
      [flattenedHeaders addObject:[NSString stringWithFormat:@"%@ = %@", key, value]];
    }];

    // Log URL and headers.
    MSLogVerbose([MSAppCenter logTag], @"URL: %@", url);
    MSLogVerbose([MSAppCenter logTag], @"Headers: %@", [flattenedHeaders componentsJoinedByString:@", "]);
  }
}

@end
