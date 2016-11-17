/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "CRLCrashNULL.h"

@implementation CRLCrashNULL

- (NSString *)category {
  return @"SIGSEGV";
}

- (NSString *)title {
  return @"Dereference a NULL pointer";
}

- (NSString *)desc {
  return @"Attempt to read from 0x0, which causes a segmentation violation.";
}

- (void)crash {
  volatile char *ptr = NULL;
  (void) *ptr;
}

@end
