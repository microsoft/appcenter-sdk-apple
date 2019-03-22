// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSHttpCall.h"
#import <Foundation/Foundation.h>

@implementation MSHttpCall

- (instancetype)initWithRetryIntervals:(NSArray *)retryIntervals {
  (void)retryIntervals;
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
