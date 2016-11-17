/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "CRLCrashNXPage.h"

@implementation CRLCrashNXPage

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
