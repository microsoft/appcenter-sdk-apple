// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSPerformSelectorUtil.h"
#import "MSAppCenterInternal.h"

@implementation MSPerformSelectorUtil

+ (void)performSelectorOnMainThread:(NSObject *)source withSelector:(SEL)selector withObjects:(NSObject *)objects, ... {
  NSMethodSignature *signature = [source methodSignatureForSelector:selector];
  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
  [invocation setTarget:source];
  [invocation setSelector:selector];
  if (!signature) {
    MSLogError([MSAppCenter logTag], @"MSUtility: Method signature could not be created.");
    return;
  }
  va_list args;
  va_start(args, objects);
  int nextArgIndex = 2;
  for (NSObject *object = objects; object != [NSNull null]; object = va_arg(args, NSObject *)) {
    [invocation setArgument:&object atIndex:nextArgIndex];
    nextArgIndex++;
  }
  va_end(args);
  [invocation retainArguments];
  [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
}

@end
