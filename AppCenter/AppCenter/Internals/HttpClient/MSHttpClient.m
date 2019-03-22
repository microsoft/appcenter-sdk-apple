// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSHttpClient.h"
#import "MSHttpClientPrivate.h"
#import "MS_Reachability.h"

@implementation MSHttpClient

- (instancetype)init {
  if ((self = [super init])) {
    _session = [NSURLSession new];
    _pendingCalls = [NSSet new];
    _reachability = [MS_Reachability new];
    _retryIntervals = @[@1.0];
  }
  return self;
}

- (instancetype)initWithMaxHttpConnectionsPerHost:(int)maxHttpConnectionsPerHost {
    if ((self = [super init])) {
      NSURLSessionConfiguration *config = [NSURLSessionConfiguration new];
      config.HTTPMaximumConnectionsPerHost = maxHttpConnectionsPerHost;
      _session = [NSURLSession sessionWithConfiguration:config];
      _pendingCalls = [NSSet new];
      _reachability = [MS_Reachability new];
      _retryIntervals = @[@1.0];
  }
  return self;
}

- (instancetype)initWithRetryIntervals:(NSArray *)retryIntervals reachability:(MS_Reachability *)reachability {
  if ((self = [super init])) {
    _session = [NSURLSession new];
    _pendingCalls = [NSSet new];
    _reachability = reachability;
    _retryIntervals = [NSArray arrayWithArray:retryIntervals];
  }
  return self;
}

- (void)sendAsync:(NSURL *)url
               method:(NSString *)method
              headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                 data:(nullable NSData *)data
    completionHandler:(MSHttpRequestCompletionHandler)handler {

  // TODO implement this.
  (void)data;
  (void)headers;
  (void)url;
  (void)method;
  (void)handler;
}

@end
