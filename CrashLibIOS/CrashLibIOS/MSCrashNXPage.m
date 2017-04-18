/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSCrashNXPage.h"
#import <sys/mman.h>

@implementation MSCrashNXPage

- (NSString *)category {
  return @"SIGSEGV";
}

- (NSString *)title {
  return @"Jump into an NX page";
}

- (NSString *)desc {
  return @"Call a function pointer to memory in a non-executable page.";
}

- (void)crash {
  /**
   * Solution and explanation by Gwynne:
   * When generating an NX crash, previously the code would explicitly jump to NULL, which modern versions of Clang
   * correctly optimize out as provable undefined behavior (the compiler is free to do whatever it wants if it can
   * prove that the code will always dereference NULL). Instead, map a valid memory space without the execute
   * permission and jump to that pointer.
   */
  void *ptr = mmap(NULL, (size_t)getpagesize(), PROT_READ | PROT_WRITE, MAP_ANON | MAP_PRIVATE, -1, 0);
  if (ptr != MAP_FAILED) {
    ((void (*)(void))ptr)();
  }
}

@end
