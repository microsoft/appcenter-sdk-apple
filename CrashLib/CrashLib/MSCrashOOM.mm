// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSCrashOOM.h"
#include <algorithm>

@implementation MSCrashOOM

- (NSString *)category {
  return @"Memory";
}

- (NSString *)title {
  return @"Produce memory shortage (OOM)";
}

- (NSString *)desc {
  return @""
  "Execute an infinite loop with excessive memory allocation, which "
  "causes a OS to terminate app.";
}

- (void)crash {
  int arrSize = 128 * 1024 * 1024;
  while (true) {
    volatile auto newArr = new char[arrSize];
    std::fill(newArr, newArr + arrSize, 42);
    NSLog(@"Allocated %d bytes", arrSize);
  }
}

@end
