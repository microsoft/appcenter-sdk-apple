// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACNSLogQueueManager.h"
#import <dispatch/dispatch.h>

@implementation MSACNSLogQueueManager

+ (MSACNSLogQueueManager *)sharedManager {
  static MSACNSLogQueueManager *sharedManager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedManager = [[MSACNSLogQueueManager alloc] init];
  });
  return sharedManager;
}

- (id)init {
  if ((self = [super init])) {
    _loggerDispatchQueue = dispatch_queue_create("com.microsoft.MSACLogQueueManager", DISPATCH_QUEUE_SERIAL);
  }
  return self;
}

@end
