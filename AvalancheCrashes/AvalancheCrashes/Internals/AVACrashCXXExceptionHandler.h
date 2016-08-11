/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

/**
 * Struct to describe CXXException information.
 */
typedef struct {
  const void *__nullable exception;
  const char *__nullable exception_type_name;
  const char *__nullable exception_message;
  uint32_t exception_frames_count;
  const uintptr_t *__nonnull exception_frames;
} AVACrashUncaughtCXXExceptionInfo;

typedef void (*AVACrashUncaughtCXXExceptionHandler)(const AVACrashUncaughtCXXExceptionInfo *__nonnull info);

@interface AVACrashUncaughtCXXExceptionHandlerManager : NSObject

/**
 * Add a XCXX exceptionhandler.
 * @param handler The AVACrashUncaughtCXXExceptionHandler that should be added.
 */
+ (void)addCXXExceptionHandler:(nonnull AVACrashUncaughtCXXExceptionHandler)handler;

/**
 * Remove a XCXX exceptionhandler.
 * @param handler The AVACrashUncaughtCXXExceptionHandler that should be
 * removed.
 */
+ (void)removeCXXExceptionHandler:(nonnull AVACrashUncaughtCXXExceptionHandler)handler;

@end
