/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "CRLCrashROPage.h"

@implementation CRLCrashROPage

static void __attribute__((used)) dummyfunc(void) {
}

- (NSString *)category {
  return @"SIGBUS";
}

- (NSString *)title {
  return @"Write to a read-only page";
}

- (NSString *)desc {
  return @"Attempt to write to a page into which the app's code is mapped.";
}

- (void)crash {
  volatile char *ptr = (char *) dummyfunc;
  *ptr = 0;
}

@end
