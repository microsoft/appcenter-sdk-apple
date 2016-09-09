/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMCrashesCXXExceptionWrapperException.h"

@implementation SNMCrashesCXXExceptionWrapperException {
  const SNMCrashesUncaughtCXXExceptionInfo *_info;
}

- (instancetype)initWithCXXExceptionInfo:(const SNMCrashesUncaughtCXXExceptionInfo *)info {
  extern char *__cxa_demangle(const char *mangled_name, char *output_buffer, size_t *length, int *status);
  char *demangled_name = &__cxa_demangle ? __cxa_demangle(info->exception_type_name ?: "", NULL, NULL, NULL) : NULL;

  if ((self = [super initWithName:[NSString stringWithUTF8String:demangled_name ?: info->exception_type_name ?: ""]
                           reason:[NSString stringWithUTF8String:info->exception_message ?: ""]
                         userInfo:nil])) {
    _info = info;
  }
  return self;
}

@end
