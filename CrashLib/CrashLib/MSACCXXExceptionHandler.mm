// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>
#import <typeinfo>
#import <dlfcn.h>

@interface MSACCrashesUncaughtCXXExceptionHandlerManager : NSObject

+ (void)registerCXXExceptionStackTrace;

@end

inline void original__cxa_throw(void *exception_object, std::type_info *tinfo, void (*dest)(void *)) {
  typedef void (*cxa_throw_func)(void *, std::type_info *, void (*)(void *));
  static cxa_throw_func __original__cxa_throw = reinterpret_cast<cxa_throw_func>(dlsym(RTLD_NEXT, "__cxa_throw"));
  __original__cxa_throw(exception_object, tinfo, dest);
}

inline bool is_objc_exception(std::type_info *tinfo) {
  static const void **__real_objc_ehtype_vtable = reinterpret_cast<const void **>(dlsym(RTLD_DEFAULT, "objc_ehtype_vtable"));
  return tinfo && __real_objc_ehtype_vtable && // Guard from an ABI change
      *reinterpret_cast<void **>(tinfo) == __real_objc_ehtype_vtable + 2;
}

extern "C" void __cxa_throw(void *exception_object, std::type_info *tinfo, void (*dest)(void *)) {
  if (!is_objc_exception(tinfo)) {
    Class exceptionHandlerManager = NSClassFromString(@"MSACCrashesUncaughtCXXExceptionHandlerManager");
    [exceptionHandlerManager registerCXXExceptionStackTrace];
  }
  original__cxa_throw(exception_object, tinfo, dest);
}
