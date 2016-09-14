/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMCrashesCXXExceptionHandler.h"
#import <Foundation/Foundation.h>

/** Temporary class until PLCR catches up. We trick PLCR with an Objective-C
 * exception. This code provides us access to the C++ exception message,
 * including a correct stack trace.
 */
@interface SNMCrashesCXXExceptionWrapperException : NSException

- (instancetype)initWithCXXExceptionInfo:(const SNMCrashesUncaughtCXXExceptionInfo *)info;

@end
