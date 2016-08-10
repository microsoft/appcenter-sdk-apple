/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "AVACrashCXXExceptionHandler.h"

/** Temporary class until PLCR catches up. We trick PLCR with an Objective-C
 * exception. This code provides us access to the C++ exception message,
 * including a correct stack trace.
 */
@interface AVACrashCXXExceptionWrapperException : NSException

- (instancetype)initWithCXXExceptionInfo:(const AVACrashUncaughtCXXExceptionInfo *)info;

@end
