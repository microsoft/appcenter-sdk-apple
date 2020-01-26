// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDispatcherUtil.h"
#import "MSAppCenterInternal.h"

@implementation MSDispatcherUtil

+ (void)performBlockOnMainThread:(void (^)(void))block {

#if TARGET_OS_OSX
  [self performSelectorOnMainThread:@selector(runBlock:) withObject:block waitUntilDone:NO];
#else
  if ([NSThread isMainThread]) {
    block();
  } else {
    dispatch_async(dispatch_get_main_queue(), block);
  }
#endif
}

+ (void)runBlock:(void (^)(void))block {
  block();
}

+ (NSInvocation *)performSelector:(id)source withSelector:(NSString *)selector withObjects:(NSArray *)objects {
  SEL selectors = NSSelectorFromString(selector);
  NSMethodSignature *signature = [(NSObject *)source methodSignatureForSelector:selectors];
  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
  [invocation setTarget:source];
  [invocation setSelector:selectors];
  int index = 2;
  for (id value in objects) {
    void *values = (__bridge void *)value;
    [invocation setArgument:&values atIndex:index++];
  }
  [invocation retainArguments];
  [invocation invoke];
  return invocation;
}

@end
