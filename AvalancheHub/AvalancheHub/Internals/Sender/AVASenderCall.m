/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVASenderCall.h"

static NSUInteger kAVAMaxRetryCount = 3;

@implementation AVASenderCall

- (BOOL)hasReachedMaxRetries {
  return self.retryCount >= kAVAMaxRetryCount;
}

@end

