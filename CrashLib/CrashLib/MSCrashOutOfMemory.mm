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
  const size_t blockSize = 128 * 1024 * 1024;
  size_t allocated = 0;
  NSMutableArray *buffers = [NSMutableArray new];
  while (true) {
    void *buffer = malloc(blockSize);
    memset(buffer, 42, blockSize);
    [buffers addObject:[NSValue valueWithPointer:buffer]];
    allocated += blockSize;
    NSLog(@"Allocated %zu MB", allocated / (1024 * 1024));
  }
}

@end
