/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "CRLCrash.h"

@interface CRLCrashObjCException : CRLCrash

- (void)crash __attribute__((noreturn));

@end
