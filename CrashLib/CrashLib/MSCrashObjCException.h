/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSCrash.h"

@interface MSCrashObjCException : MSCrash

- (void)crash __attribute__((noreturn));

@end
