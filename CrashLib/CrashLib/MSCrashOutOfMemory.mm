// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSCrashOutOfMemory.h"
#include <algorithm>

@implementation MSCrashOutOfMemory

- (NSString *)category {
  return @"Memory";
}

- (NSString *)title {
  return @"Produce memory shortage (OOM)";
}

- (NSString *)desc {
  return @""
          "Execute an infinite loop with excessive memory allocation which "
          "causes an OS to terminate app.";
}

- (void)crash {
  int blockSize = 128 * 1024 * 1024;
  while (true) {
    malloc(blockSize);
    NSLog(@"Allocated %d bytes", blockSize);
  }
}

@end
