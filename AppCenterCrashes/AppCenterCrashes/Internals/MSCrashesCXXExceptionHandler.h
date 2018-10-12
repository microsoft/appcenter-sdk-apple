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
} MSCrashesUncaughtCXXExceptionInfo;

typedef void (*MSCrashesUncaughtCXXExceptionHandler)(const MSCrashesUncaughtCXXExceptionInfo *__nonnull info);

@interface MSCrashesUncaughtCXXExceptionHandlerManager : NSObject

/**
 * Add a XCXX exceptionHandler.
 *
 * @param handler The MSCrashesUncaughtCXXExceptionHandler that should be added.
 */
+ (void)addCXXExceptionHandler:(nonnull MSCrashesUncaughtCXXExceptionHandler)handler;

/**
 * Remove a XCXX exceptionHandler.
 *
 * @param handler The MSCrashesUncaughtCXXExceptionHandler that should be removed.
 */
+ (void)removeCXXExceptionHandler:(nonnull MSCrashesUncaughtCXXExceptionHandler)handler;

/**
 * Handlers count
 */
+ (NSUInteger)countCXXExceptionHandler;

@end
