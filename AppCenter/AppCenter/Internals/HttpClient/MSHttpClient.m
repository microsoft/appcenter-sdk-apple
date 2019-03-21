// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSHttpClient.h"

@implementation MSHttpClient

- (instancetype)init {

  // TODO implement this properly.
  return self = [super init];
}

- (instancetype)initWithMaxHttpConnectionsPerHost:(int)maxHttpConnectionsPerHost {
  if ((self = [super init])) {

    // TODO implement this properly.
    (void)maxHttpConnectionsPerHost;
  }
  return self;
}

- (void)sendAsync:(NSURL *)url
               method:(NSString *)method
              headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                 data:(nullable NSObject *)data
    completionHandler:(MSHttpRequestCompletionHandler)handler {

  // TODO implement this.
  (void)data;
  (void)headers;
  (void)url;
  (void)method;
  (void)handler;
}

@end
