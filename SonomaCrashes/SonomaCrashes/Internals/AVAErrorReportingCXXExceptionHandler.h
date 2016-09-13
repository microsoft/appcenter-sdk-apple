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
} AVAErrorReportingUncaughtCXXExceptionInfo;

typedef void (*AVAErrorReportingUncaughtCXXExceptionHandler)(const AVAErrorReportingUncaughtCXXExceptionInfo *__nonnull info);

@interface AVAErrorReportingUncaughtCXXExceptionHandlerManager : NSObject

/**
 * Add a XCXX exceptionhandler.
 * @param handler The AVAErrorReportingUncaughtCXXExceptionHandler that should be added.
 */
+ (void)addCXXExceptionHandler:(nonnull AVAErrorReportingUncaughtCXXExceptionHandler)handler;

/**
 * Remove a XCXX exceptionhandler.
 * @param handler The AVAErrorReportingUncaughtCXXExceptionHandler that should be
 * removed.
 */
+ (void)removeCXXExceptionHandler:(nonnull AVAErrorReportingUncaughtCXXExceptionHandler)handler;

@end
