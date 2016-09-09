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
} SNMCrashesUncaughtCXXExceptionInfo;

typedef void (*SNMCrashesUncaughtCXXExceptionHandler)(const SNMCrashesUncaughtCXXExceptionInfo *__nonnull info);

@interface SNMCrashesUncaughtCXXExceptionHandlerManager : NSObject

/**
 * Add a XCXX exceptionhandler.
 * @param handler The ASNMCrashesUncaughtCXXExceptionHandler that should be added.
 */
+ (void)addCXXExceptionHandler:(nonnull SNMCrashesUncaughtCXXExceptionHandler)handler;

/**
 * Remove a XCXX exceptionhandler.
 * @param handler The SNMCrashesUncaughtCXXExceptionHandler that should be
 * removed.
 */
+ (void)removeCXXExceptionHandler:(nonnull SNMCrashesUncaughtCXXExceptionHandler)handler;

@end
