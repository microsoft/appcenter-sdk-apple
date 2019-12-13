// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSHttpIngestion.h"
#import "MSAppCenterInternal.h"
#import "MSConstants+Internal.h"
#import "MSHttpIngestionPrivate.h"
#import "MSHttpClientPrivate.h"
#import "MSLoggerInternal.h"
#import "MSUtility+StringFormatting.h"

// URL components' name within a partial URL.
static NSString *const kMSPartialURLComponentsName[] = {@"scheme", @"user", @"password", @"host", @"port", @"path"};

@implementation MSHttpIngestion

@synthesize baseURL = _baseURL;
@synthesize apiPath = _apiPath;

#pragma mark - Initialize

- (id)initWithHttpClient:(id<MSHttpClientProtocol>)httpClient
                 baseUrl:(NSString *)baseUrl
                 apiPath:(NSString *)apiPath
                 headers:(NSDictionary *)headers
            queryStrings:(NSDictionary *)queryStrings {
  return [self initWithHttpClient:httpClient
                          baseUrl:baseUrl
                          apiPath:apiPath
                          headers:headers
                     queryStrings:queryStrings
                   retryIntervals:@[ @(10), @(5 * 60), @(20 * 60) ]];
}

- (id)initWithHttpClient:(id<MSHttpClientProtocol>)httpClient
                 baseUrl:(NSString *)baseUrl
                 apiPath:(NSString *)apiPath
                 headers:(NSDictionary *)headers
            queryStrings:(NSDictionary *)queryStrings
          retryIntervals:(NSArray *)retryIntervals {
  return [self initWithHttpClient:httpClient
                          baseUrl:baseUrl
                          apiPath:apiPath
                          headers:headers
                     queryStrings:queryStrings
                   retryIntervals:retryIntervals
           maxNumberOfConnections:4];
}

