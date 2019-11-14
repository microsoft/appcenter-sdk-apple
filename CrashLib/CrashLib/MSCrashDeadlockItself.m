// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSCrashDeadlockItself.h"

@implementation MSCrashDeadlockItself

- (NSString *)category {
  return @"SIGTRAP";
}

- (NSString *)title {
  return @"BUG IN CLIENT OF LIBDISPATCH";
}

- (NSString *)desc {
  return @"Call dispatch_sync called on queue already owned by current thread.";
}

- (void)crash {
  dispatch_sync(dispatch_get_main_queue(), ^{});
}

@end
