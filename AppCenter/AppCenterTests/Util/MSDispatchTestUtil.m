// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDispatchTestUtil.h"

static const int kMSDispatchQueueWaitTime = 2;

@implementation MSDispatchTestUtil

+ (void)awaitAndSuspendDispatchQueue:(dispatch_queue_t)dispatchQueue {

  // Wait for all tasks to complete, then call suspend in the final task.
  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
  dispatch_async(dispatchQueue, ^{
    dispatch_semaphore_signal(semaphore);
  });
  dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, kMSDispatchQueueWaitTime * NSEC_PER_SEC);
  BOOL timedOut = dispatch_semaphore_wait(semaphore, timeout) != 0;

  // Suspend the execution of any subsequent tasks.
  dispatch_suspend(dispatchQueue);
  if (timedOut) {
    [NSException raise:@"Dispatch queue stuck during test tear down." format:@""];
  }
}

@end