- (id)initWithHttpClient:(id<MSHttpClientProtocol>)httpClient
                   baseUrl:(NSString *)baseUrl
                   apiPath:(NSString *)apiPath
                   headers:(NSDictionary *)headers
              queryStrings:(NSDictionary *)queryStrings
            retryIntervals:(NSArray *)retryIntervals
    maxNumberOfConnections:(NSInteger)maxNumberOfConnections {
  if ((self = [super init])) {
    _httpHeaders = headers;
    _httpClient = httpClient;
    _enabled = YES;
    _callsRetryIntervals = retryIntervals;
    _apiPath = apiPath;
    _maxNumberOfConnections = maxNumberOfConnections;
    _baseURL = baseUrl;
    
    httpClient.delegate = self;

    // Construct the URL string with the query string.
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@%@", baseUrl, apiPath];
    __block NSMutableString *queryStringForEncoding = [NSMutableString new];

    // Set query parameter.
    [queryStrings enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull queryString, __unused BOOL *_Nonnull stop) {
      [queryStringForEncoding
          appendString:[NSString stringWithFormat:@"%@%@=%@", [queryStringForEncoding length] > 0 ? @"&" : @"", key, queryString]];
    }];
    if ([queryStringForEncoding length] > 0) {
      [urlString appendFormat:@"?%@", [queryStringForEncoding
                                          stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    }

    // Set send URL which can't be null
    _sendURL = (NSURL * _Nonnull)[NSURL URLWithString:urlString];
  }
  return self;
}

#pragma mark - MSIngestion

- (BOOL)isReadyToSend {
  return YES;
}

- (void)sendAsync:(NSObject *)data authToken:(nullable NSString *)authToken completionHandler:(MSSendAsyncCompletionHandler)handler {
  [self sendAsync:data eTag:nil authToken:authToken callId:MS_UUID_STRING completionHandler:handler];
}

- (void)sendAsync:(NSObject *)data
                 eTag:(nullable NSString *)eTag
            authToken:(nullable NSString *)authToken
    completionHandler:(MSSendAsyncCompletionHandler)handler {
  [self sendAsync:data eTag:eTag authToken:authToken callId:MS_UUID_STRING completionHandler:handler];
}

- (void)sendAsync:(NSObject *)data completionHandler:(MSSendAsyncCompletionHandler)handler {
  [self sendAsync:data eTag:nil authToken:nil callId:MS_UUID_STRING completionHandler:handler];
}

- (void)sendAsync:(NSObject *)data eTag:(nullable NSString *)eTag completionHandler:(MSSendAsyncCompletionHandler)handler {
  [self sendAsync:data eTag:eTag authToken:nil callId:MS_UUID_STRING completionHandler:handler];
}

#pragma mark - Life cycle

- (void)setEnabled:(BOOL)isEnabled andDeleteDataOnDisabled:(BOOL __unused)deleteData {
  @synchronized(self) {
    self.enabled = isEnabled;
  }
}

#pragma mark - Private

- (void)setBaseURL:(NSString *)baseURL {
  @synchronized(self) {
    BOOL success = false;
    NSURLComponents *components;
    _baseURL = baseURL;
    NSURL *partialURL = [NSURL URLWithString:[baseURL stringByAppendingString:self.apiPath]];

    // Merge new parial URL and current full URL.
    if (partialURL) {
      components = [NSURLComponents componentsWithURL:self.sendURL resolvingAgainstBaseURL:NO];
      @try {
        for (u_long i = 0; i < sizeof(kMSPartialURLComponentsName) / sizeof(*kMSPartialURLComponentsName); i++) {
          NSString *propertyName = kMSPartialURLComponentsName[i];
          [components setValue:[partialURL valueForKey:propertyName] forKey:propertyName];
        }
      } @catch (NSException *ex) {
        MSLogInfo([MSAppCenter logTag], @"Error while updating HTTP URL %@ with %@: \n%@", self.sendURL.absoluteString, baseURL, ex);
      }

      // Update full URL.
      if (components.URL) {
        self.sendURL = (NSURL * _Nonnull) components.URL;
        success = true;
      }
    }

    // Notify failure.
    if (!success) {
      MSLogInfo([MSAppCenter logTag], @"Failed to update HTTP URL %@ with %@", self.sendURL.absoluteString, baseURL);
    }
  }
}

- (void)sendAsync:(NSObject *)data
                 eTag:(nullable NSString *)eTag
            authToken:(nullable NSString *)authToken
               callId:(NSString *)callId
    completionHandler:(MSSendAsyncCompletionHandler)handler {
  @synchronized(self) {
    if (!self.enabled) {
      return;
    }
    NSDictionary *httpHeaders = [self getHeadersWithData:data eTag:eTag authToken:authToken];
    NSData *payload = [self getPayloadWithData:data];
    [self.httpClient sendAsync:self.sendURL
                        method:[self getHttpMethod]
                       headers:httpHeaders
                          data:payload
                retryIntervals:self.callsRetryIntervals
            compressionEnabled:YES
             completionHandler:^(NSData *_Nullable responseBody, NSHTTPURLResponse *_Nullable response, NSError *_Nullable error) {
               [self printResponse:response body:responseBody error:error];
               handler(callId, response, responseBody, error);
             }];
  }
}

#pragma mark - Printing

- (void)printResponse:(NSHTTPURLResponse *)response body:(NSData *)responseBody error:(NSError *)error {

  // Don't lose time pretty printing if not going to be printed.
  if (error) {
    MSLogDebug([MSAppCenter logTag], @"HTTP request error with code: %td, domain: %@, description: %@", error.code, error.domain,
               error.localizedDescription);
  } else if ([MSAppCenter logLevel] <= MSLogLevelVerbose) {
    NSString *contentType = response.allHeaderFields[kMSHeaderContentTypeKey];
    NSString *payload;

    // Obfuscate payload.
    if (responseBody.length > 0) {
      if ([contentType hasPrefix:@"application/json"]) {
        payload = [self obfuscateResponsePayload:[MSUtility prettyPrintJson:responseBody]];
      } else if (!contentType.length || [contentType hasPrefix:@"text/"] || [contentType hasPrefix:@"application/"]) {
        payload = [self obfuscateResponsePayload:[[NSString alloc] initWithData:responseBody encoding:NSUTF8StringEncoding]];
      } else {
        payload = @"<binary>";
      }
    }
    MSLogVerbose([MSAppCenter logTag], @"HTTP response received with status code: %tu, payload:\n%@", response.statusCode, payload);
  }
}

// This method will be overridden by subclasses.
- (NSDictionary *)getHeadersWithData:(NSObject *__unused)data eTag:(NSString *__unused)eTag authToken:(NSString *__unused)authToken {
  return nil;
}

// This method will be overridden by subclasses.
- (NSData *)getPayloadWithData:(NSObject *__unused)data {
  return nil;
}

// This method will be overridden by subclasses.
- (NSString *)obfuscateResponsePayload:(NSString *__unused)payload {
  return nil;
}

- (NSString *)getHttpMethod {
  return kMSHttpMethodPost;
};

#pragma mark - Helper

+ (nullable NSString *)eTagFromResponse:(NSHTTPURLResponse *)response {

  // Response header keys are case-insensitive but NSHTTPURLResponse contains case-sensitive keys in Dictionary.
  for (NSString *key in response.allHeaderFields.allKeys) {
    if ([[key lowercaseString] isEqualToString:kMSETagResponseHeader]) {
      return response.allHeaderFields[key];
    }
  }
  return nil;
}

@end
