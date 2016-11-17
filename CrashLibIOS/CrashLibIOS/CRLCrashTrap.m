/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "CRLCrashTrap.h"

@implementation CRLCrashTrap

- (NSString *)category {
  return @"SIGTRAP";
}

- (NSString *)title {
  return @"Call __builtin_trap()";
}

- (NSString *)desc {
  return @"Call __builtin_trap() to generate a trap exception.";
}

- (void)crash __attribute__((noreturn)) {
  __builtin_trap();
}

@end
