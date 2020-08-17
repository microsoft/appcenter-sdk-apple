// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#define MS_DISPATCH_SELECTOR(declaration, object, selectorName, ...)                                                                       \
  ({                                                                                                                                       \
    SEL selector = NSSelectorFromString(@ #selectorName);                                                                                  \
    IMP impl = [object methodForSelector:selector];                                                                                        \
    (declaration impl)(object, selector, ##__VA_ARGS__);                                                                                   \
  })

@interface MSDispatcherUtil : NSObject

+ (void)performBlockOnMainThread:(void (^)(void))block;

/**
 * Adds a dispatch_async block to the provided queue and waits for its execution.
 * @param timeout timeout for waiting in seconds.
 * @param dispatchQueue the queue to perform block on.
 */
+ (void)dispatchAsyncWithTimeout:(int)timeout onQueue:(dispatch_queue_t)dispatchQueue;

@end
