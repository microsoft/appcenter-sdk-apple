/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVACrashesHelper.h"
#import <sys/sysctl.h>

static NSString *const kAVACrashesDirectory =
    @"com.microsoft.avalanche/crashes";

@interface AVACrashesHelper ()

BOOL ava_isDebuggerAttached(void);
BOOL ava_isRunningInAppExtension(void);
NSString *ava_crashesDir(void);

@end

@implementation AVACrashesHelper

#pragma mark - Public

+ (NSString *)crashesDir {
  return ava_crashesDir();
}

+ (BOOL)isAppExtension {
  return (BOOL)ava_isRunningInAppExtension();
}

+ (BOOL)isDebuggerAttached {
  return ava_isDebuggerAttached();
}

@end

#pragma mark - Private

/**
 * Check if the debugger is attached
 *
 * Taken from https://github.com/plausiblelabs/plcrashreporter/blob/2dd862ce049e6f43feb355308dfc710f3af54c4d/Source/Crash%20Demo/main.m#L96
 *
 * @return `YES` if the debugger is attached to the current process, `NO` otherwise
 */
BOOL ava_isDebuggerAttached(void) {
  static BOOL debuggerIsAttached = NO;

  static dispatch_once_t debuggerPredicate;
  dispatch_once(&debuggerPredicate, ^{
    struct kinfo_proc info;
    size_t info_size = sizeof(info);
    int name[4];

    name[0] = CTL_KERN;
    name[1] = KERN_PROC;
    name[2] = KERN_PROC_PID;
    name[3] = getpid();

    if (sysctl(name, 4, &info, &info_size, NULL, 0) == -1) {
      NSLog(@"[AVACrashes] ERROR: Checking for a running debugger via sysctl() "
            @"failed.");
      debuggerIsAttached = false;
    }

    if (!debuggerIsAttached && (info.kp_proc.p_flag & P_TRACED) != 0)
      debuggerIsAttached = true;
  });

  return debuggerIsAttached;
}

BOOL ava_isRunningInAppExtension(void) {
  static BOOL isRunningInAppExtension = NO;
  static dispatch_once_t checkAppExtension;

  dispatch_once(&checkAppExtension, ^{
    isRunningInAppExtension =
        ([[[NSBundle mainBundle] executablePath] rangeOfString:@".appex/"]
             .location != NSNotFound);
  });

  return isRunningInAppExtension;
}

