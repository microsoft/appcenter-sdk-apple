/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSCrashNXPage.h"

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
  ((void (*)(void)) NULL)();
}

@end
