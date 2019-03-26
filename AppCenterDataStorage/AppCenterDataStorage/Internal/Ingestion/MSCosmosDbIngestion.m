// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSCosmosDbIngestion.h"
#import "MSAppCenter.h"
#import "MSAppCenterInternal.h"
#import "MSHttpIngestionPrivate.h"
#import "MSLoggerInternal.h"

@implementation MSCosmosDbIngestion

@synthesize offlineMode = _offlineMode;

- (instancetype)init {
  // @TODO: clean up once the MSHttpIngestion is refactored to take generic requests.
  if ((self = [super initWithBaseUrl:@""
                             apiPath:@""
                             headers:@{}
                        queryStrings:nil
                        reachability:[MS_Reachability reachabilityForInternetConnection]
                      retryIntervals:@[ @(10), @(5 * 60), @(20 * 60) ]])) {
    _offlineMode = NO;
  }
  return self;
}

- (void)setOfflineMode:(BOOL)offlineMode {
    _offlineMode = offlineMode;
}

- (void)sendAsync:(nullable NSObject *)data
                 eTag:(nullable NSString *)eTag
            authToken:(nullable NSString *)authToken
               callId:(NSString *)callId
    completionHandler:(MSSendAsyncCompletionHandler)completionHandler {
  if (self.offlineMode) {
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"Storage offline simulation mode is enabled."};
    completionHandler(callId, nil, nil,
                      [NSError errorWithDomain:MSDataStorageErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:userInfo]);
  } else {
    [super sendAsync:data eTag:eTag authToken:authToken callId:callId completionHandler:completionHandler];
  }
}

- (NSURLRequest *)createRequest:(NSObject *)data eTag:(NSString *)__unused eTag authToken:(nullable NSString *)__unused authToken {
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.sendURL];

  // Set method.
  request.HTTPMethod = self.httpMethod;

  // Set header params.
  request.allHTTPHeaderFields = self.httpHeaders;

  // Set body.
  request.HTTPBody = (NSData *)data;

  // Always disable cookies.
  [request setHTTPShouldHandleCookies:NO];

  // Log.
  if ([MSLogger currentLogLevel] <= MSLogLevelVerbose) {
    MSLogVerbose([MSAppCenter logTag], @"Creating CosmosDB request with URL: %@", request.URL.absoluteString);
    MSLogVerbose([MSAppCenter logTag], @"CosmosDB request headers: %@", [super prettyPrintHeaders:request.allHTTPHeaderFields]);
  }
  return request;
}

- (NSString *)obfuscateHeaderValue:(NSString *)value forKey:(NSString *)key {
  // TODO Remove this implementation once parent class support obfuscating authorization header.
  return [key isEqualToString:kMSAuthorizationHeaderKey] ? [MSIngestionUtil hideSecret:value] : value;
}

@end
