// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSHttpCall.h"
#import <Foundation/Foundation.h>

@implementation MSHttpCall

- (instancetype)initWithUrl:(NSURL *)url
                     method:(NSString *)method
                    headers:(NSDictionary<NSString *, NSString *> *)headers
                       data:(NSData *)data
             retryIntervals:(NSArray *)retryIntervals
          completionHandler:(MSHttpRequestCompletionHandler)completionHandler {
  _url = url;
  _method = method;
  _headers = headers;
  _data = data;
  _retryIntervals = retryIntervals;
  _completionHandler = completionHandler;
  _retryCount = 0;
  return self;
}

- (BOOL)hasReachedMaxRetries {
  return NO;
}

- (void)resetTimer {
}

- (void)resetRetry {
}

@end
