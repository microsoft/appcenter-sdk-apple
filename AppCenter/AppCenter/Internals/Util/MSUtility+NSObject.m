// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@implementation NSObject(PerformSelectorOnMainThreadMultipleArgs)

- (void)performSelectorOnMainThread:(SEL)selector waitUntilDone:(BOOL)wait withObjects:(NSObject *)objects, ... {
    NSMethodSignature *signature = [self methodSignatureForSelector:selector];

    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:self];
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
    [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:wait];
}

@end
