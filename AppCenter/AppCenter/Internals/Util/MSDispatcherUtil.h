// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

/*
 * Convert sent arguments to an array. When you want to pass nil, replace it's value with [NSNull null].
 */
#define ARRAY_FROM_ARGS(...)                                                                                                               \
  ({                                                                                                                                       \
    NSMutableArray *initedArray = [NSMutableArray arrayWithObjects:[NSNull null], ##__VA_ARGS__, nil];                                     \
    [initedArray removeObjectAtIndex:0];                                                                                                   \
    initedArray;                                                                                                                           \
  })

#define MS_DISPATCH_SELECTOR(type, object, selectorName, ...)                                                                              \
  ({                                                                                                                                       \
    void *results;                                                                                                                         \
    [[MSDispatcherUtil performSelector:object withSelector:@ #selectorName                                                                 \
                           withObjects:ARRAY_FROM_ARGS(__VA_ARGS__)] getReturnValue:&results];                                             \
    (type) results;                                                                                                                        \
  })

#define MS_DISPATCH_SELECTOR_VOID(object, selectorName, ...)                                                                               \
  ({ [MSDispatcherUtil performSelector:object withSelector:@ #selectorName withObjects:ARRAY_FROM_ARGS(__VA_ARGS__)]; })

@interface MSDispatcherUtil : NSObject

+ (void)performBlockOnMainThread:(void (^)(void))block;

+ (NSInvocation *)performSelector:(id)source withSelector:(NSString *)selector withObjects:(NSArray *)objects;

@end
