/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSCrashesCXXExceptionHandler.h"
@import Foundation;

/** Temporary class until PLCR catches up. We trick PLCR with an Objective-C
 * exception. This code provides us access to the C++ exception message,
 * including a correct stack trace.
 */
@interface MSCrashesCXXExceptionWrapperException : NSException

- (instancetype)initWithCXXExceptionInfo:(const MSCrashesUncaughtCXXExceptionInfo *)info;

@end
