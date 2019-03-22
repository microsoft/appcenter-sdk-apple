// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSHttpClient.h"
#import "MSAppCenterInternal.h"
#import "MSHttpCall.h"
#import "MSHttpClientPrivate.h"
#import "MSLoggerInternal.h"
#import "MS_Reachability.h"
#import "MSUtility+StringFormatting.h"

@implementation MSHttpClient

- (instancetype)init {
  if ((self = [super init])) {
    _session = [NSURLSession new];
    _pendingCalls = [NSMutableSet new];
    _reachability = [MS_Reachability new];
    _retryIntervals = @[ @1.0 ];
  }
  return self;
}

- (instancetype)initWithMaxHttpConnectionsPerHost:(int)maxHttpConnectionsPerHost {
  if ((self = [super init])) {
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration new];
    config.HTTPMaximumConnectionsPerHost = maxHttpConnectionsPerHost;
    _session = [NSURLSession sessionWithConfiguration:config];
    _pendingCalls = [NSMutableSet new];
    _reachability = [MS_Reachability new];
    _retryIntervals = @[ @1.0 ];
  }
  return self;
}

- (instancetype)initWithRetryIntervals:(NSArray *)retryIntervals reachability:(MS_Reachability *)reachability {
  if ((self = [super init])) {
    _session = [NSURLSession new];
    _pendingCalls = [NSMutableSet new];
    _reachability = reachability;
    _retryIntervals = [NSArray arrayWithArray:retryIntervals];
  }
  return self;
}

- (void)sendAsync:(NSURL *)url
           method:(NSString *)method
          headers:(nullable NSDictionary<NSString *, NSString *> *)headers
             data:(nullable NSData *)data
completionHandler:(MSHttpRequestCompletionHandler)completionHandler {
  MSHttpCall *call =
  [[MSHttpCall alloc] initWithUrl:url
                           method:method
                          headers:headers
                             data:data
                   retryIntervals:self.retryIntervals
                completionHandler:^(MSHttpCall *completedCall, NSData *responseBody, NSHTTPURLResponse *response, NSError *callError) {
                  BOOL removedCall = NO;
                  @synchronized(self) {
                    if ([self.pendingCalls containsObject:completedCall]) {
                      [self.pendingCalls removeObject:completedCall];
                      removedCall = YES;
                    }
                  }

                  /*
                   * If the call was canceled, then it won't have been removed above, and thus, we should not call the completion handler, because the
                   * cancelation would have already done so.
                   */
                  if (removedCall) {
                    completionHandler(responseBody, response, callError);
                  }
                }];
  [self sendCallAsync:call];
}

- (void)sendCallAsync:(MSHttpCall *)call {
  @synchronized(self) {
    [self.pendingCalls addObject:call];
  }
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:call.url];
  request.HTTPBody = call.body;
  request.HTTPMethod = call.method;
  request.allHTTPHeaderFields = call.headers;

  // Always disable cookies.
  [request setHTTPShouldHandleCookies:NO];

  // Don't lose time pretty printing headers if not going to be printed.
  if ([MSLogger currentLogLevel] <= MSLogLevelVerbose) {
    MSLogVerbose([MSAppCenter logTag], @"URL: %@", request.URL);
    MSLogVerbose([MSAppCenter logTag], @"Headers: %@", [self prettyPrintHeaders:request.allHTTPHeaderFields]);
  }
  NSURLSessionDataTask *task =
  [self.session dataTaskWithRequest:request
                  completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    @synchronized(self) {
                      NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                      if (error) {
                        MSLogDebug([MSAppCenter logTag], @"HTTP request error with code: %td, domain: %@, description: %@",
                                   error.code, error.domain, error.localizedDescription);
                      }

                      // Don't lose time pretty printing if not going to be printed.
                      else if ([MSAppCenter logLevel] <= MSLogLevelVerbose) {
                        NSString *payload = [MSUtility prettyPrintJson:data];
                        MSLogVerbose([MSAppCenter logTag], @"HTTP response received with status code: %tu, payload:\n%@",
                                     httpResponse.statusCode, payload);
                      }

                      // Call handles the completion.
                      if (call) {
                        call.submitted = NO;
                        [call ingestion:self callCompletedWithResponse:httpResponse data:data error:error];
                      }
                    }
                  }];

  // TODO: Set task priority.
  [task resume];
  call.submitted = YES;
}
//
//- (void)sendCarllAsync:(MSIngestionCall *)call {
//  @synchronized(self) {
//
//
//    // Create the request.
//    NSURLRequest *request = [self createRequest:call.data eTag:call.eTag authToken:call.authToken];
//    if (!request) {
//      return;
//    }
//
//    // Create a task for the request.
//    NSURLSessionDataTask *task =
//    [self.session dataTaskWithRequest:request
//                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
//                      @synchronized(self) {
//                        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
//                        if (error) {
//                          MSLogDebug([MSAppCenter logTag], @"HTTP request error with code: %td, domain: %@, description: %@",
//                                     error.code, error.domain, error.localizedDescription);
//                        }
//
//                        // Don't lose time pretty printing if not going to be printed.
//                        else if ([MSAppCenter logLevel] <= MSLogLevelVerbose) {
//                          NSString *payload = [MSUtility prettyPrintJson:data];
//                          MSLogVerbose([MSAppCenter logTag], @"HTTP response received with status code: %tu, payload:\n%@",
//                                       httpResponse.statusCode, payload);
//                        }
//
//                        // Call handles the completion.
//                        if (call) {
//                          call.submitted = NO;
//                          [call ingestion:self callCompletedWithResponse:httpResponse data:data error:error];
//                        }
//                      }
//                    }];
//
//    // TODO: Set task priority.
//    [task resume];
//    call.submitted = YES;
//  }
//}

- (NSString *)prettyPrintHeaders:(NSDictionary<NSString *, NSString *> *)headers {
  NSMutableArray<NSString *> *flattenedHeaders = [NSMutableArray<NSString *> new];
  for (NSString *headerKey in headers) {
    [flattenedHeaders
        addObject:[NSString stringWithFormat:@"%@ = %@", headerKey, [self obfuscateHeaderValue:headers[headerKey] forKey:headerKey]]];
  }
  return [flattenedHeaders componentsJoinedByString:@", "];
}

@end
