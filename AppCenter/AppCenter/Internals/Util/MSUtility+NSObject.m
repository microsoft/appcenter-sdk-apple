// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>
#import "MSUtility+NSObject.h"

/*
 * Workaround for exporting symbols from category object files.
 */
NSString *MSUtilityObjectSelectorCategory;

@implementation NSObject(PerformSelectorOnMainThreadMultipleArgs)

+ (void)performSelectorOnMainThread:(NSObject*)source withSelector:(SEL)selector withObjects:(NSObject *)objects, ... {
  NSMethodSignature *signature = [source methodSignatureForSelector:selector];
  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
  [invocation setTarget:source];
  [invocation setSelector:selector];
  if (!signature) {
    NSLog(@"NSObject: Method signature could not be created.");
    return;
  }
  va_list args;
  va_start(args, objects);
  int nextArgIndex = 2;
  for (NSObject *object = objects; object != [NSNull null] ; object = va_arg(args, NSObject*)) {
    [invocation setArgument:&object atIndex:nextArgIndex];
    nextArgIndex++;
  }
  va_end(args);
  [invocation retainArguments];
  [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
}

@end
