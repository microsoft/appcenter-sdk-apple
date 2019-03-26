// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSHttpClient.h"
#import "MSAppCenterInternal.h"
#import "MSConstants+Internal.h"
#import "MSHttpCall.h"
#import "MSHttpClientPrivate.h"
#import "MSHttpUtil.h"
#import "MSLoggerInternal.h"
#import "MSUtility+StringFormatting.h"
#import "MS_Reachability.h"

@implementation MSHttpClient

#define DEFAULT_RETRY_INTERVALS @[ @10, @(5 * 60), @(20 * 60) ]

- (instancetype)init {
  return [self initWithMaxHttpConnectionsPerHost:nil retryIntervals:DEFAULT_RETRY_INTERVALS reachability:[MS_Reachability new]];
}

- (instancetype)initWithMaxHttpConnectionsPerHost:(int)maxHttpConnectionsPerHost {
  return [self initWithMaxHttpConnectionsPerHost:@(maxHttpConnectionsPerHost)
                                  retryIntervals:DEFAULT_RETRY_INTERVALS
                                    reachability:[MS_Reachability new]];
}

- (instancetype)initWithMaxHttpConnectionsPerHost:(NSNumber *)maxHttpConnectionsPerHost
                                   retryIntervals:(NSArray *)retryIntervals
                                     reachability:(MS_Reachability *)reachability {
  if ((self = [super init])) {
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    if (maxHttpConnectionsPerHost) {
      config.HTTPMaximumConnectionsPerHost = [maxHttpConnectionsPerHost intValue];
    }
    _session = [NSURLSession sessionWithConfiguration:config];
    _pendingCalls = [NSMutableSet new];
    _reachability = reachability;
    // TODO init reachability notifier and callbacks and use it for real.
    _retryIntervals = [NSArray arrayWithArray:retryIntervals];
  }
  return self;
}

- (void)sendAsync:(NSURL *)url
               method:(NSString *)method
              headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                 data:(nullable NSData *)data
    completionHandler:(MSHttpRequestCompletionHandler)completionHandler {
  MSHttpCall *call = [[MSHttpCall alloc] initWithUrl:url
                                              method:method
                                             headers:headers
                                                data:data
                                      retryIntervals:self.retryIntervals
                                   completionHandler:completionHandler];
  [self sendCallAsync:call];
}

- (void)sendCallAsync:(MSHttpCall *)call {
  @synchronized(self) {
    [self.pendingCalls addObject:call];
  }
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:call.url];
  request.HTTPBody = call.data;
  request.HTTPMethod = call.method;
  request.allHTTPHeaderFields = call.headers;

  // Always disable cookies.
  [request setHTTPShouldHandleCookies:NO];

  // Don't lose time pretty printing headers if not going to be printed.
  if ([MSLogger currentLogLevel] <= MSLogLevelVerbose) {
    MSLogVerbose([MSAppCenter logTag], @"URL: %@", request.URL);
    MSLogVerbose([MSAppCenter logTag], @"Headers: %@", [self prettyPrintHeaders:request.allHTTPHeaderFields]);
  }
  NSURLSessionDataTask *task = [self.session
      dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
          NSHTTPURLResponse *httpResponse;
          @synchronized(self) {

            // If canceled, then return immediately.
            if (![self.pendingCalls containsObject:call]) {
              MSLogDebug([MSAppCenter logTag], @"HTTP call was canceled, not processing result.");
              return;
            }

            // Handle NSError (low level error where we don't even get a HTTP response).
            BOOL internetIsDown = [MSHttpUtil isNoInternetConnectionError:error];
            BOOL couldNotEstablishSecureConnection = [MSHttpUtil isSSLConnectionError:error];
            if (error) {
              if (internetIsDown || couldNotEstablishSecureConnection) {

                // Reset the retry count, will retry once the (secure) connection is established again.
                [call resetRetry];
                NSString *logMessage = internetIsDown ? @"Internet connection is down." : @"Could not establish secure connection.";
                MSLogInfo([MSAppCenter logTag], @"HTTP call failed with error: %@", logMessage);
              } else {
                MSLogError([MSAppCenter logTag], @"HTTP request error with code: %td, domain: %@, description: %@", error.code,
                           error.domain, error.localizedDescription);
              }
            }

            // Handle HTTP error.
            else {
              httpResponse = (NSHTTPURLResponse *)response;
              if ([MSHttpUtil isRecoverableError:httpResponse.statusCode] && ![call hasReachedMaxRetries]) {
                [call startRetryTimerWithStatusCode:httpResponse.statusCode
                                              event:^{
                                                [self sendCallAsync:call];
                                              }];
                return;
              }

              // Don't lose time pretty printing if not going to be printed.
              if ([MSAppCenter logLevel] <= MSLogLevelVerbose) {
                NSString *payload = [MSUtility prettyPrintJson:data];
                MSLogVerbose([MSAppCenter logTag], @"HTTP response received with status code: %tu, payload:\n%@", httpResponse.statusCode,
                             payload);
              }
            }
            [self.pendingCalls removeObject:call];
          }

          // Unblock the caller now with the outcome of the call.
          call.completionHandler(data, httpResponse, error);
        }];
  [task resume];
}

- (NSString *)obfuscateHeaderValue:(NSString *)value forKey:(NSString *)key {
  if ([key isEqualToString:kMSAuthorizationHeaderKey]) {
    return [MSHttpUtil hideAuthToken:value];
  } else if ([key isEqualToString:kMSHeaderAppSecretKey]) {
    return [MSHttpUtil hideSecret:value];
  }
  return value;
}

- (NSString *)prettyPrintHeaders:(NSDictionary<NSString *, NSString *> *)headers {
  NSMutableArray<NSString *> *flattenedHeaders = [NSMutableArray<NSString *> new];
  for (NSString *headerKey in headers) {
    [flattenedHeaders
        addObject:[NSString stringWithFormat:@"%@ = %@", headerKey, [self obfuscateHeaderValue:headers[headerKey] forKey:headerKey]]];
  }
  return [flattenedHeaders componentsJoinedByString:@", "];
}

@end
