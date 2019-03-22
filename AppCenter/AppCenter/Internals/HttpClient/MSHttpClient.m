// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSHttpClient.h"
#import "MSHttpClientPrivate.h"
#import "MS_Reachability.h"

@implementation MSHttpClient

- (instancetype)init {
  if ((self = [super init])) {
    _session = [NSURLSession new];
  }
  return self;
}

- (instancetype)initWithMaxHttpConnectionsPerHost:(int)maxHttpConnectionsPerHost {
  self = [self init];
  if (self) {
    // TODO implement this properly.
    (void)maxHttpConnectionsPerHost;
  }
  return self;
}

- (instancetype)initWithRetryIntervals:(NSArray *)retryIntervals reachability:(MS_Reachability *)reachability {
  if ((self = [super init])) {

    // TODO implement this properly.
    (void)retryIntervals;
    (void)reachability;
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
