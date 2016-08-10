/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

typedef struct {
    const void * __nullable exception;
    const char * __nullable exception_type_name;
    const char * __nullable exception_message;
    uint32_t exception_frames_count;
    const uintptr_t * __nonnull exception_frames;
} AVACrashUncaughtCXXExceptionInfo;

typedef void (*AVACrashUncaughtCXXExceptionHandler)(
    const AVACrashUncaughtCXXExceptionInfo * __nonnull info
);

@interface AVACrashUncaughtCXXExceptionHandlerManager : NSObject

+ (void)addCXXExceptionHandler:(nonnull AVACrashUncaughtCXXExceptionHandler)handler;
+ (void)removeCXXExceptionHandler:(nonnull AVACrashUncaughtCXXExceptionHandler)handler;

@end
