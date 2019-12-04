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
#import "MSConstants+Internal.h"

@implementation MSAuthConfigIngestion

- (id)initWithHttpClient:(id<MSHttpClientProtocol>)httpClient
                 baseUrl:(NSString *)baseUrl appSecret:(NSString *)appSecret {
  NSString *apiPath = [NSString stringWithFormat:kMSAuthConfigApiFormat, appSecret];
  if ((self = [super initWithHttpClient:httpClient
                                baseUrl:baseUrl
                                apiPath:apiPath
                                headers:@{}
                           queryStrings:nil])) {
    _appSecret = appSecret;
  }

  return self;
}

- (void)sendAsync:(NSObject *)data authToken:(NSString *)authToken completionHandler:(MSSendAsyncCompletionHandler)handler {
  [super sendAsync:data authToken:authToken completionHandler:handler];
}

- (NSString *)getHttpMethod {
  return kMSHttpMethodGet;
};

- (NSString *)obfuscateHeaderValue:(NSString *)value forKey:(NSString *)__unused key {

  // No secrets in headers at the moment.
  return value;
}

- (NSDictionary *)getHeadersWithData:(NSObject * __unused)data eTag:(NSString *)eTag authToken:(NSString * __unused)authToken {
  
  // Set Header params.
  NSMutableDictionary *headers = [self.httpHeaders mutableCopy];
  if (eTag != nil) {
    [headers setValue:eTag forKey:kMSETagRequestHeader];
  }
  return headers;
}

- (NSData *)getPayloadWithData:(NSObject * __unused)data {
  return nil;
}

@end
